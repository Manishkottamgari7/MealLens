import '../models/models.dart';

class SampleData {
  // Sample User
  static final User sampleUser = User(
    id: '1',
    name: 'Emma Mitchell',
    email: 'emma@example.com',
    photoUrl: null,
    coins: 450,
    streakDays: 7,
    level: 8,
    levelProgress: 0.75,
    badges: [
      Badge(
        id: '1',
        title: '7-Day Streak',
        iconName: 'fire',
        date: 'May 15, 2023',
      ),
      Badge(
        id: '2',
        title: 'Fitness Guru',
        iconName: 'workout',
        date: 'May 10, 2023',
      ),
      Badge(
        id: '3',
        title: 'Wellness Warrior',
        iconName: 'heart',
        date: 'Apr 28, 2023',
      ),
      Badge(
        id: '4',
        title: 'Sleep Master',
        iconName: 'sleep',
        date: 'Apr 15, 2023',
      ),
      Badge(
        id: '5',
        title: 'Energy Champion',
        iconName: 'activity',
        date: 'Mar 30, 2023',
      ),
      Badge(
        id: '6',
        title: 'Early Bird',
        iconName: 'time',
        date: 'Mar 22, 2023',
      ),
    ],
    achievements: [
      Achievement(
        id: '1',
        title: '10,000 Steps',
        description: 'Reached 10,000 steps in a single day',
        date: 'May 14, 2023',
        reward: 50,
      ),
      Achievement(
        id: '2',
        title: 'Protein Goal',
        description: 'Met your protein goal for 5 consecutive days',
        date: 'May 12, 2023',
        reward: 100,
      ),
      Achievement(
        id: '3',
        title: 'Early Workout',
        description: 'Completed a workout before 9 AM',
        date: 'May 10, 2023',
        reward: 30,
      ),
      Achievement(
        id: '4',
        title: 'Hydration Master',
        description: 'Drank 2.5L of water for 3 consecutive days',
        date: 'May 8, 2023',
        reward: 75,
      ),
    ],
    orderHistory: [
      OrderHistory(
        id: '1',
        restaurant: 'Green Plate Kitchen',
        items: ['Protein Bowl', 'Green Smoothie'],
        date: 'May 14, 2023',
        amount: 24.50,
      ),
      OrderHistory(
        id: '2',
        restaurant: 'Protein Power House',
        items: ['Grilled Chicken Salad', 'Protein Shake'],
        date: 'May 10, 2023',
        amount: 18.75,
      ),
      OrderHistory(
        id: '3',
        restaurant: 'Balanced Bites',
        items: ['Quinoa Bowl', 'Kombucha'],
        date: 'May 5, 2023',
        amount: 22.00,
      ),
    ],
  );

  // Sample Health Metrics
  static final HealthMetrics sampleHealthMetrics = HealthMetrics(
    activityScore: 78,
    sleepScore: 85,
    nutritionScore: 62,
    stressScore: 45,
    overallScore: 76,
    activity: ActivityMetrics(
      steps: 8432,
      targetSteps: 10000,
      activeMinutes: 45,
      targetActiveMinutes: 60,
      caloriesBurned: 320,
      targetCaloriesBurned: 400,
      weeklyActivity: [60, 45, 80, 95, 70, 50, 65],
    ),
    sleep: SleepMetrics(
      duration: 435, // in minutes (7h15m)
      targetDuration: 480, // 8 hours
      deepSleep: 105, // 1h45m
      targetDeepSleep: 120, // 2 hours
      sleepConsistency: 80,
      targetSleepConsistency: 100,
      sleepStages: {
        'light': 210, // 3h30m
        'rem': 120, // 2h
        'deep': 105, // 1h45m
      },
    ),
    nutrition: NutritionMetrics(
      protein: 65,
      targetProtein: 120,
      fiber: 18,
      targetFiber: 25,
      hydration: 1200, // in ml
      targetHydration: 2500, // in ml
      macronutrients: {'protein': 30, 'carbs': 45, 'fat': 25},
    ),
    stress: StressMetrics(
      heartRateVariability: 40,
      targetHeartRateVariability: 100,
      restingHeartRate: 72,
      targetRestingHeartRate: 60,
      breathingRate: 16,
      targetBreathingRate: 12,
      weeklyStressLevels: [80, 70, 85, 40, 60, 30, 50],
    ),
  );

