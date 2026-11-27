import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/controller/step_track_hub_controller.dart';
import 'package:step_track/themes/step_track_theme.dart';

class ProUpgradeScreen extends StatelessWidget {
  const ProUpgradeScreen({super.key});

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
            'StepTrack Pro',
            style: TextStyle(
              color: pal.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FeatureBullet('Calories and Distance Goals', pal: pal),
              _FeatureBullet('Import from Google Fit', pal: pal),
              _FeatureBullet('Insights and Trends', pal: pal),
              _FeatureBullet('Pro widget', pal: pal),
              _FeatureBullet('Custom colors and Icons', pal: pal),
              _FeatureBullet('100% Ad Free', pal: pal),
              const Spacer(),
              _PlanOptionCard(
                title: 'Rs 5,200.00 / year',
                badgeText: 'SAVE 27%',
                selected: p.selectedBillingPlan == 'yearly',
                pal: pal,
                onTap: () => ctrl.saveHubPreferences(
                  p.copyWith(selectedBillingPlan: 'yearly'),
                ),
              ),
              const SizedBox(height: 10),
              _PlanOptionCard(
                title: 'Rs 590.00 / month',
                selected: p.selectedBillingPlan == 'monthly',
                pal: pal,
                onTap: () => ctrl.saveHubPreferences(
                  p.copyWith(selectedBillingPlan: 'monthly'),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      ctrl.isSubscribingPro.value ? null : ctrl.subscribeProPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pal.accent,
                    foregroundColor: pal.onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: ctrl.isSubscribingPro.value
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Subscribe Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _FeatureBullet extends StatelessWidget {
  final String text;
  final StepTrackPalette pal;
  const _FeatureBullet(this.text, {required this.pal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.check, color: pal.accent, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(color: pal.textPrimary, fontSize: 15.5),
          ),
        ],
      ),
    );
  }
}

class _PlanOptionCard extends StatelessWidget {
  final String title;
  final String? badgeText;
  final bool selected;
  final StepTrackPalette pal;
  final VoidCallback onTap;

  const _PlanOptionCard({
    required this.title,
    this.badgeText,
    required this.selected,
    required this.pal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: pal.tileBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? pal.accent : pal.borderColor,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? pal.accent : pal.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: pal.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (badgeText != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1D12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText!,
                  style: const TextStyle(
                    color: Color(0xFFFFA726),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}