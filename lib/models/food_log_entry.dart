
import 'package:intl/intl.dart';

import 'food_item.dart';

class FoodLogEntry {
  final String id;
  final FoodItem foodItem;
  final DateTime dateTime;
  final String mealType; // breakfast, lunch, dinner, snack
  final double quantity;
  final String unit;

  FoodLogEntry({
    required this.id,
    required this.foodItem,
    required this.dateTime, 
    required this.mealType,
    required this.quantity,
    required this.unit,
  });

  // Format date for display
  String get formattedDate => DateFormat('MMMM d, yyyy').format(dateTime);
  
  // Format time for display
  String get formattedTime => DateFormat('h:mm a').format(dateTime);
  
  // Calculate calories for this entry
  double get calories => foodItem.calories * (quantity / foodItem.servingQuantity);
  
  // Calculate proteins for this entry
  double get protein => foodItem.protein * (quantity / foodItem.servingQuantity);
  
  // Calculate carbs for this entry
  double get carbs => foodItem.carbs * (quantity / foodItem.servingQuantity);
  
  // Calculate fat for this entry
  double get fat => foodItem.fat * (quantity / foodItem.servingQuantity);

  // Create map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodItem': foodItem.toMap(),
      'dateTime': dateTime.toIso8601String(),
      'mealType': mealType,
      'quantity': quantity,
      'unit': unit,
    };
  }

  // Create a FoodLogEntry from a map
  factory FoodLogEntry.fromMap(Map<String, dynamic> map) {
    return FoodLogEntry(
      id: map['id'],
      foodItem: FoodItem(
        passioFoodItem: null as dynamic, // This would need to be reconstructed properly
        iconId: map['foodItem']['iconId'],
        mealTime: map['foodItem']['mealTime'],
        loggedTime: DateTime.parse(map['foodItem']['loggedTime']),
      ),
      dateTime: DateTime.parse(map['dateTime']),
      mealType: map['mealType'],
      quantity: map['quantity'],
      unit: map['unit'],
    );
  }
}