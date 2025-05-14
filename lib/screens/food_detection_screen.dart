import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:nutrition_ai/nutrition_ai.dart';
import 'dart:io';

import '../models/food_item.dart';
import '../utils/IOSCameraHelper.dart';
import '../utils/passio_integration_helper.dart';
import '../widgets/passio_id_image_widget.dart';
import 'food_details_screen.dart';

class FoodDetectionScreen extends StatefulWidget {
  const FoodDetectionScreen({Key? key}) : super(key: key);

  @override
  State<FoodDetectionScreen> createState() => _FoodDetectionScreenState();
}

class _FoodDetectionScreenState extends State<FoodDetectionScreen>
    implements FoodRecognitionListener {
  // Passio helper instance
  final _passioHelper = PassioIntegrationHelper();

  // UI state
  bool _isLoading = true;
  String _statusMessage = 'Initializing...';
  bool _isDetecting = false;
  bool _isCameraReady = false;

  // Detected food items
  List<PassioAdvisorFoodInfo> _detectedItems = [];

  @override
  void initState() {
    super.initState();
    // For iOS, suppress CoreML warnings
    if (Platform.isIOS) {
      IOSCameraHelper.suppressNeuralNetworkWarnings();
    }
    _initializeScreen();
  }

  @override
  void dispose() {
    _passioHelper.dispose();
    super.dispose();
  }

  // Initialize the screen with Passio SDK and camera
  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing Passio SDK...';
    });

    // Initialize Passio SDK with your API key
    final sdkInitialized = await _passioHelper.initializePassioSDK(
      apiKey: 'k2pz9c0WJFX2AlytO6Xd2wLaPPyFYO90e7U7Venh', // Your actual key
      remoteOnly: Platform.isIOS, // Use remote API on iOS
    );

    if (!sdkInitialized) {
      setState(() {
        _statusMessage = 'Failed to initialize Passio SDK: ${_passioHelper.lastError}';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _statusMessage = 'Setting up camera...';
    });

    // Setup camera
    final cameraReady = await _passioHelper.setupCamera(context: context);

    if (!cameraReady) {
      setState(() {
        _statusMessage = 'Failed to initialize camera: ${_passioHelper.lastError}';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isCameraReady = true;
      _isLoading = false;
      _statusMessage = 'Ready for food detection';
    });

    // Start detection automatically
    if (_isCameraReady) {
      _startDetection();
    }
  }

  // Start food detection
  Future<void> _startDetection() async {
    if (_isDetecting) return;

    setState(() {
      _statusMessage = 'Starting food detection...';
      _isLoading = true;
    });

    final started = await _passioHelper.startFoodDetection(this);

    setState(() {
      _isDetecting = started;
      _isLoading = false;
      _statusMessage = started
          ? 'Point camera at food to detect'
          : 'Failed to start detection: ${_passioHelper.lastError}';
    });
  }

  // Stop food detection
  Future<void> _stopDetection() async {
    if (!_isDetecting) return;

    await _passioHelper.stopFoodDetection();

    setState(() {
      _isDetecting = false;
      _statusMessage = 'Detection stopped';
    });
  }

  // Called when a food is recognized
  @override
  void recognitionResults(FoodCandidates? foodCandidates, PlatformImage? image) {
    if (foodCandidates == null || !mounted) return;

    // Process and convert detected candidates
    _processDetectedCandidates(foodCandidates);
  }

  // Process detected food candidates and update UI
  Future<void> _processDetectedCandidates(FoodCandidates foodCandidates) async {
    List<PassioAdvisorFoodInfo> items = [];

    // Process visual candidates
    if (foodCandidates.detectedCandidates != null &&
        foodCandidates.detectedCandidates!.isNotEmpty) {
      for (final candidate in foodCandidates.detectedCandidates!) {
        try {
          // Get food item details
          final foodItem = await NutritionAI.instance.fetchFoodItemForPassioID(
              candidate.passioID
          );

          if (foodItem != null) {
            // Create food data info
            final foodDataInfo = PassioFoodDataInfo(
              foodName: candidate.foodName,
              iconID: candidate.passioID,
              brandName: '',
              score: candidate.confidence,
              labelId: '',
              resultId: '',
              scoredName: candidate.foodName,
              type: 'visual',
              isShortName: false,
              refCode: '',
              nutritionPreview: PassioSearchNutritionPreview(
                calories: 0,
                protein: 0.0,
                carbs: 0.0,
                fat: 0.0,
                fiber: 0.0,
                servingUnit: 'g',
                servingQuantity: 100.0,
                weightUnit: 'g',
                weightQuantity: 100.0,
              ),
              tags: [],
            );

            // Create advisor food info
            final advisorFoodInfo = PassioAdvisorFoodInfo(
              recognisedName: candidate.foodName,
              portionSize: "100g",
              weightGrams: 100,
              foodDataInfo: foodDataInfo,
              packagedFoodItem: foodItem,
              resultType: PassioFoodResultType.foodItem,
            );

            items.add(advisorFoodInfo);
          }
        } catch (e) {
          debugPrint('Error processing candidate: $e');
        }
      }
    }

    // Process barcode candidates
    if (foodCandidates.barcodeCandidates != null &&
        foodCandidates.barcodeCandidates!.isNotEmpty) {
      for (final barcode in foodCandidates.barcodeCandidates!) {
        try {
          final foodItem = await NutritionAI.instance.fetchFoodItemForProductCode(
              barcode.value
          );

          if (foodItem != null) {
            final advisorFoodInfo = PassioAdvisorFoodInfo(
              recognisedName: foodItem.name,
              portionSize: "1 serving",
              weightGrams: 100,
              packagedFoodItem: foodItem,
              resultType: PassioFoodResultType.barcode,
            );

            items.add(advisorFoodInfo);
          }
        } catch (e) {
          debugPrint('Error processing barcode: $e');
        }
      }
    }

    // Update UI with detected items
    if (items.isNotEmpty && mounted) {
      setState(() {
        _detectedItems = items;
        _statusMessage = 'Food detected! (${items.length} items)';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Detection'),
        actions: [
          IconButton(
            icon: Icon(_isDetecting ? Icons.pause : Icons.play_arrow),
            onPressed: _isCameraReady
                ? (_isDetecting ? _stopDetection : _startDetection)
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _buildCameraPreview(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _statusMessage,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildDetectedItemsList(),
          ),
        ],
      ),
    );
  }

  // Build camera preview widget
  Widget _buildCameraPreview() {
    if (_isLoading || !_isCameraReady) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final controller = _passioHelper.cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Text('Camera initialization failed'),
      );
    }

    // Handle camera orientation for iOS specifically
    if (Platform.isIOS) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 1 / controller.value.aspectRatio,
          child: CameraPreview(controller),
        ),
      );
    }

    // Default camera preview for all platforms
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CameraPreview(controller),
    );
  }

  // Build list of detected food items
  Widget _buildDetectedItemsList() {
    if (_detectedItems.isEmpty) {
      return const Center(
        child: Text('No food detected yet. Point camera at food.'),
      );
    }

    return ListView.builder(
      itemCount: _detectedItems.length,
      itemBuilder: (context, index) {
        final item = _detectedItems[index];
        return ListTile(
          leading: _buildFoodIcon(item),
          title: Text(item.recognisedName),
          subtitle: Text('${item.portionSize} (${item.weightGrams}g)'),
          trailing: Text(
            _getCaloriesText(item),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: () => _showFoodDetails(item),
        );
      },
    );
  }

  // Build food icon for the item
  Widget _buildFoodIcon(PassioAdvisorFoodInfo item) {
    String iconID = '';

    if (item.foodDataInfo != null) {
      iconID = item.foodDataInfo!.iconID;
    } else if (item.packagedFoodItem != null) {
      iconID = item.packagedFoodItem!.iconId;
    }

    if (iconID.isEmpty) {
      return const CircleAvatar(
        child: Icon(Icons.fastfood),
      );
    }

    // Use the custom PassioIDImageWidget
    return PassioIDImageWidget(
      iconID,
      size: IconSize.px90,
      width: 40,
      height: 40,
      errorWidget: const CircleAvatar(child: Icon(Icons.fastfood)),
    );
  }

  // Get calories text for display
  String _getCaloriesText(PassioAdvisorFoodInfo item) {
    if (item.packagedFoodItem != null) {
      final nutrients = item.packagedFoodItem!.nutrientsReference();
      final calories = nutrients.calories?.value;
      return calories != null ? '$calories kcal' : 'n/a';
    }

    if (item.foodDataInfo?.nutritionPreview?.calories != null) {
      return '${item.foodDataInfo!.nutritionPreview!.calories} kcal';
    }

    return 'n/a';
  }

  // Show detailed information about the selected food
  void _showFoodDetails(PassioAdvisorFoodInfo item) {
    // Navigate to the food details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodDetailsScreen(
          foodInfo: item,
        ),
      ),
    );
  }
}