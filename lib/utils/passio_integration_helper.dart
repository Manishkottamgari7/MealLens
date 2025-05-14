import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutrition_ai/nutrition_ai.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';

import 'IOSCameraHelper.dart';


/// A helper class for integrating the Passio Nutrition AI SDK in Flutter
/// Handles SDK initialization, camera setup, and real-time detection
class PassioIntegrationHelper {
  // Singleton instance
  static final PassioIntegrationHelper _instance = PassioIntegrationHelper._internal();
  factory PassioIntegrationHelper() => _instance;
  PassioIntegrationHelper._internal();

  // SDK status
  bool _isInitialized = false;
  bool _isInitializing = false;
  PassioStatus? _passioStatus;
  String? _lastError;

  // Camera control
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraRunning = false;

  // Food detection
  FoodRecognitionListener? _recognitionListener;
  bool _isDetectionActive = false;

  // Platform channel for iOS-specific camera handling
  static const _platform = MethodChannel('com.demo.app/camera');

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  PassioStatus? get passioStatus => _passioStatus;
  String? get lastError => _lastError;
  bool get isCameraRunning => _isCameraRunning;
  bool get isDetectionActive => _isDetectionActive;
  CameraController? get cameraController => _cameraController;

  /// Initialize the Passio SDK with proper configuration
  Future<bool> initializePassioSDK({
    required String apiKey,
    bool remoteOnly = false,
    bool sdkDownloadsModels = true,
  }) async {
    if (_isInitialized) return true;
    if (_isInitializing) return false;

    _isInitializing = true;
    _lastError = null;

    try {
      debugPrint('Initializing Passio SDK...');

      // Create configuration with appropriate parameters via constructor
      final configuration = PassioConfiguration(
        apiKey,
        remoteOnly: remoteOnly,
        sdkDownloadsModels: sdkDownloadsModels,
        debugMode: 0,
      );

      _passioStatus = await NutritionAI.instance.configureSDK(configuration);

      if (_passioStatus?.mode == PassioMode.isReadyForDetection ||
          (remoteOnly && _passioStatus?.mode == PassioMode.isBeingConfigured)) {
        debugPrint('Passio SDK initialized successfully: ${_passioStatus?.mode}');
        _isInitialized = true;
        _isInitializing = false;
        return true;
      } else {
        _lastError = "Failed to initialize Passio SDK: ${_passioStatus?.mode}";
        debugPrint(_lastError);
        _isInitializing = false;
        return false;
      }
    } catch (e) {
      _lastError = "Error initializing Passio SDK: $e";
      debugPrint(_lastError);
      _isInitializing = false;
      return false;
    }
  }

