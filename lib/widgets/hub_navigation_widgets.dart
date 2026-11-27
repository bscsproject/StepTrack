import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/controller/step_track_hub_controller.dart';
import 'package:step_track/routes/app_routes.dart';
import 'package:step_track/themes/step_track_theme.dart';

class HubAvatarDropdownButton extends StatelessWidget {
  const HubAvatarDropdownButton({super.key});

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

      return PopupMenuButton<String>(
        offset: const Offset(0, 44),
        color: pal.elevatedBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onSelected: (value) {
          switch (value) {
            case 'profile':
              Get.toNamed(AppRoutes.profile);
              break;
            case 'goals':
              Get.toNamed(AppRoutes.bodyMeasurements);
              break;
            case 'support':
              ctrl.openUri(StepTrackHubController.supportUri);
              break;
            case 'settings':
              Get.toNamed(AppRoutes.settings);
              break;
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem<String>(
            value: 'profile',
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: pal.accent,
                  child: Text(
                    ctrl.userInitial.value,
                    style: TextStyle(
                      color: pal.onAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  ctrl.userName.value,
                  style: TextStyle(
                    color: pal.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'goals',
            child: Row(
              children: [
                Icon(Icons.track_changes, color: pal.accent, size: 20),
                const SizedBox(width: 10),
                Text('Goals', style: TextStyle(color: pal.textPrimary)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'support',
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: pal.accent, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Chat with Support',
                  style: TextStyle(color: pal.textPrimary),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings, color: pal.accent, size: 20),
                const SizedBox(width: 10),
                Text('Settings', style: TextStyle(color: pal.textPrimary)),
              ],
            ),
          ),
        ],
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pal.accent,
            shape: BoxShape.circle,
          ),
          child: Text(
            ctrl.userInitial.value,
            style: TextStyle(
              color: pal.onAccent,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      );
    });
  }
}

class StepTrackBottomNavBar extends StatelessWidget {
  const StepTrackBottomNavBar({super.key});

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

      return BottomNavigationBar(
        currentIndex: ctrl.navIndex.value,
        onTap: ctrl.changeBottomTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: pal.tileBg,
        selectedItemColor: pal.accent,
        unselectedItemColor: pal.textMuted,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            activeIcon: Icon(Icons.show_chart),
            label: 'Insights',
          ),
        ],
      );
    });
  }
}