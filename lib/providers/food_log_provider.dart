import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/food_item.dart';
import '../models/food_log_entry.dart';

class FoodLogProvider extends ChangeNotifier {
  List<FoodLogEntry> _foodLogs = [];
  bool _isLoading = false;

  // Getters
  List<FoodLogEntry> get foodLogs => _foodLogs;
  bool get isLoading => _isLoading;

  // Load logs from SharedPreferences
  Future<void> loadFoodLogs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? logsJson = prefs.getString('food_logs');

      if (logsJson != null) {
        final List<dynamic> logsList = jsonDecode(logsJson);
        // This is a simplified approach. In a real app, you'd need proper JSON serialization
        // _foodLogs = logsList.map((log) => FoodLogEntry.fromMap(log)).toList();
      }
    } catch (e) {
      debugPrint('Error loading food logs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save logs to SharedPreferences
  Future<void> _saveFoodLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert logs to JSON (simplified)
      final List<Map<String, dynamic>> logsMap = _foodLogs.map((log) => log.toMap()).toList();
      final String logsJson = jsonEncode(logsMap);

      await prefs.setString('food_logs', logsJson);
    } catch (e) {
      debugPrint('Error saving food logs: $e');
    }
  }

  // Add a new food log entry
  Future<void> addFoodLog(FoodItem foodItem, String mealType, double quantity, String unit) async {
    final logEntry = FoodLogEntry(
      id: const Uuid().v4(),
      foodItem: foodItem,
      dateTime: DateTime.now(),
      mealType: mealType,
      quantity: quantity,
      unit: unit,
    );

    _foodLogs.add(logEntry);
    notifyListeners();

    await _saveFoodLogs();
  }

  // Delete a food log entry
  Future<void> deleteFoodLog(String id) async {
    _foodLogs.removeWhere((log) => log.id == id);
    notifyListeners();

    await _saveFoodLogs();
  }

  // Get logs for a specific date
  List<FoodLogEntry> getLogsForDate(DateTime date) {
    return _foodLogs.where((log) =>
    log.dateTime.year == date.year &&
        log.dateTime.month == date.month &&
        log.dateTime.day == date.day
    ).toList();
  }

  // Get logs for a specific meal type
  List<FoodLogEntry> getLogsForMealType(String mealType) {
    return _foodLogs.where((log) => log.mealType == mealType).toList();
  }

  // Calculate total nutrients for a given day
  Map<String, double> getDailyNutrients(DateTime date) {
    final logsForDay = getLogsForDate(date);

    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var log in logsForDay) {
      totalCalories += log.calories;
      totalProtein += log.protein;
      totalCarbs += log.carbs;
      totalFat += log.fat;
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }
}