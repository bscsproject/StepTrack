import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/controller/step_track_hub_controller.dart';
import 'package:step_track/themes/step_track_theme.dart';

class GoogleFitSyncScreen extends StatelessWidget {
  const GoogleFitSyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<StepTrackHubController>();

    return Obx(() {
      final p = ctrl.prefs.value;
      final enabled = p.googleFitSyncEnabled;
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
            'Google Fit Sync',
            style: TextStyle(
              color: pal.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Icon(Icons.favorite, color: pal.accent, size: 54),
            ),
            const SizedBox(height: 18),
            SwitchListTile(
              value: enabled,
              activeThumbColor: pal.accent,
              tileColor: pal.tileBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Google Fit Sync',
                style: TextStyle(color: pal.textPrimary),
              ),
              subtitle: Text(
                'Keep StepTrack in sync with Google Fit and your Wear OS devices.',
                style: TextStyle(color: pal.textMuted),
              ),
              onChanged: (v) => ctrl.saveHubPreferences(
                p.copyWith(googleFitSyncEnabled: v),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: pal.tileBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Google Fit Import',
                    style: TextStyle(
                      color: pal.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Import existing steps from Google Fit.',
                    style: TextStyle(color: pal.textMuted),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: ctrl.isImportingFit.value
                          ? null
                          : ctrl.importFromGoogleFit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pal.buttonSecondaryBg,
                        foregroundColor: pal.accent,
                      ),
                      child: ctrl.isImportingFit.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Import now'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}