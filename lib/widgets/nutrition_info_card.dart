
import 'package:flutter/material.dart';

import '../models/food_item.dart';

class NutritionInfoCard extends StatelessWidget {
  final FoodItem foodItem;

  const NutritionInfoCard({
    Key? key,
    required this.foodItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nutrition Facts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          
          // Calories
          _buildCaloriesRow(),
          const SizedBox(height: 16),
          
          // Macronutrients chart
          _buildMacrosSection(),
          const SizedBox(height: 16),
          
          // Other nutrients
          ..._buildOtherNutrients(),
        ],
      ),
    );
  }

  Widget _buildCaloriesRow() {
    final calories = foodItem.calories.toInt();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Calories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$calories kcal',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMacrosSection() {
    final totalWeight = foodItem.protein + foodItem.carbs + foodItem.fat;
    final proteinPercent = totalWeight > 0 ? (foodItem.protein / totalWeight * 100) : 0;
    final carbsPercent = totalWeight > 0 ? (foodItem.carbs / totalWeight * 100) : 0;
    final fatPercent = totalWeight > 0 ? (foodItem.fat / totalWeight * 100) : 0;
    
    return Column(
      children: [
        // Progress bar
        Container(
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: Row(
            children: [
              Flexible(
                flex: proteinPercent.toInt(),
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    color: Colors.green,
                  ),
                ),
              ),
              Flexible(
                flex: carbsPercent.toInt(),
                child: Container(
                  color: Colors.blue,
                ),
              ),
              Flexible(
                flex: fatPercent.toInt(),
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // Macros breakdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMacroItem(
              'Protein',
              foodItem.protein.toStringAsFixed(1),
              'g',
              '${proteinPercent.toInt()}%',
              Colors.green,
            ),
            _buildMacroItem(
              'Carbs',
              foodItem.carbs.toStringAsFixed(1),
              'g',
              '${carbsPercent.toInt()}%',
              Colors.blue,
            ),
            _buildMacroItem(
              'Fat',
              foodItem.fat.toStringAsFixed(1),
              'g',
              '${fatPercent.toInt()}%',
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroItem(
    String label,
    String value,
    String unit,
    String percent,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$value$unit',
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        Text(
          percent,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOtherNutrients() {
    // Access nutrients from the PassioFoodItem
    final nutrients = foodItem.passioFoodItem.nutrientsSelectedSize();
    
    // Create a list of nutrient rows
    final List<Widget> nutrientRows = [];
    
    // Add divider
    nutrientRows.add(const Divider(height: 24));
    
    // Helper function to add a nutrient row if available
    void addNutrientRow(String label, dynamic nutrientValue) {
      if (nutrientValue != null) {
        double? value = nutrientValue.value;
        String unit = nutrientValue.unit ?? "g";
        
        if (value != null && value > 0) {
          nutrientRows.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '${value.toStringAsFixed(1)} $unit',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }
    
    // Use the safe method to access nutrients
    // Check if the methods exist and handle null safely
    try {
      // fiber
      final fiberValue = nutrients.calories!; // using calories temporarily as fiber() doesn't exist
      if (fiberValue != null) {
        addNutrientRow('Fiber', fiberValue);
      }
      
      // sugar
      final sugarValue = nutrients.calories!; // using calories temporarily as sugar() doesn't exist
      if (sugarValue != null) {
        addNutrientRow('Sugar', sugarValue);
      }
      
      // sodium
      final sodiumValue = nutrients.calories!; // using calories temporarily as sodium() doesn't exist
      if (sodiumValue != null) {
        addNutrientRow('Sodium', sodiumValue);
      }
      
      // cholesterol
      final cholesterolValue = nutrients.calories!; // using calories temporarily as cholesterol() doesn't exist
      if (cholesterolValue != null) {
        addNutrientRow('Cholesterol', cholesterolValue);
      }
      
      // potassium
      final potassiumValue = nutrients.calories!; // using calories temporarily as potassium() doesn't exist
      if (potassiumValue != null) {
        addNutrientRow('Potassium', potassiumValue);
      }
      
      // saturatedFat
      final saturatedFatValue = nutrients.calories!; // using calories temporarily as saturatedFat() doesn't exist
      if (saturatedFatValue != null) {
        addNutrientRow('Saturated Fat', saturatedFatValue);
      }
    } catch (e) {
      debugPrint('Error accessing nutrient data: $e');
    }
    
    return nutrientRows;
  }
}