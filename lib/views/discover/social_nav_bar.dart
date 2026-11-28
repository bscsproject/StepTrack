import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/social_realtime_controller.dart';
import '../chat/chat_screen.dart';
import 'discover_screen.dart';
import 'social_hub_screen.dart';

class SocialNavBar extends StatelessWidget {
  final int currentIndex;

  const SocialNavBar({
    super.key,
    required this.currentIndex,
  });

  void _navigateToIndex(int index) {
    final controller = Get.find<SocialRealtimeController>();
    controller.hubTabIndex.value = index;

    if (index == 0 && Get.currentRoute != SocialHubScreen.routeName) {
      Get.offAllNamed(SocialHubScreen.routeName);
    } else if (index == 1 && Get.currentRoute != ChatScreen.routeName) {
      Get.toNamed(ChatScreen.routeName);
    } else if (index == 2 && Get.currentRoute != DiscoverScreen.routeName) {
      Get.toNamed(DiscoverScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SocialRealtimeController>();

    return Obx(
      () => NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _navigateToIndex,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Hub',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: controller.totalUnreadCount > 0,
              label: Text('${controller.totalUnreadCount}'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: controller.totalUnreadCount > 0,
              label: Text('${controller.totalUnreadCount}'),
              child: const Icon(Icons.chat_bubble),
            ),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: 'Discover',
          ),
        ],
      ),
    );
  }
}
