import 'package:flutter/material.dart';
import 'package:nutrition_ai/nutrition_ai.dart';

/// Wrapper class for PassioFoodItem to add additional functionality
class FoodItem {
  final PassioFoodItem passioFoodItem;
  final String? iconId;
  final String? mealTime;
  final DateTime loggedTime;
  
  FoodItem({
    required this.passioFoodItem,
    this.iconId,
    this.mealTime,
    DateTime? loggedTime,
  }) : this.loggedTime = loggedTime ?? DateTime.now();

  // Properties from PassioFoodItem
  String get name => passioFoodItem.name;
  String get details => passioFoodItem.details;
  String get id => passioFoodItem.id;
  
  // Nutrition data
  double get calories {
    final nutrients = passioFoodItem.nutrientsSelectedSize();
    final caloriesObj = nutrients.calories!;
    return caloriesObj?.value ?? 0.0;
  }
  
  double get protein {
    final nutrients = passioFoodItem.nutrientsSelectedSize();
    final proteinObj = nutrients.proteins!;
    return proteinObj?.value ?? 0.0;
  }
  
  double get carbs {
    final nutrients = passioFoodItem.nutrientsSelectedSize();
    final carbsObj = nutrients.carbs!;
    return carbsObj?.value ?? 0.0;
  }
  
  double get fat {
    final nutrients = passioFoodItem.nutrientsSelectedSize();
    final fatObj = nutrients.fat!;
    return fatObj?.value ?? 0.0;
  }
  
  double get servingQuantity => passioFoodItem.amount.selectedQuantity;
  String get servingUnit => passioFoodItem.amount.selectedUnit;
  
  // Converts a PassioFoodItem to a FoodItem
  static FoodItem fromPassioFoodItem(PassioFoodItem passioFoodItem) {
    return FoodItem(
      passioFoodItem: passioFoodItem,
      iconId: passioFoodItem.iconId,
    );
  }
  
  // Converts a PassioAdvisorFoodInfo to a FoodItem (when available)
  static Future<FoodItem?> fromPassioAdvisorFoodInfo(
    PassioAdvisorFoodInfo foodInfo,
  ) async {
    if (foodInfo.packagedFoodItem != null) {
      return FoodItem(
        passioFoodItem: foodInfo.packagedFoodItem!,
        iconId: foodInfo.packagedFoodItem?.iconId,
      );
    } else if (foodInfo.foodDataInfo != null) {
      try {
        final foodItem = await NutritionAI.instance.fetchFoodItemForDataInfo(
          foodInfo.foodDataInfo!,
        );
        if (foodItem != null) {
          return FoodItem(
            passioFoodItem: foodItem,
            iconId: foodInfo.foodDataInfo?.iconID,
          );
        }
      } catch (e) {
        debugPrint('Error fetching food item: $e');
      }
    }
    return null;
  }
  
  // Updates the serving size
  void updateServingSize(double quantity, String unit) {
    // Use the correct method based on the PassioFoodItem class
    // This is an adaptation since the direct setSelectedQuantity/setSelectedUnit methods don't exist
    if (passioFoodItem.amount.selectedQuantity != quantity ||
        passioFoodItem.amount.selectedUnit != unit) {
      // In a real application, you would need to create a new PassioFoodItem or update the amount
      // Since we can't modify PassioFoodItem directly, this is a placeholder
      debugPrint('Updating serving size to: $quantity $unit');
    }
  }
  
  // To map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'details': details,
      'iconId': iconId,
      'mealTime': mealTime,
      'loggedTime': loggedTime.toIso8601String(),
      'servingQuantity': servingQuantity,
      'servingUnit': servingUnit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}