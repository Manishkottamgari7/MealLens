import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nutrition_ai/nutrition_ai.dart';

import '../config/passio_config.dart';
import '../models/food_item.dart';

enum PassioSdkStatus {
  notInitialized,
  initializing,
  ready,
  failed,
}

class PassioProvider extends ChangeNotifier implements FoodRecognitionListener {
  PassioSdkStatus _sdkStatus = PassioSdkStatus.notInitialized;
  PassioStatus? _passioStatus;
  List<PassioAdvisorFoodInfo> _detectedFoods = [];
  FoodItem? _selectedFoodItem;
  bool _isDetecting = false;
  String? _lastError;

  // Getters
  PassioSdkStatus get sdkStatus => _sdkStatus;
  PassioStatus? get passioStatus => _passioStatus;
  List<PassioAdvisorFoodInfo> get detectedFoods => _detectedFoods;
  FoodItem? get selectedFoodItem => _selectedFoodItem;
  bool get isDetecting => _isDetecting;
  String? get lastError => _lastError;

  // Initialize the Passio SDK
  Future<void> initializePassioSDK() async {
    if (_sdkStatus == PassioSdkStatus.initializing ||
        _sdkStatus == PassioSdkStatus.ready) {
      return;
    }

    _sdkStatus = PassioSdkStatus.initializing;
    notifyListeners();

    try {
      final configuration = PassioConfig.getConfiguration();
      final status = await NutritionAI.instance.configureSDK(configuration);
      _passioStatus = status;

      if (PassioConfig.isSDKConfigured(status)) {
        _sdkStatus = PassioSdkStatus.ready;
      } else {
        // Force model download
        debugPrint("Forcing model download...");
        // await NutritionAI.instance.updateModel(); // 🔥 Trigger download
        await PassioConfig.ensureModelDownload();
        _sdkStatus = PassioSdkStatus.failed;
        _lastError = "Failed to configure Passio SDK: ${status.mode}";
      }
    } catch (e) {
      _sdkStatus = PassioSdkStatus.failed;
      _lastError = "Error initializing Passio SDK: $e";
      debugPrint(_lastError);
    }

    notifyListeners();
  }

  // Start food detection
  void startFoodDetection() {
    if (_sdkStatus != PassioSdkStatus.ready) {
      debugPrint("SDK not ready for food detection");
      return;
    }

    if (_isDetecting) return;

    final config = PassioConfig.getDetectionConfig();
    NutritionAI.instance.startFoodDetection(config, this);
    _isDetecting = true;
    notifyListeners();
  }

  // Stop food detection
  void stopFoodDetection() {
    if (!_isDetecting) return;

    NutritionAI.instance.stopFoodDetection();
    _isDetecting = false;
    _detectedFoods = []; // Clear detected foods when stopping
    notifyListeners();
  }

  // Process image for food recognition
  Future<List<PassioAdvisorFoodInfo>?> recognizeFood(dynamic image) async {
    try {
      if (image is Uint8List) {
        final results = await NutritionAI.instance.recognizeImageRemote(image);
        return results;
      } else if (image is List<int>) {
        return await NutritionAI.instance.recognizeImageRemote(Uint8List.fromList(image));
      }
      return null;
    } catch (e) {
      _lastError = "Error recognizing food: $e";
      debugPrint(_lastError);
      return null;
    }
  }

