import 'package:cloud_firestore/cloud_firestore.dart';

class DailyStepRecord {
  final String dateKey; // YYYY-MM-DD
  final int steps;
  final double distanceKm;
  final int calories;
  final int activeMinutes;

  DailyStepRecord({
    required this.dateKey,
    required this.steps,
    required this.distanceKm,
    required this.calories,
    required this.activeMinutes,
  });

  factory DailyStepRecord.fromMap(String dateKey, Map<String, dynamic> data) {
    final int steps = (data['steps'] ?? 0) is int
        ? data['steps'] ?? 0
        : ((data['steps'] ?? 0) as num).toInt();
    final double distanceKm = (data['distanceKm'] ?? (steps * 0.00078)).toDouble();
    final int calories = (data['calories'] ?? (steps * 0.04)).toInt();
    final int activeMinutes = (data['activeMinutes'] ?? (steps ~/ 100)).toInt();

    return DailyStepRecord(
      dateKey: dateKey,
      steps: steps,
      distanceKm: double.parse(distanceKm.toStringAsFixed(2)),
      calories: calories,
      activeMinutes: activeMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateKey': dateKey,
      'steps': steps,
      'distanceKm': distanceKm,
      'calories': calories,
      'activeMinutes': activeMinutes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class UserStepProfile {
  final String uid;
  final String name;
  final String email;
  final int dailyGoal;
  final int totalSteps;
  final int todaySteps;
  final List<DailyStepRecord> history;

  UserStepProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.dailyGoal = 10000,
    this.totalSteps = 0,
    this.todaySteps = 0,
    this.history = const [],
  });

  double get goalProgress =>
      dailyGoal > 0 ? (todaySteps / dailyGoal).clamp(0.0, 1.0) : 0.0;

  int get remainingSteps =>
      (dailyGoal - todaySteps) > 0 ? (dailyGoal - todaySteps) : 0;

  double get todayDistanceKm =>
      double.parse((todaySteps * 0.00078).toStringAsFixed(2));

  int get todayCalories => (todaySteps * 0.04).round();

  int get todayActiveMinutes => (todaySteps / 100).round();

  factory UserStepProfile.fromFirestore({
    required String uid,
    required String fallbackEmail,
    Map<String, dynamic>? userDoc,
    List<DailyStepRecord> history = const [],
  }) {
    final data = userDoc ?? {};
    final String resolvedName = (data['name'] ??
            data['displayName'] ??
            (fallbackEmail.isNotEmpty ? fallbackEmail.split('@').first : 'StepTrack User'))
        .toString();

    final int goal = ((data['dailyGoal'] ?? data['goal'] ?? 10000) as num).toInt();
    final int docSteps = ((data['steps'] ?? data['todaySteps'] ?? 0) as num).toInt();
    final int docTotal = ((data['totalSteps'] ?? docSteps) as num).toInt();

    return UserStepProfile(
      uid: uid,
      name: resolvedName,
      email: (data['email'] ?? fallbackEmail).toString(),
      dailyGoal: goal > 0 ? goal : 10000,
      todaySteps: docSteps,
      totalSteps: docTotal > docSteps ? docTotal : docSteps,
      history: history,
    );
  }
}
