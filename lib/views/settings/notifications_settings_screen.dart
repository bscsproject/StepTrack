import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/controller/step_track_hub_controller.dart';
import 'package:step_track/themes/step_track_theme.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<StepTrackHubController>();

    return Obx(() {
      final p = ctrl.prefs.value;
      final n = p.notifications;
      final pal = StepTrackPalette.resolve(
        context,
        themeMode: p.themeMode,
        accent: Color(p.accentColorValue),
      );

      return Scaffold(
        backgroundColor: pal.screenBg,
        appBar: AppBar(
          backgroundColor: pal.screenBg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: pal.textPrimary),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Notifications',
            style: TextStyle(
              color: pal.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _GroupLabel('Goal achieved', pal: pal),
            SwitchListTile(
              value: n.stepsGoalAchieved,
              activeThumbColor: pal.accent,
              title: Text('Steps', style: TextStyle(color: pal.textPrimary)),
              onChanged: (v) =>
                  ctrl.updateNotifications(n.copyWith(stepsGoalAchieved: v)),
            ),
            _GroupLabel('Streaks', pal: pal),
            SwitchListTile(
              value: n.streakNotifications,
              activeThumbColor: pal.accent,
              title: Text(
                'Streak Notifications',
                style: TextStyle(color: pal.textPrimary),
              ),
              onChanged: (v) =>
                  ctrl.updateNotifications(n.copyWith(streakNotifications: v)),
            ),
            SwitchListTile(
              value: n.streakUpdatesOnOpen,
              activeThumbColor: pal.accent,
              title: Text(
                'Streak updates',
                style: TextStyle(color: pal.textPrimary),
              ),
              subtitle: Text(
                'Get streak updates when opening the App.',
                style: TextStyle(color: pal.textMuted),
              ),
              onChanged: (v) =>
                  ctrl.updateNotifications(n.copyWith(streakUpdatesOnOpen: v)),
            ),
            _GroupLabel('More', pal: pal),
            SwitchListTile(
              value: n.weeklyReport,
              activeThumbColor: pal.accent,
              title: Text(
                'Weekly Report',
                style: TextStyle(color: pal.textPrimary),
              ),
              onChanged: (v) =>
                  ctrl.updateNotifications(n.copyWith(weeklyReport: v)),
            ),
            SwitchListTile(
              value: n.weeklyProgress,
              activeThumbColor: pal.accent,
              title: Text(
                'Weekly Progress',
                style: TextStyle(color: pal.textPrimary),
              ),
              onChanged: (v) =>
                  ctrl.updateNotifications(n.copyWith(weeklyProgress: v)),
            ),
            _GroupLabel('Social', pal: pal),
            SwitchListTile(
              value: n.friendsAndGroups,
              activeThumbColor: pal.accent,
              title: Text(
                'Friends & Groups',
                style: TextStyle(color: pal.textPrimary),
              ),
              onChanged: (v) =>
                  ctrl.updateNotifications(n.copyWith(friendsAndGroups: v)),
            ),
            SwitchListTile(
              value: n.statistics,
              activeThumbColor: pal.accent,
              title: Text(
                'Statistics',
                style: TextStyle(color: pal.textPrimary),
              ),
              onChanged: (v) =>
                  ctrl.updateNotifications(n.copyWith(statistics: v)),
            ),
            SwitchListTile(
              value: n.competitions,
              activeThumbColor: pal.accent,
              title: Text(
                'Competitions',
                style: TextStyle(color: pal.textPrimary),
              ),
              onChanged: (v) =>
                  ctrl.updateNotifications(n.copyWith(competitions: v)),
            ),
            SwitchListTile(
              value: n.challenges,
              activeThumbColor: pal.accent,
              title: Text(
                'Challenges',
                style: TextStyle(color: pal.textPrimary),
              ),
              onChanged: (v) =>
                  ctrl.updateNotifications(n.copyWith(challenges: v)),
            ),
            SwitchListTile(
              value: n.chat,
              activeThumbColor: pal.accent,
              title: Text('Chat', style: TextStyle(color: pal.textPrimary)),
              onChanged: (v) => ctrl.updateNotifications(n.copyWith(chat: v)),
            ),
          ],
        ),
      );
    });
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  final StepTrackPalette pal;
  const _GroupLabel(this.text, {required this.pal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        text,
        style: TextStyle(color: pal.textMuted, fontSize: 13),
      ),
    );
  }
}