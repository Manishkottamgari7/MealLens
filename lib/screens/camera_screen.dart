import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:nutrition_ai/nutrition_ai.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/passio_provider.dart';
import '../utils/IOSCameraHelper.dart';
import '../utils/permission_fix.dart'; // Import the new class
import '../widgets/camera_controls.dart';
import '../widgets/passio_id_image_widget.dart';
import 'food_details_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  // Camera state
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;

  // UI state
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Detection state
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // On iOS, suppress CoreML warnings
    if (Platform.isIOS) {
      IOSCameraHelper.suppressNeuralNetworkWarnings();
    }

    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopDetection();
    _disposeCameraController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes for camera
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopDetection();
      _disposeCameraController();
    } else if (state == AppLifecycleState.resumed) {
      _reinitializeCamera();
    }
  }

  // Add this to your _CameraScreenState class:
  bool _showDebugInfo = false;

  // Then add this method:
  Widget _buildDebugInfo() {
    if (!_showDebugInfo) return const SizedBox.shrink();

    final cameraInfo = _cameraController?.description;
    final previewSize = _cameraController?.value.previewSize;

    return Positioned(
      top: MediaQuery.of(context).padding.top + kToolbarHeight + 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Camera: ${cameraInfo?.name ?? "None"}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              'Resolution: ${previewSize?.width.toInt() ?? 0} x ${previewSize?.height.toInt() ?? 0}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              'Streaming: ${_cameraController?.value.isStreamingImages ?? false}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              'Detecting: $_isDetecting',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reinitializeCamera() async {
    // When returning to the app, ensure we refresh permission status
    final permissionGranted = await PermissionFix.refreshCameraPermission();
    setState(() {
      _isCameraPermissionGranted = permissionGranted;
    });

    if (_isCameraPermissionGranted) {
      _initializeCamera();
    }
  }

  // Add this method to your _CameraScreenState class:
  Future<void> _resetCameraStream() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    try {
      // Force refresh the camera stream
      await _cameraController!.pausePreview();
      await Future.delayed(const Duration(milliseconds: 300));
      await _cameraController!.resumePreview();

      debugPrint('Camera stream reset successfully');
    } catch (e) {
      debugPrint('Error resetting camera stream: $e');
    }
  }

  Future<void> _initializeCamera() async {
    setState(() => _isLoading = true);

    try {
      // First check if Passio SDK is initialized
      final passioProvider = Provider.of<PassioProvider>(
        context,
        listen: false,
      );
      if (passioProvider.sdkStatus != PassioSdkStatus.ready) {
        await passioProvider.initializePassioSDK();
      }

      // Use our improved permission checking
      final permissionGranted = await PermissionFix.refreshCameraPermission();

      debugPrint('Permission check result: $permissionGranted');
      setState(() {
        _isCameraPermissionGranted = permissionGranted;
      });

      if (!_isCameraPermissionGranted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Camera permission required';
        });
        return;
      }

      // Dispose any existing controller first
      await _disposeCameraController();

      // Get available cameras
      _cameras = await availableCameras();
      debugPrint('Available cameras: ${_cameras!.length}');

      if (_cameras!.isEmpty) {
        throw Exception('No cameras available on device');
      }

      // Select back camera for food detection
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      debugPrint(
        'Selected camera: ${backCamera.name}, direction: ${backCamera.lensDirection}',
      );

      // Create camera controller with improved settings
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium, // Use medium for better performance
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS
                ? ImageFormatGroup.bgra8888
                : ImageFormatGroup.yuv420,
      );

      // Initialize with proper error handling
      await _cameraController!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Camera initialization timed out');
        },
      );

      // Force camera orientation to portrait for consistency
      await _cameraController!.lockCaptureOrientation(
        DeviceOrientation.portraitUp,
      );

      // Set flash to off for better detection
      await _cameraController!.setFlashMode(FlashMode.off);

      // Platform-specific camera optimizations
      if (Platform.isIOS) {
        debugPrint('iOS: Preparing AVCaptureSession');
        await IOSCameraHelper.setupCameraFocus(_cameraController!);
        await IOSCameraHelper.optimizeCameraForFoodDetection(
          _cameraController!,
        );
        debugPrint('iOS: AVCaptureSession preparation complete');
      }

      // Android-specific settings
      if (Platform.isAndroid) {
        // Set exposure and focus modes
        await _cameraController!.setExposureMode(ExposureMode.auto);
        await _cameraController!.setFocusMode(FocusMode.auto);
      }

      // Start streaming immediately to avoid freezing
      if (!_cameraController!.value.isStreamingImages) {
        await _cameraController!.startImageStream((image) {
          // Just keep stream active, actual processing is done in Passio SDK
        });
      }

      setState(() {
        _isCameraInitialized = true;
        _isLoading = false;
        _hasError = false;
      });

      // Small delay before starting detection
      await Future.delayed(const Duration(milliseconds: 500));

      // Start food detection if SDK is ready
      if (passioProvider.sdkStatus == PassioSdkStatus.ready) {
        _startDetection();
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _disposeCameraController() async {
    if (_cameraController != null) {
      try {
        if (_cameraController!.value.isInitialized) {
          await _cameraController!.dispose();
        }
      } catch (e) {
        debugPrint('Error disposing camera: $e');
      }
      _cameraController = null;
      _isCameraInitialized = false;
    }
  }

  Future<void> _startDetection() async {
    if (!_isCameraInitialized || _cameraController == null) {
      debugPrint('Cannot start detection - camera not initialized');
      return;
    }

    final passioProvider = Provider.of<PassioProvider>(context, listen: false);
    if (passioProvider.sdkStatus != PassioSdkStatus.ready) {
      debugPrint('Cannot start detection - Passio SDK not ready');
      return;
    }

    if (_isDetecting) {
      debugPrint('Detection already active');
      return;
    }

    try {
      // Reset camera stream first
      await _resetCameraStream();

      // Now start food detection
      passioProvider.startFoodDetection();

      setState(() {
        _isDetecting = true;
      });

      debugPrint('Food detection started successfully');
    } catch (e) {
      debugPrint('Error starting food detection: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start detection: $e')));
    }
  }

  void _stopDetection() {
    if (!_isDetecting) return;

    final passioProvider = Provider.of<PassioProvider>(context, listen: false);
    passioProvider.stopFoodDetection();

    setState(() {
      _isDetecting = false;
    });

    debugPrint('Food detection stopped');
  }

  void _captureImage() async {
    if (!_isCameraInitialized || _cameraController == null) {
      debugPrint('Cannot capture - camera not initialized');
      return;
    }

    setState(() => _isLoading = true);
    _stopDetection(); // Pause detection while capturing

    try {
      // Capture image
      final XFile image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();

      // Recognize food in image
      final passioProvider = Provider.of<PassioProvider>(
        context,
        listen: false,
      );
      final foods = await passioProvider.recognizeFood(bytes);

      setState(() => _isLoading = false);

      if (foods != null && foods.isNotEmpty) {
        if (mounted) {
          // Navigate to food details screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FoodDetailsScreen(foodInfo: foods.first),
            ),
          ).then((_) {
            // Resume detection when returning
            if (mounted && _isCameraInitialized) {
              _startDetection();
            }
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No food detected in this image'),
            duration: Duration(seconds: 2),
          ),
        );
        _startDetection(); // Resume detection
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error capturing image: $e')));
      _startDetection(); // Resume detection
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Food Detection')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error screen
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Food Detection')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeCamera,
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    // Show permission request screen
    if (!_isCameraPermissionGranted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Camera Permission')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Camera Permission Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'This app needs camera access to detect food.\n'
                  'Please grant permission in settings.',
                  textAlign: TextAlign.center,
                ),
              ),
              if (Platform.isIOS)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  child: Text(
                    'Note: On iOS, you may need to restart the app after granting permission.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  // Force refresh permission status
                  final status = await PermissionFix.refreshCameraPermission();
                  if (mounted) {
                    setState(() {
                      _isCameraPermissionGranted = status;
                    });
                    if (status) {
                      _initializeCamera();
                    }
                  }
                },
                child: const Text('Retry'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    // Main camera screen
    return Scaffold(
      body: Stack(
        children: [
          // Camera preview
          _buildCameraPreview(),

          // Add this to your Stack in the build method (after _buildCameraPreview())
          IgnorePointer(
            child: CustomPaint(
              painter: DetectionAreaPainter(),
              size: MediaQuery.of(context).size,
            ),
          ),

          // App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              color: Colors.black.withOpacity(0.4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Food Detection',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isDetecting ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: _isDetecting ? _stopDetection : _startDetection,
                  ),
                  IconButton(
                    icon: const Icon(Icons.bug_report, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _showDebugInfo = !_showDebugInfo;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Camera controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CameraControls(
              onCapture: _captureImage,
              onImageSelected: (image) async {
                // Process selected image from gallery
                setState(() => _isLoading = true);
                try {
                  final bytes = await image.readAsBytes();
                  final passioProvider = Provider.of<PassioProvider>(
                    context,
                    listen: false,
                  );
                  final foods = await passioProvider.recognizeFood(bytes);

                  setState(() => _isLoading = false);

                  if (foods != null && foods.isNotEmpty && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                FoodDetailsScreen(foodInfo: foods.first),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No food detected in this image'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error processing image: $e')),
                  );
                }
              },
            ),
          ),

          // Detection results overlay
          Consumer<PassioProvider>(
            builder: (context, provider, child) {
              final detectedFoods = provider.detectedFoods;

              if (detectedFoods.isEmpty) {
                return const SizedBox.shrink();
              }

              return Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  color: Colors.black.withOpacity(0.5),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: detectedFoods.length,
                    itemBuilder: (context, index) {
                      final food = detectedFoods[index];
                      final iconID = food.foodDataInfo?.iconID ?? '';
                      final name =
                          food.foodDataInfo?.foodName ?? food.recognisedName;
                      final calories =
                          food.foodDataInfo?.nutritionPreview?.calories ?? 0;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      FoodDetailsScreen(foodInfo: food),
                            ),
                          );
                        },
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              iconID.isNotEmpty
                                  ? PassioIDImageWidget(
                                    iconID,
                                    width: 40,
                                    height: 40,
                                  )
                                  : const Icon(
                                    Icons.fastfood,
                                    color: Colors.white,
                                  ),
                              const SizedBox(height: 4),
                              Text(
                                name,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '$calories kcal',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          _buildDebugInfo(),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // Replace your _buildCameraPreview() method with this improved version
  Widget _buildCameraPreview() {
    if (!_isCameraInitialized ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const SizedBox.expand(
        child: ColoredBox(
          color: Colors.black,
          child: Center(
            child: Text(
              'Camera initializing...',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    // Get the screen size and camera preview size
    final screenSize = MediaQuery.of(context).size;
    final previewSize = _cameraController!.value.previewSize!;

    // Calculate preview aspect ratios
    final screenAspectRatio = screenSize.width / screenSize.height;
    final previewAspectRatio = previewSize.width / previewSize.height;

    // Determine the scale factor based on platform and orientation
    var scale = 1.0;

    if (Platform.isAndroid) {
      // On Android, adjust based on aspect ratio differences
      scale = screenAspectRatio / previewAspectRatio;
    } else if (Platform.isIOS) {
      // On iOS, we need to handle this differently as the camera preview is rotated
      scale = previewAspectRatio / screenAspectRatio;

      // Adjust scale based on orientation if needed
      if (MediaQuery.of(context).orientation == Orientation.portrait &&
          scale < 1.0) {
        scale = 1 / scale;
      }
    }

    // Create a container that's as large as possible
    return Container(
      color: Colors.black,
      width: screenSize.width,
      height: screenSize.height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: screenSize.width,
              height: screenSize.width * previewSize.height / previewSize.width,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
      ),
    );
  }
}

// Add this class at the bottom of your file
class DetectionAreaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Define detection area size (70% of the screen width)
    final areaSize = size.width * 0.7;

    // Calculate center position
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Create rectangle for detection area
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: areaSize,
      height: areaSize,
    );

    // Draw detection area border
    final borderPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    // Draw rounded rectangle
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rrect, borderPaint);

    // Draw corner highlights
    final cornerPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

    final cornerSize = 20.0;

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerSize),
      Offset(rect.left, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerSize, rect.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - cornerSize, rect.top),
      Offset(rect.right, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerSize),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerSize),
      Offset(rect.left, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerSize, rect.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right - cornerSize, rect.bottom),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerSize),
      cornerPaint,
    );

    // Optional: Add text guide at the top of the detection area
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    final textSpan = TextSpan(
      text: 'Position food item here',
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        rect.top - textPainter.height - 8,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
