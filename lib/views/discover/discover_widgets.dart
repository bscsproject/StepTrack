import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:step_track/model/suite_models.dart';

class ChallengeSectionWidget extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<ChallengeItem> items;
  final ValueChanged<ChallengeItem> onToggleJoin;
  final ValueChanged<ChallengeItem> onAddSteps;
  final VoidCallback? onSeeAll;

  const ChallengeSectionWidget({
    super.key,
    required this.title,
    required this.emptyText,
    required this.items,
    required this.onToggleJoin,
    required this.onAddSteps,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onSeeAll != null)
              TextButton(onPressed: onSeeAll, child: const Text('See All')),
          ],
        ),
        const SizedBox(height: 6),
        if (items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(emptyText),
            ),
          )
        else
          ...items.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(label: Text(item.category.toUpperCase())),
                        const Spacer(),
                        Text('${item.participants} participants'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(item.description),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: item.progress),
                    const SizedBox(height: 4),
                    Text(
                      '${NumberFormat.decimalPattern().format(item.currentSteps)} / ${NumberFormat.decimalPattern().format(item.targetSteps)} steps (${(item.progress * 100).toStringAsFixed(0)}%)',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => onToggleJoin(item),
                            child: Text(item.joined ? 'Joined' : 'Join'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: () => onAddSteps(item),
                            child: const Text('+1,000 Steps'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class GroupsSectionWidget extends StatelessWidget {
  final List<GroupItem> groups;
  final ValueChanged<GroupItem> onToggleJoin;
  final VoidCallback onOpenGroupsModal;

  const GroupsSectionWidget({
    super.key,
    required this.groups,
    required this.onToggleJoin,
    required this.onOpenGroupsModal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Groups (${groups.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: onOpenGroupsModal,
              child: const Text('Manage Groups'),
            ),
          ],
        ),
        if (groups.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('No groups created yet.'),
            ),
          )
        else
          ...groups.map(
            (g) => Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.groups)),
                title: Text(g.name),
                subtitle: Text(
                  '${g.city} • ${g.membersCount} members • ${NumberFormat.decimalPattern().format(g.weeklySteps)} weekly steps',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () => onToggleJoin(g),
                  child: Text(g.isJoined ? 'Joined' : 'Join'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PeopleSectionWidget extends StatelessWidget {
  final List<SuggestedMemberItem> people;
  final ValueChanged<SuggestedMemberItem> onToggleConnect;

  const PeopleSectionWidget({
    super.key,
    required this.people,
    required this.onToggleConnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'People You Might Know (${people.length})',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (people.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('No member suggestions right now.'),
            ),
          )
        else
          ...people.map(
            (p) => Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : 'W'),
                ),
                title: Text(p.name),
                subtitle: Text(
                  '${p.handle} • ${NumberFormat.decimalPattern().format(p.todaySteps)} steps today',
                ),
                trailing: OutlinedButton(
                  onPressed: () => onToggleConnect(p),
                  child: Text(p.connected ? 'Connected' : 'Connect'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
