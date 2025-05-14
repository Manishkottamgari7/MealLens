import 'package:flutter/foundation.dart';

import '../data/sample_data.dart';
import '../models/models.dart';

class UserProvider with ChangeNotifier {
  User _user = SampleData.sampleUser;
  HealthMetrics _healthMetrics = SampleData.sampleHealthMetrics;
  WellnessProgram _wellnessProgram = SampleData.sampleWellnessProgram;
  List<DiaryEvent> _diaryEvents = SampleData.sampleDiaryEvents;

  User get user => _user;
  HealthMetrics get healthMetrics => _healthMetrics;
  WellnessProgram get wellnessProgram => _wellnessProgram;
  List<DiaryEvent> get diaryEvents => _diaryEvents;

  void addCoins(int amount) {
    _user = User(
      id: _user.id,
      name: _user.name,
      email: _user.email,
      photoUrl: _user.photoUrl,
      coins: _user.coins + amount,
      streakDays: _user.streakDays,
      level: _user.level,
      levelProgress: _user.levelProgress,
      badges: _user.badges,
      achievements: _user.achievements,
      orderHistory: _user.orderHistory,
    );
    notifyListeners();
  }

  void updateStreakDays(int days) {
    _user = User(
      id: _user.id,
      name: _user.name,
      email: _user.email,
      photoUrl: _user.photoUrl,
      coins: _user.coins,
      streakDays: days,
      level: _user.level,
      levelProgress: _user.levelProgress,
      badges: _user.badges,
      achievements: _user.achievements,
      orderHistory: _user.orderHistory,
    );

    _wellnessProgram = WellnessProgram(
      tasks: _wellnessProgram.tasks,
      challenges: _wellnessProgram.challenges,
      rewards: _wellnessProgram.rewards,
      coins: _user.coins,
      streakDays: days,
      weeksDone: _wellnessProgram.weeksDone,
      totalWeeks: _wellnessProgram.totalWeeks,
    );

    notifyListeners();
  }

  void completeTask(String taskId) {
    final tasks =
        _wellnessProgram.tasks.map((task) {
          if (task.id == taskId) {
            return WellnessTask(
              id: task.id,
              title: task.title,
              icon: task.icon,
              points: task.points,
              completed: true,
              progress: 100,
            );
          }
          return task;
        }).toList();

    _wellnessProgram = WellnessProgram(
      tasks: tasks,
      challenges: _wellnessProgram.challenges,
      rewards: _wellnessProgram.rewards,
      coins: _wellnessProgram.coins,
      streakDays: _wellnessProgram.streakDays,
      weeksDone: _wellnessProgram.weeksDone,
      totalWeeks: _wellnessProgram.totalWeeks,
    );

    addCoins(tasks.firstWhere((task) => task.id == taskId).points);
    notifyListeners();
  }

  // Add this method to UserProvider class
  void unlockMysteryBox() {
    // Check if user has enough coins
    if (_user.coins >= 200) {
      // Deduct coins
      _user = User(
        id: _user.id,
        name: _user.name,
        email: _user.email,
        photoUrl: _user.photoUrl,
        coins: _user.coins - 200,
        streakDays: _user.streakDays,
        level: _user.level,
        levelProgress: _user.levelProgress,
        badges: _user.badges,
        achievements: _user.achievements,
        orderHistory: _user.orderHistory,
      );

      // Update wellness program
      _wellnessProgram = WellnessProgram(
        tasks: _wellnessProgram.tasks,
        challenges: _wellnessProgram.challenges,
        rewards: _wellnessProgram.rewards,
        coins: _user.coins,
        streakDays: _wellnessProgram.streakDays,
        weeksDone: _wellnessProgram.weeksDone,
        totalWeeks: _wellnessProgram.totalWeeks,
      );

      notifyListeners();
    }
  }

  void redeemReward(String rewardId) {
    final reward = _wellnessProgram.rewards.firstWhere((r) => r.id == rewardId);

    if (reward.canAfford) {
      _user = User(
        id: _user.id,
        name: _user.name,
        email: _user.email,
        photoUrl: _user.photoUrl,
        coins: _user.coins - reward.cost,
        streakDays: _user.streakDays,
        level: _user.level,
        levelProgress: _user.levelProgress,
        badges:
            reward.isBadge
                ? [
                  ..._user.badges,
                  Badge(
                    id: 'badge_${_user.badges.length + 1}',
                    title: reward.title,
                    iconName: reward.title.toLowerCase().replaceAll(' ', '_'),
                    date: DateTime.now().toString().substring(0, 10),
                    isLocked: false,
                  ),
                ]
                : _user.badges,
        achievements: _user.achievements,
        orderHistory: _user.orderHistory,
      );

      _wellnessProgram = WellnessProgram(
        tasks: _wellnessProgram.tasks,
        challenges: _wellnessProgram.challenges,
        rewards:
            _wellnessProgram.rewards
                .map(
                  (r) =>
                      r.id == rewardId
                          ? WellnessReward(
                            id: r.id,
                            title: r.title,
                            description: r.description,
                            cost: r.cost,
                            canAfford: _user.coins - reward.cost >= r.cost,
                            isBadge: r.isBadge,
                          )
                          : WellnessReward(
                            id: r.id,
                            title: r.title,
                            description: r.description,
                            cost: r.cost,
                            canAfford: _user.coins - reward.cost >= r.cost,
                            isBadge: r.isBadge,
                          ),
                )
                .toList(),
        coins: _user.coins,
        streakDays: _wellnessProgram.streakDays,
        weeksDone: _wellnessProgram.weeksDone,
        totalWeeks: _wellnessProgram.totalWeeks,
      );

      notifyListeners();
    }
  }

  void addDiaryEvent(DiaryEvent event) {
    _diaryEvents = [..._diaryEvents, event];
    notifyListeners();
  }

  void removeDiaryEvent(int eventId) {
    _diaryEvents = _diaryEvents.where((event) => event.id != eventId).toList();
    notifyListeners();
  }

  void addOrderToHistory(OrderHistory order) {
    _user = User(
      id: _user.id,
      name: _user.name,
      email: _user.email,
      photoUrl: _user.photoUrl,
      coins: _user.coins,
      streakDays: _user.streakDays,
      level: _user.level,
      levelProgress: _user.levelProgress,
      badges: _user.badges,
      achievements: _user.achievements,
      orderHistory: [order, ..._user.orderHistory],
    );
    notifyListeners();
  }
}
