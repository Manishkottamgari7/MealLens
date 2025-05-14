// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'dart:io';
//
// class CameraService {
//   static List<CameraDescription> cameras = [];
//   static bool _isInitializing = false;
//   static CameraController? _activeCameraController;
//
//   /// Initialize available cameras
//   static Future<void> initialize() async {
//     if (_isInitializing) {
//       debugPrint('Camera initialization already in progress');
//       return;
//     }
//
//     _isInitializing = true;
//     try {
//       debugPrint('Initializing cameras...');
//       cameras = await availableCameras();
//       debugPrint('Available cameras: ${cameras.length}');
//
//       // Print camera details for debugging
//       for (var i = 0; i < cameras.length; i++) {
//         debugPrint('Camera $i: ${cameras[i].name}, direction: ${cameras[i].lensDirection}');
//       }
//     } on CameraException catch (e) {
//       debugPrint('Camera initialization error: ${e.description}');
//     } catch (e) {
//       debugPrint('Unexpected error initializing cameras: $e');
//     } finally {
//       _isInitializing = false;
//     }
//   }
//   static Future<bool> requestCameraAccess(BuildContext context) async {
//     final status = await Permission.camera.status;
//
//     if (status.isGranted) {
//       debugPrint('Camera permission already granted');
//       return true;
//     }
//
//     if (status.isPermanentlyDenied) {
//       debugPrint('Camera permission permanently denied. Prompting user.');
//       await openAppSettings(); // Open system settings
//       return false;
//     }
//
//     final result = await Permission.camera.request();
//     return result.isGranted;
//   }
//
//   //
//   // /// Request camera permission with improved iOS handling
//   // static Future<bool> requestCameraAccess(BuildContext context) async {
//   //   try {
//   //     // Double-check if we already have permission
//   //     final status = await Permission.camera.status;
//   //     debugPrint('Current camera permission status: $status');
//   //
//   //     if (status.isGranted) {
//   //       debugPrint('Camera permission already granted');
//   //       return true;
//   //     }
//   //
//   //     // Request permission directly
//   //     final result = await Permission.camera.request();
//   //     debugPrint('Camera permission request result: $result');
//   //
//   //     if (result.isGranted) {
//   //       return true;
//   //     }
//   //
//   //     // For iOS, try platform-specific approach
//   //     if (Platform.isIOS && (result.isDenied || result.isPermanentlyDenied)) {
//   //       try {
//   //         debugPrint('Attempting iOS-specific camera permission request');
//   //         const platform = MethodChannel('com.demo.app/camera');
//   //         final bool granted = await platform.invokeMethod('requestCameraPermission');
//   //         debugPrint('iOS-specific camera permission result: $granted');
//   //         return granted;
//   //       } catch (e) {
//   //         debugPrint('iOS platform channel error: $e');
//   //       }
//   //     }
//   //
//   //     debugPrint('Camera permission denied');
//   //     return false;
//   //   } catch (e) {
//   //     debugPrint('Error requesting camera permission: $e');
//   //     return false;
//   //   }
//   // }
//
//   /// Get a camera controller with proper configuration
//   static Future<CameraController?> getCameraController({
//     ResolutionPreset resolution = ResolutionPreset.high,
//   }) async {
//     // Clean up any existing controller
//     await _disposeCurrentController();
//
//     // Make sure cameras are initialized
//     if (cameras.isEmpty) {
//       debugPrint('No cameras available, initializing...');
//       await initialize();
//       if (cameras.isEmpty) {
//         debugPrint('No cameras available after initialization');
//         return null;
//       }
//     }
//
//     try {
//       // Find back camera for food detection
//       debugPrint('Selecting camera for food detection');
//       CameraDescription selectedCamera;
//
//       try {
//         // Prefer back camera for food detection
//         selectedCamera = cameras.firstWhere(
//               (camera) => camera.lensDirection == CameraLensDirection.back,
//         );
//         debugPrint('Using back camera: ${selectedCamera.name}');
//       } catch (e) {
//         // Fall back to first available camera
//         debugPrint('Back camera not found, using first available camera');
//         selectedCamera = cameras.first;
//       }
//
//       // Create and initialize controller with specific settings for iOS
//       debugPrint('Creating camera controller with ${resolution.toString()}');
//       final cameraController = CameraController(
//         selectedCamera,
//         resolution,
//         enableAudio: false,
//         imageFormatGroup: Platform.isAndroid
//             ? ImageFormatGroup.yuv420
//             : ImageFormatGroup.bgra8888,
//       );
//
//       // Apply iOS-specific settings with try-catch blocks
//       if (Platform.isIOS) {
//         debugPrint('Applying iOS-specific camera settings');
//
//         try {
//           // Explicitly modify camera controller behavior for iOS
//           cameraController.setFlashMode(FlashMode.off);
//         } catch (e) {
//           debugPrint('Error setting flash mode: $e');
//         }
//       }
//
//       // Initialize the controller
//       debugPrint('Initializing camera controller...');
//       await cameraController.initialize().timeout(
//         const Duration(seconds: 10),
//         onTimeout: () {
//           debugPrint('Camera initialization timed out');
//           throw CameraException('timeout', 'Camera initialization timed out');
//         },
//       );
//
//       debugPrint('Camera controller initialized successfully');
//
//       // Configure optimal camera settings for food detection
//       if (cameraController.value.isInitialized) {
//         try {
//           // Set focus and exposure modes for better food detection
//           await cameraController.setFocusMode(FocusMode.auto);
//           await cameraController.setExposureMode(ExposureMode.auto);
//           debugPrint('Camera focus and exposure set to auto');
//         } catch (e) {
//           debugPrint('Error setting camera parameters: $e');
//           // Continue even if these settings fail
//         }
//       }
//
//       // Save the active controller
//       _activeCameraController = cameraController;
//       return cameraController;
//     } catch (e) {
//       debugPrint('Error creating camera controller: $e');
//       return null;
//     }
//   }
//
//   /// Get a properly configured camera controller specifically for iOS
//   static Future<CameraController?> getIOSCameraController({
//     ResolutionPreset resolution = ResolutionPreset.high,
//   }) async {
//     if (!Platform.isIOS) {
//       return getCameraController(resolution: resolution);
//     }
//
//     // Clean up any existing controller
//     await _disposeCurrentController();
//
//     // Make sure cameras are initialized
//     if (cameras.isEmpty) {
//       await initialize();
//       if (cameras.isEmpty) {
//         return null;
//       }
//     }
//
//     try {
//       // Find back camera - on iOS, the first back camera is typically the wide angle
//       final selectedCamera = cameras.firstWhere(
//             (camera) => camera.lensDirection == CameraLensDirection.back,
//         orElse: () => cameras.first,
//       );
//
//       debugPrint('Creating iOS camera controller with ${selectedCamera.name}');
//
//       // For iOS, we need to use specific settings
//       final cameraController = CameraController(
//         selectedCamera,
//         resolution,
//         enableAudio: false,
//         imageFormatGroup: ImageFormatGroup.bgra8888, // iOS specific
//       );
//
//       // Initialize with explicit timeout
//       await cameraController.initialize().timeout(
//         const Duration(seconds: 10),
//         onTimeout: () {
//           debugPrint('iOS camera initialization timed out');
//           throw CameraException('timeout', 'Camera initialization timed out');
//         },
//       );
//
//       // Apply iOS-specific fixes
//       await applyIOSCameraFixes(cameraController);
//
//       // Save the active controller
//       _activeCameraController = cameraController;
//       return cameraController;
//     } catch (e) {
//       debugPrint('Error creating iOS camera controller: $e');
//       return null;
//     }
//   }
//
//   /// Apply iOS-specific camera fixes that resolve common preview issues
//   static Future<void> applyIOSCameraFixes(CameraController controller) async {
//     if (!Platform.isIOS || !controller.value.isInitialized) {
//       return;
//     }
//
//     try {
//       debugPrint('Applying iOS-specific camera fixes');
//
//       // Set the flash mode to off to avoid permissions issues
//       await controller.setFlashMode(FlashMode.off);
//
//       // Set the exposure mode
//       try {
//         await controller.setExposureMode(ExposureMode.auto);
//       } catch (e) {
//         debugPrint('Error setting exposure mode: $e');
//       }
//
//       // Set focus mode
//       try {
//         await controller.setFocusMode(FocusMode.auto);
//       } catch (e) {
//         debugPrint('Error setting focus mode: $e');
//       }
//
//       // Additional iOS fix for preview orientation
//       if (controller.description.sensorOrientation == 90 ||
//           controller.description.sensorOrientation == 270) {
//         debugPrint('Fixing iOS camera orientation');
//         // This is a placeholder for any additional orientation fixes needed
//       }
//
//       // Force the preview to update if needed
//       if (controller.value.isPreviewPaused) {
//         await controller.resumePreview();
//       }
//
//       debugPrint('iOS camera fixes applied');
//     } catch (e) {
//       debugPrint('Error applying iOS camera fixes: $e');
//     }
//   }
//
//   /// Dispose the current camera controller safely
//   static Future<void> _disposeCurrentController() async {
//     if (_activeCameraController != null) {
//       if (_activeCameraController!.value.isInitialized) {
//         debugPrint('Disposing active camera controller');
//         try {
//           await _activeCameraController!.dispose();
//         } catch (e) {
//           debugPrint('Error disposing camera controller: $e');
//         }
//       }
//       _activeCameraController = null;
//     }
//   }
//
//   /// Dispose any controller passed in
//   static Future<void> disposeController(CameraController? controller) async {
//     if (controller != null && controller.value.isInitialized) {
//       try {
//         debugPrint('Disposing provided camera controller');
//         await controller.dispose();
//       } catch (e) {
//         debugPrint('Error disposing provided camera controller: $e');
//       }
//     }
//   }
// }