  // Sample Wellness Program
  static final WellnessProgram sampleWellnessProgram = WellnessProgram(
    coins: 450,
    streakDays: 7,
    weeksDone: 2,
    totalWeeks: 8,
    tasks: [
      WellnessTask(
        id: '1',
        title: 'Log all meals',
        icon: 'nutrition',
        points: 20,
        completed: true,
      ),
      WellnessTask(
        id: '2',
        title: '30 min exercise',
        icon: 'workout',
        points: 30,
        completed: true,
      ),
      WellnessTask(
        id: '3',
        title: 'Drink 2.5L water',
        icon: 'water',
        points: 15,
        completed: false,
        progress: 48,
      ),
    ],
    challenges: [
      WellnessChallenge(
        id: '1',
        title: 'Protein Power',
        description: 'Consume at least 100g of protein daily for 5 days',
        progress: 60,
        days: '3/5',
        reward: 100,
      ),
      WellnessChallenge(
        id: '2',
        title: 'Morning Workout',
        description: 'Complete a workout before 9 AM three times this week',
        progress: 33,
        days: '1/3',
        reward: 75,
      ),
      WellnessChallenge(
        id: '3',
        title: 'Mindful Eating',
        description: 'No screen time during meals for 7 days',
        progress: 42,
        days: '3/7',
        reward: 120,
      ),
    ],
    rewards: [
      WellnessReward(
        id: '1',
        title: '15% Off Healthy Bowl',
        description: 'Valid at Green Plate Kitchen',
        cost: 300,
        canAfford: true,
      ),
      WellnessReward(
        id: '2',
        title: 'Free Yoga Class',
        description: 'One-time pass to Zen Yoga Studio',
        cost: 500,
        canAfford: false,
      ),
      WellnessReward(
        id: '3',
        title: 'Nutrition Consultation',
        description: '30-min session with certified nutritionist',
        cost: 750,
        canAfford: false,
      ),
      WellnessReward(
        id: '4',
        title: 'Wellness Badge: Nutrition Master',
        description: 'Unlock exclusive profile badge',
        cost: 400,
        canAfford: true,
        isBadge: true,
      ),
    ],
  );

  // Sample Diary Events
  static final List<DiaryEvent> sampleDiaryEvents = [
    DiaryEvent(
      id: 1,
      title: 'Breakfast',
      type: EventType.food,
      time: '08:30 AM',
      duration: 30,
      details: {
        'calories': 420,
        'protein': 22,
        'carbs': 45,
        'fat': 18,
        'items': [
          'Greek Yogurt with Berries',
          'Whole Grain Toast',
          'Almond Butter',
        ],
      },
    ),
    DiaryEvent(
      id: 2,
      title: 'Morning Meeting',
      type: EventType.calendar,
      time: '10:00 AM',
      duration: 60,
      details: {
        'location': 'Conference Room A',
        'participants': ['John', 'Sarah', 'Mike'],
      },
    ),
    DiaryEvent(
      id: 3,
      title: 'Hydration',
      type: EventType.water,
      time: '10:30 AM',
      duration: 5,
      details: {'amount': 250},
    ),
    DiaryEvent(
      id: 4,
      title: 'Lunch',
      type: EventType.food,
      time: '12:30 PM',
      duration: 45,
      details: {
        'calories': 530,
        'protein': 35,
        'carbs': 60,
        'fat': 15,
        'items': ['Quinoa Salad', 'Grilled Chicken'],
      },
    ),
    DiaryEvent(
      id: 5,
      title: 'Hydration',
      type: EventType.water,
      time: '01:30 PM',
      duration: 5,
      details: {'amount': 250},
    ),
    DiaryEvent(
      id: 6,
      title: 'Workout',
      type: EventType.activity,
      time: '05:30 PM',
      duration: 45,
      details: {'type': 'Weight Training', 'calories': 320},
    ),
    DiaryEvent(
      id: 7,
      title: 'Hydration',
      type: EventType.water,
      time: '06:30 PM',
      duration: 5,
      details: {'amount': 250},
    ),
    DiaryEvent(
      id: 8,
      title: 'Dinner',
      type: EventType.food,
      time: '07:30 PM',
      duration: 60,
      details: {
        'calories': 650,
        'protein': 40,
        'carbs': 70,
        'fat': 20,
        'items': ['Salmon', 'Roasted Vegetables', 'Quinoa'],
      },
    ),
  ];

  // Sample Kitchens
  static final List<Kitchen> sampleKitchens = [
    Kitchen(
      id: '1',
      name: 'Green Plate Kitchen',
      rating: 4.8,
      time: '15-25 min',
      tags: ['Healthy', 'Organic'],
      imageUrl: 'assets/images/restaurant.png',
    ),
    Kitchen(
      id: '2',
      name: 'Protein Power House',
      rating: 4.6,
      time: '20-30 min',
      tags: ['High Protein', 'Fitness'],
      imageUrl: 'assets/images/restaurant.png',
    ),
    Kitchen(
      id: '3',
      name: 'Balanced Bites',
      rating: 4.7,
      time: '10-20 min',
      tags: ['Balanced', 'Gluten-Free'],
      imageUrl: 'assets/images/restaurant.png',
    ),
  ];

