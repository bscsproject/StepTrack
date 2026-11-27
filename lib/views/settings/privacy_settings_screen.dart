import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/controller/step_track_hub_controller.dart';
import 'package:step_track/themes/step_track_theme.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

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
          title: Text(
            'Privacy Policy',
            style: TextStyle(
              color: pal.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Help improve the app',
                style: TextStyle(color: pal.textMuted, fontSize: 13),
              ),
            ),
            SwitchListTile(
              value: p.crashLogsEnabled,
              activeThumbColor: pal.accent,
              tileColor: pal.tileBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Crash Logs',
                style: TextStyle(color: pal.textPrimary),
              ),
              onChanged: (v) =>
                  ctrl.saveHubPreferences(p.copyWith(crashLogsEnabled: v)),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: p.usageStatisticsEnabled,
              activeThumbColor: pal.accent,
              tileColor: pal.tileBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Usage Statistics',
                style: TextStyle(color: pal.textPrimary),
              ),
              onChanged: (v) => ctrl.saveHubPreferences(
                p.copyWith(usageStatisticsEnabled: v),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Improve your ad experience',
                style: TextStyle(color: pal.textMuted, fontSize: 13),
              ),
            ),
            SwitchListTile(
              value: p.personalizedAdsEnabled,
              activeThumbColor: pal.accent,
              tileColor: pal.tileBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Personalized Ads',
                style: TextStyle(color: pal.textPrimary),
              ),
              onChanged: (v) => ctrl.saveHubPreferences(
                p.copyWith(personalizedAdsEnabled: v),
              ),
            ),
          ],
        ),
      );
    });
  }
}