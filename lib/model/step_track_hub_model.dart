class BodyMeasurementsModel {
  final String sex; // 'Female' | 'Male'
  final int birthYear;
  final double weightKg;
  final int heightCm;
  final int? customStepLengthCm; // null => Automatic

  const BodyMeasurementsModel({
    this.sex = 'Female',
    this.birthYear = 2000,
    this.weightKg = 60.0,
    this.heightCm = 165,
    this.customStepLengthCm,
  });

  BodyMeasurementsModel copyWith({
    String? sex,
    int? birthYear,
    double? weightKg,
    int? heightCm,
    int? customStepLengthCm,
    bool clearCustomStepLength = false,
  }) {
    return BodyMeasurementsModel(
      sex: sex ?? this.sex,
      birthYear: birthYear ?? this.birthYear,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      customStepLengthCm: clearCustomStepLength
          ? null
          : (customStepLengthCm ?? this.customStepLengthCm),
    );
  }

  Map<String, dynamic> toMap() => {
        'sex': sex,
        'birthYear': birthYear,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'customStepLengthCm': customStepLengthCm,
      };

  factory BodyMeasurementsModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const BodyMeasurementsModel();
    return BodyMeasurementsModel(
      sex: (map['sex'] as String?) ?? 'Female',
      birthYear: (map['birthYear'] as num?)?.toInt() ?? 2000,
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 60.0,
      heightCm: (map['heightCm'] as num?)?.toInt() ?? 165,
      customStepLengthCm: (map['customStepLengthCm'] as num?)?.toInt(),
    );
  }
}

class NotificationSettingsModel {
  final bool stepsGoalAchieved;
  final bool streakNotifications;
  final bool streakUpdatesOnOpen;
  final bool weeklyReport;
  final bool weeklyProgress;
  final bool friendsAndGroups;
  final bool statistics;
  final bool competitions;
  final bool challenges;
  final bool chat;

  const NotificationSettingsModel({
    this.stepsGoalAchieved = true,
    this.streakNotifications = true,
    this.streakUpdatesOnOpen = true,
    this.weeklyReport = true,
    this.weeklyProgress = true,
    this.friendsAndGroups = true,
    this.statistics = true,
    this.competitions = true,
    this.challenges = true,
    this.chat = true,
  });

  NotificationSettingsModel copyWith({
    bool? stepsGoalAchieved,
    bool? streakNotifications,
    bool? streakUpdatesOnOpen,
    bool? weeklyReport,
    bool? weeklyProgress,
    bool? friendsAndGroups,
    bool? statistics,
    bool? competitions,
    bool? challenges,
    bool? chat,
  }) {
    return NotificationSettingsModel(
      stepsGoalAchieved: stepsGoalAchieved ?? this.stepsGoalAchieved,
      streakNotifications: streakNotifications ?? this.streakNotifications,
      streakUpdatesOnOpen: streakUpdatesOnOpen ?? this.streakUpdatesOnOpen,
      weeklyReport: weeklyReport ?? this.weeklyReport,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      friendsAndGroups: friendsAndGroups ?? this.friendsAndGroups,
      statistics: statistics ?? this.statistics,
      competitions: competitions ?? this.competitions,
      challenges: challenges ?? this.challenges,
      chat: chat ?? this.chat,
    );
  }

  Map<String, dynamic> toMap() => {
        'stepsGoalAchieved': stepsGoalAchieved,
        'streakNotifications': streakNotifications,
        'streakUpdatesOnOpen': streakUpdatesOnOpen,
        'weeklyReport': weeklyReport,
        'weeklyProgress': weeklyProgress,
        'friendsAndGroups': friendsAndGroups,
        'statistics': statistics,
        'competitions': competitions,
        'challenges': challenges,
        'chat': chat,
      };

  factory NotificationSettingsModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationSettingsModel();
    return NotificationSettingsModel(
      stepsGoalAchieved: (map['stepsGoalAchieved'] as bool?) ?? true,
      streakNotifications: (map['streakNotifications'] as bool?) ?? true,
      streakUpdatesOnOpen: (map['streakUpdatesOnOpen'] as bool?) ?? true,
      weeklyReport: (map['weeklyReport'] as bool?) ?? true,
      weeklyProgress: (map['weeklyProgress'] as bool?) ?? true,
      friendsAndGroups: (map['friendsAndGroups'] as bool?) ?? true,
      statistics: (map['statistics'] as bool?) ?? true,
      competitions: (map['competitions'] as bool?) ?? true,
      challenges: (map['challenges'] as bool?) ?? true,
      chat: (map['chat'] as bool?) ?? true,
    );
  }
}

class HubPreferencesModel {
  final String themeMode; // 'system' | 'dark' | 'light'
  final int accentColorValue;
  final int widgetStyleIndex; // 0, 1, 2
  final bool isProActive;
  final String selectedBillingPlan; // 'yearly' | 'monthly'
  final bool emailNewsletter;
  final bool leaderboardEnabled;
  final bool showFriendsEnabled;
  final bool googleFitSyncEnabled;
  final bool goalHistoryEnabled;
  final bool crashLogsEnabled;
  final bool usageStatisticsEnabled;
  final bool personalizedAdsEnabled;
  final int unreadBlogCount;
  final BodyMeasurementsModel measurements;
  final NotificationSettingsModel notifications;