  // Sample Menu Items
  static final Map<String, List<MenuItem>> sampleMenuItems = {
    'Green Plate Kitchen': [
      MenuItem(
        id: 1,
        name: 'Protein Power Bowl',
        description: 'Quinoa, grilled chicken, avocado, and vegetables',
        price: 14.99,
        calories: '520 cal',
        category: 'bowls',
        imageUrl: 'assets/images/restaurant.png',
      ),
      MenuItem(
        id: 2,
        name: 'Green Goddess Salad',
        description: 'Mixed greens, cucumber, avocado with herb dressing',
        price: 12.99,
        calories: '320 cal',
        category: 'salads',
        imageUrl: 'assets/images/restaurant.png',
      ),
      MenuItem(
        id: 3,
        name: 'Berry Protein Smoothie',
        description: 'Mixed berries, protein powder, almond milk',
        price: 8.99,
        calories: '280 cal',
        category: 'drinks',
        imageUrl: 'assets/images/restaurant.png',
      ),
      MenuItem(
        id: 4,
        name: 'Mediterranean Bowl',
        description: 'Falafel, hummus, tabbouleh, and tzatziki',
        price: 13.99,
        calories: '480 cal',
        category: 'bowls',
        imageUrl: 'assets/images/restaurant.png',
      ),
      MenuItem(
        id: 5,
        name: 'Avocado Toast',
        description: 'Whole grain toast, avocado, microgreens, and seeds',
        price: 9.99,
        calories: '350 cal',
        category: 'bowls',
        imageUrl: 'assets/images/restaurant.png',
      ),
      MenuItem(
        id: 6,
        name: 'Teriyaki Tofu Bowl',
        description: 'Brown rice, tofu, broccoli, carrots, teriyaki sauce',
        price: 13.99,
        calories: '450 cal',
        category: 'bowls',
        imageUrl: 'assets/images/restaurant.png',
      ),
      MenuItem(
        id: 7,
        name: 'Southwest Bowl',
        description: 'Black beans, corn, avocado, salsa, lime-cilantro rice',
        price: 14.99,
        calories: '510 cal',
        category: 'bowls',
        imageUrl: 'assets/images/restaurant.png',
      ),
      MenuItem(
        id: 8,
        name: 'Poke Bowl',
        description: 'Sushi rice, salmon, cucumber, avocado, seaweed',
        price: 16.99,
        calories: '490 cal',
        category: 'bowls',
        imageUrl: 'assets/images/restaurant.png',
      ),
      MenuItem(
        id: 9,
        name: 'Cobb Salad',
        description: 'Lettuce, chicken, bacon, egg, avocado, blue cheese',
        price: 14.99,
        calories: '550 cal',
        category: 'salads',
        imageUrl: 'assets/images/restaurant.png',
      ),
      MenuItem(
        id: 10,
        name: 'Quinoa Tabbouleh',
        description: 'Quinoa, parsley, tomato, cucumber, lemon dressing',
        price: 11.99,
        calories: '380 cal',
        category: 'salads',
        imageUrl: 'assets/images/restaurant.png',
      ),
      MenuItem(
        id: 11,
        name: 'Kale Caesar',
        description: 'Kale, parmesan, croutons, caesar dressing',
        price: 12.99,
        calories: '420 cal',
        category: 'salads',
        imageUrl: 'assets/images/restaurant.png',
      ),
      MenuItem(
        id: 12,
        name: 'Green Detox Juice',
        description: 'Kale, cucumber, apple, celery, ginger',
        price: 7.99,
        calories: '120 cal',
        category: 'drinks',
        imageUrl: 'assets/images/restaurant.png',
      ),
      MenuItem(
        id: 13,
        name: 'Turmeric Latte',
        description: 'Almond milk, turmeric, cinnamon, honey',
        price: 5.99,
        calories: '180 cal',
        category: 'drinks',
        imageUrl: 'assets/images/restaurant.png',
      ),
      MenuItem(
        id: 14,
        name: 'Kombucha',
        description: 'Fermented tea with probiotics',
        price: 6.99,
        calories: '60 cal',
        category: 'drinks',
        imageUrl: 'assets/images/restaurant.png',
      ),
    ],
  };
}