  /// Request camera permission with improved iOS handling
  Future<bool> requestCameraPermission(BuildContext context) async {
    try {
      // Check current permission status
      final status = await Permission.camera.status;
      debugPrint('Current camera permission status: $status');

      if (status.isGranted) {
        debugPrint('Camera permission already granted');
        return true;
      }

      // Request permission through permission_handler first
      final result = await Permission.camera.request();
      debugPrint('Camera permission request result: $result');

      if (result.isGranted) {
        return true;
      }

      // For iOS, try platform channel if needed
      if (Platform.isIOS && (result.isDenied || result.isPermanentlyDenied)) {
        try {
          debugPrint('Attempting iOS-specific camera permission request');
          final bool granted = await _platform.invokeMethod('requestCameraPermission');
          debugPrint('iOS-specific camera permission result: $granted');

          // If granted, try initializing the camera to validate
          if (granted) {
            await _initializeCameras();
            return true;
          }
        } catch (e) {
          debugPrint('iOS platform channel error: $e');
        }
      }

      // Show dialog to guide user to settings if permission denied
      if (context.mounted && (result.isDenied || result.isPermanentlyDenied)) {
        _showPermissionSettingsDialog(context);
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      return false;
    }
  }

  /// Initialize available cameras
  Future<bool> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
      debugPrint('Available cameras: ${_cameras.length}');

      if (_cameras.isEmpty) {
        _lastError = "No cameras available on device";
        return false;
      }

      return true;
    } catch (e) {
      _lastError = "Failed to initialize cameras: $e";
      debugPrint(_lastError);
      return false;
    }
  }

  /// Setup camera for food detection
  Future<bool> setupCamera({
    required BuildContext context,
    ResolutionPreset resolution = ResolutionPreset.high,
  }) async {
    // Ensure SDK is initialized
    if (!_isInitialized) {
      _lastError = "Passio SDK not initialized. Call initializePassioSDK first.";
      debugPrint(_lastError);
      return false;
    }

    // Request camera permission
    final hasPermission = await requestCameraPermission(context);
    if (!hasPermission) {
      _lastError = "Camera permission not granted";
      debugPrint(_lastError);
      return false;
    }

    // Make sure cameras are initialized
    if (_cameras.isEmpty) {
      final camerasInitialized = await _initializeCameras();
      if (!camerasInitialized) return false;
    }

    // Clean up existing controller
    await _disposeCamera();

    try {
      // Select the best camera for food detection (usually back camera)
      CameraDescription selectedCamera;
      try {
        selectedCamera = _cameras.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
        );
        debugPrint('Using back camera: ${selectedCamera.name}');
      } catch (e) {
        debugPrint('Back camera not found, using first available camera');
        selectedCamera = _cameras.first;
      }

      // Create camera controller with specific settings
      _cameraController = CameraController(
        selectedCamera,
        resolution,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      // Initialize the controller
      debugPrint('Initializing camera controller...');
      await _cameraController!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _lastError = "Camera initialization timed out";
          throw CameraException('timeout', _lastError!);
        },
      );

      // Configure camera for optimal food detection
      if (_cameraController!.value.isInitialized) {
        await _optimizeCameraForFoodDetection();
        _isCameraRunning = true;
        return true;
      } else {
        _lastError = "Camera controller initialized but not ready";
        return false;
      }
    } catch (e) {
      _lastError = "Error setting up camera: $e";
      debugPrint(_lastError);
      await _disposeCamera();
      return false;
    }
  }

  /// Configure camera for optimal food detection
  Future<void> _optimizeCameraForFoodDetection() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      // Set focus and exposure modes
      await _cameraController!.setFlashMode(FlashMode.off);
      await _cameraController!.setFocusMode(FocusMode.auto);
      await _cameraController!.setExposureMode(ExposureMode.auto);

      // Set focus point to center for better food detection
      await _cameraController!.setFocusPoint(const Offset(0.5, 0.5));

      // Apply iOS-specific fixes
      if (Platform.isIOS) {
        await IOSCameraHelper.optimizeCameraForFoodDetection(_cameraController!);
        await IOSCameraHelper.refreshCameraPreview(_cameraController!);
      }

      debugPrint('Camera optimized for food detection');
    } catch (e) {
      debugPrint('Error optimizing camera: $e');
    }
  }

  /// Start real-time food detection with the camera
  Future<bool> startFoodDetection(FoodRecognitionListener listener) async {
    if (!_isInitialized) {
      _lastError = "Passio SDK not initialized. Call initializePassioSDK first.";
      debugPrint(_lastError);
      return false;
    }

    if (!_isCameraRunning || _cameraController == null) {
      _lastError = "Camera not initialized. Call setupCamera first.";
      debugPrint(_lastError);
      return false;
    }

    if (_isDetectionActive) {
      debugPrint('Food detection already active');
      return true;
    }

    try {
      _recognitionListener = listener;

      // Configure detection options for maximum compatibility
      final config = FoodDetectionConfiguration(
        detectVisual: true,
        detectBarcodes: true,
        detectPackagedFood: true,
        // Use appropriate framerates based on platform
        framesPerSecond: Platform.isIOS ? FramesPerSecond.two : FramesPerSecond.three,
        volumeDetectionMode: Platform.isIOS ? VolumeDetectionMode.none : VolumeDetectionMode.auto,
      );

      debugPrint('Starting food detection...');
      await NutritionAI.instance.startFoodDetection(config, listener);
      _isDetectionActive = true;

      debugPrint('Food detection started successfully');
      return true;
    } catch (e) {
      _lastError = "Error starting food detection: $e";
      debugPrint(_lastError);
      return false;
    }
  }

  /// Stop real-time food detection
  Future<void> stopFoodDetection() async {
    if (!_isDetectionActive) return;

    try {
      await NutritionAI.instance.stopFoodDetection();
      _isDetectionActive = false;
      debugPrint('Food detection stopped');
    } catch (e) {
      debugPrint('Error stopping food detection: $e');
    }
  }

  /// Process an image for food recognition
  Future<List<PassioAdvisorFoodInfo>?> recognizeFoodInImage(Uint8List imageBytes) async {
    if (!_isInitialized) {
      _lastError = "Passio SDK not initialized";
      return null;
    }

    try {
      debugPrint('Recognizing food in image...');
      final results = await NutritionAI.instance.recognizeImageRemote(imageBytes);
      debugPrint('Recognition complete: ${results.length} items found');
      return results;
    } catch (e) {
      _lastError = "Error recognizing food: $e";
      debugPrint(_lastError);
      return null;
    }
  }

  /// Cleanup resources
  Future<void> dispose() async {
    await stopFoodDetection();
    await _disposeCamera();
  }

  /// Dispose camera controller
  Future<void> _disposeCamera() async {
    if (_cameraController != null) {
      if (_cameraController!.value.isInitialized) {
        try {
          await _cameraController!.dispose();
          debugPrint('Camera controller disposed');
        } catch (e) {
          debugPrint('Error disposing camera controller: $e');
        }
      }
      _cameraController = null;
      _isCameraRunning = false;
    }
  }

  /// Show dialog to guide user to app settings for permission
  void _showPermissionSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text(
              'This app needs camera access to detect and analyze food. '
                  'Please grant camera permission in app settings.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
}