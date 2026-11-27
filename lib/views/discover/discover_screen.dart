import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/controller/suite_realtime_controller.dart';
import 'package:step_track/model/groups_modal_screen.dart';
import 'package:step_track/views/discover/discover_widgets.dart';

import 'create_challenge_screen.dart';
import 'previous_challenges_screen.dart';
import 'weight_loss_plan_screen.dart';

class DiscoverScreen extends StatelessWidget {
  static const String routeName = '/discover-suite';

  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SuiteRealtimeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            tooltip: 'Create Challenge',
            icon: const Icon(Icons.add),
            onPressed: () => Get.toNamed(CreateChallengeScreen.routeName),
          ),
          IconButton(
            tooltip: 'Previous Challenges',
            icon: const Icon(Icons.history),
            onPressed: () => Get.toNamed(PreviousChallengesScreen.routeName),
          ),
          IconButton(
            tooltip: 'Seed Sample Data',
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: c.seedSuiteSampleData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(CreateChallengeScreen.routeName),
        icon: const Icon(Icons.add_task),
        label: const Text('New Challenge'),
      ),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              onChanged: (v) => c.searchQuery.value = v,
              decoration: const InputDecoration(
                hintText: 'Search challenges, groups, or walkers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: c.selectedCategory.value == 'all',
                  onSelected: (_) => c.selectedCategory.value = 'all',
                ),
                ChoiceChip(
                  label: const Text('Community'),
                  selected: c.selectedCategory.value == 'community',
                  onSelected: (_) => c.selectedCategory.value = 'community',
                ),
                ChoiceChip(
                  label: const Text('Personal'),
                  selected: c.selectedCategory.value == 'personal',
                  onSelected: (_) => c.selectedCategory.value = 'personal',
                ),
                ChoiceChip(
                  label: const Text('Fitness Plans'),
                  selected: c.selectedCategory.value == 'plan',
                  onSelected: (_) => c.selectedCategory.value = 'plan',
                ),
              ],
            ),
            const SizedBox(height: 16),
            ChallengeSectionWidget(
              title: 'My & Community Challenges',
              emptyText: 'No active challenges yet.',
              items: c.filteredChallenges
                  .where((dynamic x) => !((x.completed ?? false) as bool))
                  .toList(),
              onToggleJoin: c.toggleChallengeJoin,
              onAddSteps: (item) => c.incrementChallengeSteps(item, 1000),
              onSeeAll: () => Get.toNamed(PreviousChallengesScreen.routeName),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.monitor_weight_outlined),
                title: const Text('Weight Loss & Cardio Step Plan'),
                subtitle: const Text('Open dedicated plan tracker'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Get.toNamed(WeightLossPlanScreen.routeName),
              ),
            ),
            const SizedBox(height: 16),
            GroupsSectionWidget(
              groups: c.groups,
              onToggleJoin: c.toggleGroupJoin,
              onOpenGroupsModal: () => Get.toNamed(GroupsModalScreen.routeName),
            ),
            const SizedBox(height: 16),
            PeopleSectionWidget(
              people: c.people,
              onToggleConnect: c.toggleConnectPerson,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}