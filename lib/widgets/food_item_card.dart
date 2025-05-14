
import 'package:flutter/material.dart';
import 'package:nutrition_ai/nutrition_ai.dart';

import '../models/food_log_entry.dart';

class FoodItemCard extends StatelessWidget {
  final FoodLogEntry foodLogEntry;
  final VoidCallback? onDelete;

  const FoodItemCard({
    Key? key,
    required this.foodLogEntry,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final foodItem = foodLogEntry.foodItem;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food icon
            _buildFoodIcon(),
            const SizedBox(width: 12),
            
            // Food info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foodItem.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${foodLogEntry.quantity} ${foodLogEntry.unit}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildNutrientInfo(),
                ],
              ),
            ),
            
            // Delete button
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodIcon() {
    final iconId = foodLogEntry.foodItem.iconId;
    
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: iconId != null && iconId.isNotEmpty
          ? FutureBuilder<Widget>(
              future: _loadIcon(iconId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  return snapshot.data!;
                }
                return const Icon(Icons.fastfood, size: 30, color: Colors.grey);
              },
            )
          : const Icon(Icons.fastfood, size: 30, color: Colors.grey),
    );
  }
  
  Future<Widget> _loadIcon(String iconId) async {
    try {
      final iconUrl = 'https://storage.googleapis.com/passio-prod-env-public-cdn-data/label-icons/$iconId-90.jpg';
      return Image.network(
        iconUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.fastfood, size: 30, color: Colors.grey);
        },
      );
    } catch (e) {
      return const Icon(Icons.fastfood, size: 30, color: Colors.grey);
    }
  }

  Widget _buildNutrientInfo() {
    return Row(
      children: [
        _buildNutrientItem(
          'Calories', 
          '${foodLogEntry.calories.toInt()}',
          'kcal',
          Colors.orange,
        ),
        const SizedBox(width: 16),
        _buildNutrientItem(
          'Protein', 
          '${foodLogEntry.protein.toStringAsFixed(1)}',
          'g',
          Colors.green,
        ),
        const SizedBox(width: 16),
        _buildNutrientItem(
          'Carbs', 
          '${foodLogEntry.carbs.toStringAsFixed(1)}',
          'g',
          Colors.blue,
        ),
        const SizedBox(width: 16),
        _buildNutrientItem(
          'Fat', 
          '${foodLogEntry.fat.toStringAsFixed(1)}',
          'g',
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildNutrientItem(String label, String value, String unit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$value $unit',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}