import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/IOSCameraHelper.dart';

/// A service class to manage camera initialization and interaction
class CameraService {
  static List<CameraDescription> _cameras = [];

  /// Initialize cameras
  static Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      debugPrint('Initializing cameras...');

      for (int i = 0; i < _cameras.length; i++) {
        debugPrint('Camera $i: ${_cameras[i].name}, direction: ${_cameras[i].lensDirection}');
      }
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
      rethrow;
    }
  }

  /// Request camera access with improved error handling
  static Future<bool> requestCameraAccess(BuildContext context) async {
    try {
      final status = await Permission.camera.status;

      // If already granted, return true
      if (status.isGranted) {
        return true;
      }

      // Request permission
      PermissionStatus result = await Permission.camera.request();

      // If granted after request, return true
      if (result.isGranted) {
        return true;
      }

      // For iOS, try a platform-specific approach if regular request fails
      if (Platform.isIOS && (result.isDenied || result.isPermanentlyDenied)) {
        try {
          const platform = MethodChannel('com.demo.app/camera');
          final bool granted = await platform.invokeMethod('requestCameraPermission');
          return granted;
        } catch (e) {
          debugPrint('Platform channel error: $e');
        }
      }

      // Handle permanently denied case
      if (context.mounted && (result.isPermanentlyDenied || result.isDenied)) {
        // Show permission settings dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Camera Permission Required'),
            content: const Text(
              'This app needs camera access to detect food. Please enable it in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      return false;
    }
  }

  /// Get camera controller for iOS devices with appropriate settings
  static Future<CameraController?> getIOSCameraController({
    ResolutionPreset resolution = ResolutionPreset.high,
  }) async {
    try {
      // Ensure cameras are initialized
      if (_cameras.isEmpty) {
        await initialize();
      }

      if (_cameras.isEmpty) {
        debugPrint('No cameras available');
        return null;
      }

      // Select back camera for food detection
      final backCamera = _cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      debugPrint('iOS: Preparing camera controller for ${backCamera.name}');

      // Create controller with iOS-specific settings
      final controller = CameraController(
        backCamera,
        resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888, // Use bgra8888 format for iOS
      );

      // Initialize with timeout
      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Camera initialization timed out');
        },
      );

      // Apply iOS-specific optimizations
      await IOSCameraHelper.optimizeCameraForFoodDetection(controller);

      return controller;
    } catch (e) {
      debugPrint('Error creating iOS camera controller: $e');
      return null;
    }
  }

  /// Get camera controller for any platform
  static Future<CameraController?> getCameraController({
    ResolutionPreset resolution = ResolutionPreset.high,
  }) async {
    try {
      // For iOS, use the iOS-specific controller
      if (Platform.isIOS) {
        return getIOSCameraController(resolution: resolution);
      }

      // Ensure cameras are initialized
      if (_cameras.isEmpty) {
        await initialize();
      }

      if (_cameras.isEmpty) {
        debugPrint('No cameras available');
        return null;
      }

      // Select back camera for food detection
      final backCamera = _cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      // Create controller for Android or other platforms
      final controller = CameraController(
        backCamera,
        resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // yuv420 is recommended for Android
      );

      // Initialize with timeout
      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Camera initialization timed out');
        },
      );

      return controller;
    } catch (e) {
      debugPrint('Error creating camera controller: $e');
      return null;
    }
  }

  /// Safely dispose a camera controller
  static Future<void> disposeController(CameraController? controller) async {
    if (controller != null && controller.value.isInitialized) {
      try {
        await controller.dispose();
        debugPrint('Camera controller disposed');
      } catch (e) {
        debugPrint('Error disposing camera controller: $e');
      }
    }
  }
}