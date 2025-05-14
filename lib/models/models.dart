// User Model
class User {
  final String id;
  final String name;
  final String? email;
  final String? photoUrl;
  final int coins;
  final int streakDays;
  final int level;
  final double levelProgress;
  final List<Badge> badges;
  final List<Achievement> achievements;
  final List<OrderHistory> orderHistory;

  User({
    required this.id,
    required this.name,
    this.email,
    this.photoUrl,
    this.coins = 0,
    this.streakDays = 0,
    this.level = 1,
    this.levelProgress = 0.0,
    this.badges = const [],
    this.achievements = const [],
    this.orderHistory = const [],
  });
}

// Badge Model
class Badge {
  final String id;
  final String title;
  final String iconName;
  final String date;
  final bool isLocked;

  Badge({
    required this.id,
    required this.title,
    required this.iconName,
    required this.date,
    this.isLocked = false,
  });
}

// Achievement Model
class Achievement {
  final String id;
  final String title;
  final String description;
  final String date;
  final int reward;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.reward,
  });
}

// Order History Model
class OrderHistory {
  final String id;
  final String restaurant;
  final List<String> items;
  final String date;
  final double amount;

  OrderHistory({
    required this.id,
    required this.restaurant,
    required this.items,
    required this.date,
    required this.amount,
  });
}

// Health Metrics Model
class HealthMetrics {
  final int activityScore;
  final int sleepScore;
  final int nutritionScore;
  final int stressScore;
  final int overallScore;
  final ActivityMetrics activity;
  final SleepMetrics sleep;
  final NutritionMetrics nutrition;
  final StressMetrics stress;

  HealthMetrics({
    required this.activityScore,
    required this.sleepScore,
    required this.nutritionScore,
    required this.stressScore,
    required this.overallScore,
    required this.activity,
    required this.sleep,
    required this.nutrition,
    required this.stress,
  });
}

class ActivityMetrics {
  final int steps;
  final int targetSteps;
  final int activeMinutes;
  final int targetActiveMinutes;
  final int caloriesBurned;
  final int targetCaloriesBurned;
  final List<int> weeklyActivity;

  ActivityMetrics({
    required this.steps,
    required this.targetSteps,
    required this.activeMinutes,
    required this.targetActiveMinutes,
    required this.caloriesBurned,
    required this.targetCaloriesBurned,
    required this.weeklyActivity,
  });
}

class SleepMetrics {
  final int duration;
  final int targetDuration;
  final int deepSleep;
  final int targetDeepSleep;
  final int sleepConsistency;
  final int targetSleepConsistency;
  final Map<String, int> sleepStages;

  SleepMetrics({
    required this.duration,
    required this.targetDuration,
    required this.deepSleep,
    required this.targetDeepSleep,
    required this.sleepConsistency,
    required this.targetSleepConsistency,
    required this.sleepStages,
  });
}

class NutritionMetrics {
  final int protein;
  final int targetProtein;
  final int fiber;
  final int targetFiber;
  final int hydration;
  final int targetHydration;
  final Map<String, int> macronutrients;

  NutritionMetrics({
    required this.protein,
    required this.targetProtein,
    required this.fiber,
    required this.targetFiber,
    required this.hydration,
    required this.targetHydration,
    required this.macronutrients,
  });
}

class StressMetrics {
  final int heartRateVariability;
  final int targetHeartRateVariability;
  final int restingHeartRate;
  final int targetRestingHeartRate;
  final int breathingRate;
  final int targetBreathingRate;
  final List<int> weeklyStressLevels;

  StressMetrics({
    required this.heartRateVariability,
    required this.targetHeartRateVariability,
    required this.restingHeartRate,
    required this.targetRestingHeartRate,
    required this.breathingRate,
    required this.targetBreathingRate,
    required this.weeklyStressLevels,
  });
}

// Kitchen Model
class Kitchen {
  final String id;
  final String name;
  final double rating;
  final String time;
  final List<String> tags;
  final String? imageUrl;

  Kitchen({
    required this.id,
    required this.name,
    required this.rating,
    required this.time,
    required this.tags,
    this.imageUrl,
  });
}

// MenuItem Model
class MenuItem {
  final int id;
  final String name;
  final String description;
  final double price;
  final String calories;
  final String? imageUrl;
  final String category;
  final bool isFavorite;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.calories,
    this.imageUrl,
    required this.category,
    this.isFavorite = false,
  });

  MenuItem copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? calories,
    String? imageUrl,
    String? category,
    bool? isFavorite,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      calories: calories ?? this.calories,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

// CartItem Model
class CartItem {
  final int id;
  final String name;
  final double price;
  final int quantity;
  final String restaurant;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.restaurant,
  });

  CartItem copyWith({
    int? id,
    String? name,
    double? price,
    int? quantity,
    String? restaurant,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      restaurant: restaurant ?? this.restaurant,
    );
  }

  double get totalPrice => price * quantity;
}

// Diary Event Model
enum EventType { food, water, activity, calendar }

class DiaryEvent {
  final int id;
  final String title;
  final EventType type;
  final String time;
  final int duration;
  final Map<String, dynamic> details;

  DiaryEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.time,
    required this.duration,
    required this.details,
  });
}

// Wellness Program Model
class WellnessProgram {
  final List<WellnessTask> tasks;
  final List<WellnessChallenge> challenges;
  final List<WellnessReward> rewards;
  final int coins;
  final int streakDays;
  final int weeksDone;
  final int totalWeeks;

  WellnessProgram({
    required this.tasks,
    required this.challenges,
    required this.rewards,
    required this.coins,
    required this.streakDays,
    required this.weeksDone,
    required this.totalWeeks,
  });
}

class WellnessTask {
  final String id;
  final String title;
  final String icon;
  final int points;
  final bool completed;
  final int? progress;

  WellnessTask({
    required this.id,
    required this.title,
    required this.icon,
    required this.points,
    required this.completed,
    this.progress,
  });
}

class WellnessChallenge {
  final String id;
  final String title;
  final String description;
  final int progress;
  final String days;
  final int reward;

  WellnessChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.days,
    required this.reward,
  });
}

class WellnessReward {
  final String id;
  final String title;
  final String description;
  final int cost;
  final bool canAfford;
  final bool isBadge;

  WellnessReward({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.canAfford,
    this.isBadge = false,
  });
}

// Add these extension getters to the WellnessProgram class in models.dart
extension WellnessProgramExtension on WellnessProgram {
  int get tasksCompleted {
    return tasks.where((task) => task.completed).length;
  }

  int get challengesCompleted {
    // Assume a challenge is completed when progress is 100
    return challenges.where((challenge) => challenge.progress >= 100).length;
  }

  int get coinsEarned {
    // This is an estimate since we don't track earned coins
    return coins +
        tasks
            .where((task) => task.completed)
            .fold(0, (sum, task) => sum + task.points);
  }

  int get rewardsRedeemed {
    // Since we don't track redeemed rewards, return a fixed number
    return 2; // Placeholder value
  }
}
