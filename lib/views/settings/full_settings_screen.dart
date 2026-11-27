import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/controller/step_track_hub_controller.dart';
import 'package:step_track/routes/app_routes.dart';
import 'package:step_track/themes/step_track_theme.dart';

class FullSettingsScreen extends StatelessWidget {
  const FullSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<StepTrackHubController>();
    const swatches = <int>[
      0xFFEF5350,
      0xFFFF7043,
      0xFFFFCA28,
      0xFF2ECC71,
      0xFF4FD0F8,
      0xFFAB47BC,
      0xFF8E24AA,
    ];

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
            'Settings',
            style: TextStyle(
              color: pal.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 36),
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: pal.tileBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Text(
                    p.isProActive ? 'STEPTRACK PRO ACTIVE' : 'STEPTRACK PRO',
                    style: TextStyle(
                      color: pal.accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Get.toNamed(AppRoutes.proUpgrade),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pal.accent,
                        foregroundColor: pal.onAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Try Free Now',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _SectionTitle('Account', pal: pal),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: pal.tileBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                onTap: () => Get.toNamed(AppRoutes.profile),
                leading: CircleAvatar(
                  backgroundColor: pal.accent,
                  child: Text(
                    ctrl.userInitial.value,
                    style: TextStyle(
                      color: pal.onAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  ctrl.userName.value,
                  style: TextStyle(
                    color: pal.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'My Profile',
                  style: TextStyle(color: pal.textMuted),
                ),
                trailing: Icon(Icons.chevron_right, color: pal.textMuted),
              ),
            ),
            _SectionTitle('Appearance', pal: pal),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: pal.tileBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ThemeOption(
                        icon: Icons.settings,
                        label: 'System',
                        selected: p.themeMode == 'system',
                        pal: pal,
                        onTap: () => ctrl.saveHubPreferences(
                          p.copyWith(themeMode: 'system'),
                        ),
                      ),
                      _ThemeOption(
                        icon: Icons.check_circle_outline,
                        label: 'Dark',
                        selected: p.themeMode == 'dark',
                        pal: pal,
                        onTap: () => ctrl.saveHubPreferences(
                          p.copyWith(themeMode: 'dark'),
                        ),
                      ),
                      _ThemeOption(
                        icon: Icons.circle,
                        label: 'Light',
                        selected: p.themeMode == 'light',
                        pal: pal,
                        onTap: () => ctrl.saveHubPreferences(
                          p.copyWith(themeMode: 'light'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: swatches.map((hex) {
                      final active = p.accentColorValue == hex;
                      return GestureDetector(
                        onTap: () => ctrl.saveHubPreferences(
                          p.copyWith(accentColorValue: hex),
                        ),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Color(hex),
                            shape: BoxShape.circle,
                            border: active
                                ? Border.all(color: pal.textPrimary, width: 2.5)
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.widgets_outlined, color: pal.accent),
              title: Text(
                'Widget Appearance',
                style: TextStyle(color: pal.textPrimary),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final selected = p.widgetStyleIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: GestureDetector(
                      onTap: () => ctrl.saveHubPreferences(
                        p.copyWith(widgetStyleIndex: i),
                      ),
                      child: Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selected ? pal.textPrimary : pal.textMuted,
                        size: 20,
                      ),
                    ),
                  );
                }),
              ),
            ),
            _SectionTitle('General', pal: pal),
            _NavTile(
              icon: Icons.lightbulb_outline,
              title: 'Setup Step Counter',
              pal: pal,
              onTap: () => Get.toNamed(AppRoutes.setupStepCounter),
            ),
            _NavTile(
              icon: Icons.tune,
              title: 'General',
              pal: pal,
              onTap: () => Get.toNamed(AppRoutes.bodyMeasurements),
            ),
            _NavTile(
              icon: Icons.accessibility_new,
              title: 'Body Measurements',
              pal: pal,
              onTap: () => Get.toNamed(AppRoutes.bodyMeasurements),
            ),
            _NavTile(
              icon: Icons.notifications_none,
              title: 'Notifications',
              pal: pal,
              onTap: () => Get.toNamed(AppRoutes.notifications),
            ),
            _SectionTitle('Add-ons', pal: pal),
            _NavTile(
              icon: Icons.favorite,
              title: 'Import from Google Fit',
              pal: pal,
              onTap: () => Get.toNamed(AppRoutes.googleFitSync),
            ),
            _NavTile(
              icon: Icons.upload_outlined,
              title: 'Export Data',
              pal: pal,
              onTap: ctrl.exportStepDataToDevice,
            ),
            _NavTile(
              icon: Icons.download_outlined,
              title: 'Import Data',
              pal: pal,
              onTap: ctrl.importStepDataFromDevice,
            ),
            if (ctrl.appVersionText.value.isNotEmpty)
              _SectionTitle(ctrl.appVersionText.value, pal: pal),
            _NavTile(
              icon: Icons.card_giftcard,
              title: "What's New",
              pal: pal,
              onTap: () => ctrl.openUri(StepTrackHubController.blogUri),
            ),
            _NavTile(
              icon: Icons.notifications_active_outlined,
              title: 'Support',
              pal: pal,
              onTap: () => ctrl.openUri(StepTrackHubController.supportUri),
            ),
            _NavTile(
              icon: Icons.mail_outline,
              title: 'Contact Us',
              pal: pal,
              onTap: ctrl.openContactEmail,
            ),
            _NavTile(
              icon: Icons.star_border,
              title: 'Rate App',
              pal: pal,
              onTap: () => ctrl.openUri(StepTrackHubController.websiteUri),
            ),
            _NavTile(
              icon: Icons.share_outlined,
              title: 'Share this App',
              pal: pal,
              onTap: ctrl.shareApp,
            ),
            _NavTile(
              icon: Icons.verified_user_outlined,
              title: 'Privacy Policy',
              pal: pal,
              onTap: () => Get.toNamed(AppRoutes.privacySettings),
            ),
            _NavTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              pal: pal,
              onTap: () => ctrl.openUri(StepTrackHubController.termsUri),
            ),
            _SectionTitle('Follow us', pal: pal),
            ListTile(
              leading: Icon(Icons.directions_walk, color: pal.accent),
              title: Text('Blog', style: TextStyle(color: pal.textPrimary)),
              trailing: p.unreadBlogCount > 0
                  ? CircleAvatar(
                      radius: 11,
                      backgroundColor: const Color(0xFFD9383A),
                      child: Text(
                        '${p.unreadBlogCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : null,
              onTap: () => ctrl.openUri(StepTrackHubController.blogUri),
            ),
            _NavTile(
              icon: Icons.facebook,
              title: 'Facebook',
              pal: pal,
              onTap: () => ctrl.openUri(StepTrackHubController.facebookUri),
            ),
            _NavTile(
              icon: Icons.alternate_email,
              title: 'X',
              pal: pal,
              onTap: () => ctrl.openUri(StepTrackHubController.xUri),
            ),
            _NavTile(
              icon: Icons.camera_alt_outlined,
              title: 'Instagram',
              pal: pal,
              onTap: () => ctrl.openUri(StepTrackHubController.instagramUri),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => ctrl.openUri(StepTrackHubController.websiteUri),
                child: Text(
                  'www.steps.app',
                  style: TextStyle(
                    color: pal.accent,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final StepTrackPalette pal;
  const _SectionTitle(this.text, {required this.pal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        text,
        style: TextStyle(color: pal.textMuted, fontSize: 13),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final StepTrackPalette pal;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.pal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: pal.accent),
      title: Text(title, style: TextStyle(color: pal.textPrimary)),
      onTap: onTap,
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final StepTrackPalette pal;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.pal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: selected ? pal.textPrimary : pal.textMuted,
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? pal.textPrimary : pal.textMuted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: selected ? pal.textPrimary : pal.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}