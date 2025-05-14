class DailySummary {
  final DateTime date;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalWater;

  // Default goals
  final int calorieGoal;
  final double proteinGoal;
  final double carbsGoal;
  final double fatGoal;
  final double waterGoal;

  DailySummary({
    required this.date,
    this.totalCalories = 0,
    this.totalProtein = 0.0,
    this.totalCarbs = 0.0,
    this.totalFat = 0.0,
    this.totalWater = 0.0,
    this.calorieGoal = 2000,
    this.proteinGoal = 100.0,
    this.carbsGoal = 250.0,
    this.fatGoal = 70.0,
    this.waterGoal = 2.5,
  });

  // Get progress percentages
  double get calorieProgress => totalCalories / calorieGoal;
  double get proteinProgress => totalProtein / proteinGoal;
  double get carbsProgress => totalCarbs / carbsGoal;
  double get fatProgress => totalFat / fatGoal;
  double get waterProgress => totalWater / waterGoal;

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'totalWater': totalWater,
      'calorieGoal': calorieGoal,
      'proteinGoal': proteinGoal,
      'carbsGoal': carbsGoal,
      'fatGoal': fatGoal,
      'waterGoal': waterGoal,
    };
  }

  // Create from map
  factory DailySummary.fromMap(Map<String, dynamic> map) {
    return DailySummary(
      date: DateTime.parse(map['date']),
      totalCalories: map['totalCalories'] ?? 0,
      totalProtein: map['totalProtein'] ?? 0.0,
      totalCarbs: map['totalCarbs'] ?? 0.0,
      totalFat: map['totalFat'] ?? 0.0,
      totalWater: map['totalWater'] ?? 0.0,
      calorieGoal: map['calorieGoal'] ?? 2000,
      proteinGoal: map['proteinGoal'] ?? 100.0,
      carbsGoal: map['carbsGoal'] ?? 250.0,
      fatGoal: map['fatGoal'] ?? 70.0,
      waterGoal: map['waterGoal'] ?? 2.5,
    );
  }
}
