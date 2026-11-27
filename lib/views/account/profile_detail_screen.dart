import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/controller/step_track_hub_controller.dart';
import 'package:step_track/routes/app_routes.dart';
import 'package:step_track/themes/step_track_theme.dart';

class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<StepTrackHubController>();

    return Obx(() {
      final p = ctrl.prefs.value;
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
            icon: Icon(Icons.close, color: pal.textPrimary),
            onPressed: () => Get.back(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: pal.accent,
                child: Text(
                  ctrl.userInitial.value,
                  style: TextStyle(
                    color: pal.onAccent,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                ctrl.userName.value,
                style: TextStyle(
                  color: pal.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: pal.elevatedBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  ctrl.providerLabel.value,
                  style: TextStyle(color: pal.textSecondary, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCol(
                  label: 'Average Steps',
                  value: '${ctrl.averageStepsAllDays}',
                  pal: pal,
                ),
                _StatCol(
                  label: 'Streak',
                  value: '${ctrl.streakDays.value}',
                  pal: pal,
                ),
                _StatCol(
                  label: 'Awards',
                  value: '${ctrl.awardsCount.value}',
                  pal: pal,
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: ctrl.shareProfile,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pal.accent,
                  foregroundColor: pal.onAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: ctrl.copyInviteLink,
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Copy Invite Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pal.buttonSecondaryBg,
                  foregroundColor: pal.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: () => Get.toNamed(AppRoutes.bodyMeasurements),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pal.elevatedBg,
                  foregroundColor: pal.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Edit Profile'),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              tileColor: pal.tileBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(
                'Notifications',
                style: TextStyle(color: pal.textPrimary),
              ),
              trailing: Icon(Icons.chevron_right, color: pal.textMuted),
              onTap: () => Get.toNamed(AppRoutes.notifications),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: p.emailNewsletter,
              activeThumbColor: pal.accent,
              tileColor: pal.tileBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(
                'Email Newsletter',
                style: TextStyle(color: pal.textPrimary),
              ),
              onChanged: (v) => ctrl.saveHubPreferences(
                p.copyWith(emailNewsletter: v),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: p.leaderboardEnabled,
              activeThumbColor: pal.accent,
              tileColor: pal.tileBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(
                'Leaderboard',
                style: TextStyle(color: pal.textPrimary),
              ),
              subtitle: Text(
                'Show Leaderboard and share steps with your Friends and Groups.',
                style: TextStyle(color: pal.textMuted, fontSize: 12),
              ),
              onChanged: (v) => ctrl.saveHubPreferences(
                p.copyWith(leaderboardEnabled: v),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: p.showFriendsEnabled,
              activeThumbColor: pal.accent,
              tileColor: pal.tileBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(
                'Show Friends',
                style: TextStyle(color: pal.textPrimary),
              ),
              subtitle: Text(
                'When enabled other users can see your friends.',
                style: TextStyle(color: pal.textMuted, fontSize: 12),
              ),
              onChanged: (v) => ctrl.saveHubPreferences(
                p.copyWith(showFriendsEnabled: v),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: ctrl.signOutUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: pal.buttonSecondaryBg,
                  foregroundColor: pal.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Sign Out'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'DANGER ZONE',
              style: TextStyle(
                color: pal.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: () => Get.snackbar(
                  'Account',
                  'Account deletion request can be submitted via Support.',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A161A),
                  foregroundColor: const Color(0xFFFF8A80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Delete Account'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;
  final StepTrackPalette pal;
  const _StatCol({
    required this.label,
    required this.value,
    required this.pal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: pal.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: pal.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}