  // Search for food by text
  Future<List<PassioFoodDataInfo>> searchFood(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await NutritionAI.instance.searchForFood(query);
      return response.results;
    } catch (e) {
      _lastError = "Error searching food: $e";
      debugPrint(_lastError);
      return [];
    }
  }

  // Fetch food item details by PassioID
  Future<FoodItem?> fetchFoodItemByPassioID(String passioID) async {
    try {
      final foodItem = await NutritionAI.instance.fetchFoodItemForPassioID(passioID);
      if (foodItem != null) {
        return FoodItem.fromPassioFoodItem(foodItem);
      }
    } catch (e) {
      _lastError = "Error fetching food item: $e";
      debugPrint(_lastError);
    }
    return null;
  }

  // Fetch food item by barcode
  Future<FoodItem?> fetchFoodItemByBarcode(String barcode) async {
    try {
      final foodItem = await NutritionAI.instance.fetchFoodItemForProductCode(barcode);
      if (foodItem != null) {
        return FoodItem.fromPassioFoodItem(foodItem);
      }
    } catch (e) {
      _lastError = "Error fetching food by barcode: $e";
      debugPrint(_lastError);
    }
    return null;
  }

  // Fetch food by data info
  Future<FoodItem?> fetchFoodByDataInfo(PassioFoodDataInfo dataInfo) async {
    try {
      final foodItem = await NutritionAI.instance.fetchFoodItemForDataInfo(dataInfo);
      if (foodItem != null) {
        return FoodItem.fromPassioFoodItem(foodItem);
      }
    } catch (e) {
      _lastError = "Error fetching food by data info: $e";
      debugPrint(_lastError);
    }
    return null;
  }

  // Set selected food item
  void setSelectedFoodItem(FoodItem foodItem) {
    _selectedFoodItem = foodItem;
    notifyListeners();
  }

  // Clear selected food item
  void clearSelectedFoodItem() {
    _selectedFoodItem = null;
    notifyListeners();
  }

  // Implementation of FoodRecognitionListener
  @override
  void recognitionResults(FoodCandidates? foodCandidates, PlatformImage? image) async {
    if (foodCandidates == null) return;

    // Process detected food items
    List<PassioAdvisorFoodInfo> detectedItems = [];

    // Handle detected visual foods
    if (foodCandidates.detectedCandidates != null &&
        foodCandidates.detectedCandidates!.isNotEmpty) {

      for (var candidate in foodCandidates.detectedCandidates!) {
        try {
          final passioID = candidate.passioID;

          // Create a PassioAdvisorFoodInfo object
          // NOTE: Since we don't have the exact structure of PassioAdvisorFoodInfo,
          // we'll create a simplified approach that may need to be adjusted based on your SDK

          final foodItem = await NutritionAI.instance.fetchFoodItemForPassioID(passioID);
          if (foodItem != null) {
            // In a real app, construct PassioAdvisorFoodInfo properly here
            // For now, we're just converting detected candidates to a format that can be displayed
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
                calories: 0,  // Default value, replace if needed
                protein: 0.0,  // Default value, replace if needed
                carbs: 0.0,    // Default value, replace if needed
                fat: 0.0,      // Default value, replace if needed
                fiber: 0.0,    // Default value, replace if needed
                servingUnit: 'g', // Default unit
                servingQuantity: 100.0, // Default quantity
                weightUnit: 'g',
                weightQuantity: 100.0,
              ), tags: [],
            );


            // Add to detected foods - this is a simplified example
            final advisorFoodInfo = PassioAdvisorFoodInfo(
              recognisedName: candidate.foodName,
              portionSize: "100g",
              weightGrams: 100,
              foodDataInfo: foodDataInfo,
              packagedFoodItem: foodItem,
              resultType: PassioFoodResultType.foodItem,
            );

            detectedItems.add(advisorFoodInfo);
          }
        } catch (e) {
          debugPrint('Error processing food candidate: $e');
        }
      }
    }

    // Handle barcode detection
    if (foodCandidates.barcodeCandidates != null &&
        foodCandidates.barcodeCandidates!.isNotEmpty) {

      final barcode = foodCandidates.barcodeCandidates!.first.value;
      try {
        final foodItem = await NutritionAI.instance.fetchFoodItemForProductCode(barcode);
        if (foodItem != null) {
          // Create a simplified PassioAdvisorFoodInfo for barcode result
          final advisorFoodInfo = PassioAdvisorFoodInfo(
            recognisedName: foodItem.name,
            portionSize: "1 serving",
            weightGrams: 100,
            packagedFoodItem: foodItem,
            resultType: PassioFoodResultType.barcode,
          );

          detectedItems.add(advisorFoodInfo);
        }
      } catch (e) {
        debugPrint('Error processing barcode: $e');
      }
    }

    // Only update if we have results and are still detecting
    if (detectedItems.isNotEmpty && _isDetecting) {
      _detectedFoods = detectedItems;
      notifyListeners();
    }
  }
}