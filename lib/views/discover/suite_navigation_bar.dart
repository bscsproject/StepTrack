import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/controller/suite_realtime_controller.dart';
import 'package:step_track/views/chat/chats_home_screen.dart';
import 'package:step_track/views/chat/stepsapp_feed_screen.dart';
import 'package:step_track/views/discover/discover_screen.dart';


class SuiteNavigationBar extends StatelessWidget {
  final int currentIndex; // 0 = Discover, 1 = Chats, 2 = Feed

  const SuiteNavigationBar({super.key, required this.currentIndex});

  void _onSelect(int index) {
    if (index == currentIndex) return;
    if (index == 0) {
      Get.offAllNamed(DiscoverScreen.routeName);
    } else if (index == 1) {
      Get.offAllNamed(ChatsHomeScreen.routeName);
    } else if (index == 2) {
      Get.offAllNamed(StepsAppFeedScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SuiteRealtimeController>();
    return Obx(
      () => NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _onSelect,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: controller.totalUnread > 0,
              label: Text('${controller.totalUnread}'),
              child: const Icon(Icons.chat_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: controller.totalUnread > 0,
              label: Text('${controller.totalUnread}'),
              child: const Icon(Icons.chat),
            ),
            label: 'Chats',
          ),
          const NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed),
            label: 'Feed',
          ),
        ],
      ),
    );
  }
}