  const HubPreferencesModel({
    this.themeMode = 'dark',
    this.accentColorValue = 0xFF4FD0F8,
    this.widgetStyleIndex = 2,
    this.isProActive = false,
    this.selectedBillingPlan = 'yearly',
    this.emailNewsletter = true,
    this.leaderboardEnabled = true,
    this.showFriendsEnabled = true,
    this.googleFitSyncEnabled = false,
    this.goalHistoryEnabled = false,
    this.crashLogsEnabled = true,
    this.usageStatisticsEnabled = true,
    this.personalizedAdsEnabled = false,
    this.unreadBlogCount = 0,
    this.measurements = const BodyMeasurementsModel(),
    this.notifications = const NotificationSettingsModel(),
  });

  HubPreferencesModel copyWith({
    String? themeMode,
    int? accentColorValue,
    int? widgetStyleIndex,
    bool? isProActive,
    String? selectedBillingPlan,
    bool? emailNewsletter,
    bool? leaderboardEnabled,
    bool? showFriendsEnabled,
    bool? googleFitSyncEnabled,
    bool? goalHistoryEnabled,
    bool? crashLogsEnabled,
    bool? usageStatisticsEnabled,
    bool? personalizedAdsEnabled,
    int? unreadBlogCount,
    BodyMeasurementsModel? measurements,
    NotificationSettingsModel? notifications,
  }) {
    return HubPreferencesModel(
      themeMode: themeMode ?? this.themeMode,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      widgetStyleIndex: widgetStyleIndex ?? this.widgetStyleIndex,
      isProActive: isProActive ?? this.isProActive,
      selectedBillingPlan: selectedBillingPlan ?? this.selectedBillingPlan,
      emailNewsletter: emailNewsletter ?? this.emailNewsletter,
      leaderboardEnabled: leaderboardEnabled ?? this.leaderboardEnabled,
      showFriendsEnabled: showFriendsEnabled ?? this.showFriendsEnabled,
      googleFitSyncEnabled: googleFitSyncEnabled ?? this.googleFitSyncEnabled,
      goalHistoryEnabled: goalHistoryEnabled ?? this.goalHistoryEnabled,
      crashLogsEnabled: crashLogsEnabled ?? this.crashLogsEnabled,
      usageStatisticsEnabled:
          usageStatisticsEnabled ?? this.usageStatisticsEnabled,
      personalizedAdsEnabled:
          personalizedAdsEnabled ?? this.personalizedAdsEnabled,
      unreadBlogCount: unreadBlogCount ?? this.unreadBlogCount,
      measurements: measurements ?? this.measurements,
      notifications: notifications ?? this.notifications,
    );
  }

  Map<String, dynamic> toMap() => {
        'themeMode': themeMode,
        'accentColorValue': accentColorValue,
        'widgetStyleIndex': widgetStyleIndex,
        'isProActive': isProActive,
        'selectedBillingPlan': selectedBillingPlan,
        'emailNewsletter': emailNewsletter,
        'leaderboardEnabled': leaderboardEnabled,
        'showFriendsEnabled': showFriendsEnabled,
        'googleFitSyncEnabled': googleFitSyncEnabled,
        'goalHistoryEnabled': goalHistoryEnabled,
        'crashLogsEnabled': crashLogsEnabled,
        'usageStatisticsEnabled': usageStatisticsEnabled,
        'personalizedAdsEnabled': personalizedAdsEnabled,
        'unreadBlogCount': unreadBlogCount,
        'measurements': measurements.toMap(),
        'notifications': notifications.toMap(),
      };

  factory HubPreferencesModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const HubPreferencesModel();
    return HubPreferencesModel(
      themeMode: (map['themeMode'] as String?) ?? 'dark',
      accentColorValue: (map['accentColorValue'] as int?) ?? 0xFF4FD0F8,
      widgetStyleIndex: (map['widgetStyleIndex'] as int?) ?? 2,
      isProActive: (map['isProActive'] as bool?) ?? false,
      selectedBillingPlan: (map['selectedBillingPlan'] as String?) ?? 'yearly',
      emailNewsletter: (map['emailNewsletter'] as bool?) ?? true,
      leaderboardEnabled: (map['leaderboardEnabled'] as bool?) ?? true,
      showFriendsEnabled: (map['showFriendsEnabled'] as bool?) ?? true,
      googleFitSyncEnabled: (map['googleFitSyncEnabled'] as bool?) ?? false,
      goalHistoryEnabled: (map['goalHistoryEnabled'] as bool?) ?? false,
      crashLogsEnabled: (map['crashLogsEnabled'] as bool?) ?? true,
      usageStatisticsEnabled: (map['usageStatisticsEnabled'] as bool?) ?? true,
      personalizedAdsEnabled: (map['personalizedAdsEnabled'] as bool?) ?? false,
      unreadBlogCount: (map['unreadBlogCount'] as int?) ?? 0,
      measurements: BodyMeasurementsModel.fromMap(
        map['measurements'] is Map
            ? Map<String, dynamic>.from(map['measurements'] as Map)
            : null,
      ),
      notifications: NotificationSettingsModel.fromMap(
        map['notifications'] is Map
            ? Map<String, dynamic>.from(map['notifications'] as Map)
            : null,
      ),
    );
  }
}