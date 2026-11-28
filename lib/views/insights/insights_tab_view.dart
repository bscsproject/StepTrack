import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/controller/step_track_hub_controller.dart';
import 'package:step_track/routes/app_routes.dart';
import 'package:step_track/themes/step_track_theme.dart';
import 'package:step_track/widgets/hub_navigation_widgets.dart';

class InsightsTabView extends StatefulWidget {
  const InsightsTabView({super.key});

  @override
  State<InsightsTabView> createState() => _InsightsTabViewState();
}

class _InsightsTabViewState extends State<InsightsTabView> {
  static const List<String> _trendPeriods = ['7 Days', 'Week', 'Month', 'Year'];
  static const List<String> _dayMetrics = [
    'Steps',
    'Calories',
    'Distance',
    'Duration',
    'Live Trends',
  ];

  int _trendIndex = 0;
  bool _showAllAwards = false;

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
      final isAwards = ctrl.insightsSubTab.value == 1;
      final todayVal = ctrl.todaySteps.value;
      final usualVal = ctrl.usualSteps;
      final diffText = todayVal >= usualVal
          ? 'So far you have taken more steps than you usually do.'
          : 'So far you have taken fewer steps than you usually do.';

      return Scaffold(
        backgroundColor: pal.scaffoldBg,
        floatingActionButton: FloatingActionButton(
          onPressed: () => ctrl.openInsightsTab(subTab: isAwards ? 0 : 1),
          backgroundColor: pal.accent,
          foregroundColor: pal.onAccent,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28),
        ),
        body: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              Row(
                children: [
                  const HubAvatarDropdownButton(),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: pal.chipBg,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        _SubSegment(
                          label: 'Insights',
                          selected: !isAwards,
                          pal: pal,
                          onTap: () => ctrl.insightsSubTab.value = 0,
                        ),
                        _SubSegment(
                          label: 'Awards',
                          selected: isAwards,
                          pal: pal,
                          onTap: () => ctrl.insightsSubTab.value = 1,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 34),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                isAwards ? 'Awards' : 'Insights',
                style: TextStyle(
                  color: pal.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isAwards
                    ? 'Count Steps. Earn Awards.'
                    : 'Trends. Totals. Records',
                style: TextStyle(color: pal.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 18),
              if (!isAwards) ...[
                _buildMyDayCard(ctrl, pal, p.isProActive, usualVal, diffText),
                const SizedBox(height: 16),
                _buildStreaksCard(ctrl, pal, p.isProActive),
                const SizedBox(height: 16),
                _buildTrendsCard(ctrl, pal, p.isProActive),
                const SizedBox(height: 16),
                _buildTotalsCard(ctrl, pal),
              ] else ...[
                _buildAwardsTabContent(ctrl, pal),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMyDayCard(
    StepTrackHubController ctrl,
    StepTrackPalette pal,
    bool isPro,
    int usualVal,
    String diffText,
  ) {
    final activeMetric = _dayMetrics.contains(ctrl.selectedMetric.value)
        ? ctrl.selectedMetric.value
        : 'Steps';

    return _CardContainer(
      pal: pal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My day',
                style: TextStyle(
                  color: pal.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              DropdownButton<String>(
                value: activeMetric,
                dropdownColor: pal.elevatedBg,
                underline: const SizedBox.shrink(),
                style: TextStyle(
                  color: pal.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                items: _dayMetrics.map((m) {
                  final requiresPro = m != 'Steps';
                  return DropdownMenuItem(
                    value: m,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(m),
                        if (requiresPro && !isPro) ...[
                          const SizedBox(width: 6),
                          _ProBadge(pal: pal),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  if (v != 'Steps' && !isPro) {
                    Get.toNamed(AppRoutes.proUpgrade);
                    return;
                  }
                  ctrl.selectedMetric.value = v;
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TODAY',
                    style: TextStyle(
                      color: pal.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _metricDisplay(ctrl),
                    style: TextStyle(
                      color: pal.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 34),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'USUALLY',
                    style: TextStyle(
                      color: pal.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatInt(usualVal)} steps',
                    style: TextStyle(
                      color: pal.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            width: double.infinity,
            child: CustomPaint(
              painter: _DayTrendPainter(
                values: ctrl.hourlySteps.toList(),
                accent: pal.accent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '12:00 am',
                style: TextStyle(color: pal.textMuted, fontSize: 12),
              ),
              Text(
                '12:00 am',
                style: TextStyle(color: pal.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            diffText,
            style: TextStyle(color: pal.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStreaksCard(
    StepTrackHubController ctrl,
    StepTrackPalette pal,
    bool isPro,
  ) {
    return _CardContainer(
      pal: pal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Streaks',
                style: TextStyle(
                  color: pal.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Steps',
                style: TextStyle(
                  color: pal.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Streak',
                      style: TextStyle(color: pal.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ctrl.streakDays.value} days',
                      style: TextStyle(
                        color: pal.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: pal.borderColor, width: 8),
                ),
                child: Icon(
                  Icons.directions_walk,
                  color: pal.textPrimary,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                if (!isPro) {
                  Get.toNamed(AppRoutes.proUpgrade);
                } else {
                  ctrl.enableGoalHistory();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: pal.buttonSecondaryBg,
                foregroundColor: pal.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                ctrl.prefs.value.goalHistoryEnabled
                    ? 'Goal History Enabled'
                    : 'Enable Goal History',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsCard(
    StepTrackHubController ctrl,
    StepTrackPalette pal,
    bool isPro,
  ) {
    final period = _trendPeriods[_trendIndex];
    final previousLabel = period == 'Month'
        ? 'LAST MONTH'
        : period == 'Year'
            ? 'LAST YEAR'
            : 'LAST WEEK';
    final currentLabel = period == 'Month'
        ? 'THIS MONTH'
        : period == 'Year'
            ? 'THIS YEAR'
            : 'THIS WEEK';

    final now = DateTime.now();
    final windowDays = period == 'Month'
        ? 30
        : period == 'Year'
            ? 365
            : 7;

    var currentSum = 0;
    var previousSum = 0;
    for (var i = 0; i < windowDays; i++) {
      final dCurr = now.subtract(Duration(days: i));
      final dPrev = now.subtract(Duration(days: i + windowDays));
      currentSum += ctrl.stepsByDay[_dateKey(dCurr)] ?? 0;
      previousSum += ctrl.stepsByDay[_dateKey(dPrev)] ?? 0;
    }

    return _CardContainer(
      pal: pal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trends',
            style: TextStyle(
              color: pal.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: pal.chipBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: List.generate(_trendPeriods.length, (index) {
                final selected = _trendIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _trendIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? pal.activeChipBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        _trendPeriods[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? pal.textPrimary : pal.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      previousLabel,
                      style: TextStyle(
                        color: pal.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatInt(previousSum)} steps',
                      style: TextStyle(
                        color: pal.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentLabel,
                      style: TextStyle(
                        color: pal.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatInt(currentSum)} steps',
                      style: TextStyle(
                        color: pal.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isPro) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: () => Get.toNamed(AppRoutes.proUpgrade),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: pal.elevatedBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _ProBadge(pal: pal),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Unlock detailed $period comparison charts',
                        style: TextStyle(
                          color: pal.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: pal.textMuted, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalsCard(StepTrackHubController ctrl, StepTrackPalette pal) {
    final totalSteps = ctrl.stepsByDay.values.fold<int>(0, (a, b) => a + b);
    final now = DateTime.now();
    final sortedDates = ctrl.stepsByDay.keys.toList()..sort();
    final firstDate = sortedDates.isNotEmpty
        ? DateTime.tryParse(sortedDates.first) ?? now
        : now;
    final startYear = firstDate.year;
    final endYear = now.year;
    final sinceLabel =
        '${firstDate.day.toString().padLeft(2, '0')}/${firstDate.month.toString().padLeft(2, '0')}/${firstDate.year}';

    return _CardContainer(
      pal: pal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Totals',
                style: TextStyle(
                  color: pal.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$startYear - $endYear',
                style: TextStyle(
                  color: pal.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_formatInt(totalSteps)} steps',
            style: TextStyle(
              color: pal.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Overall you walked ${_formatInt(totalSteps)} steps since $sinceLabel',
            style: TextStyle(color: pal.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAwardsTabContent(
    StepTrackHubController ctrl,
    StepTrackPalette pal,
  ) {
    final goal = ctrl.dailyStepGoal.value > 0
        ? ctrl.dailyStepGoal.value
        : StepTrackHubController.defaultDailyGoal;
    final today = ctrl.todaySteps.value;
    final streak = ctrl.streakDays.value;
    final totalSteps = ctrl.stepsByDay.values.fold<int>(0, (a, b) => a + b);
    final maxDaily = ctrl.stepsByDay.values.isEmpty
        ? today
        : ctrl.stepsByDay.values.reduce((a, b) => a > b ? a : b);

    final inProgressItems = [
      _AwardItem('Goal achieved', 'Reach 100% of daily goal', today >= goal),
      _AwardItem('Goal 200%', 'Reach 200% of daily goal', today >= goal * 2),
      _AwardItem('Goal 300%', 'Reach 300% of daily goal', today >= goal * 3),
      _AwardItem('7 Day Streak', 'Hit goal 7 days in a row', streak >= 7),
      _AwardItem('14 Day Streak', 'Hit goal 14 days in a row', streak >= 14),
      _AwardItem('30 Day Streak', 'Hit goal 30 days in a row', streak >= 30),
    ];

    final longestStreakItems = [
      _AwardItem('200 Day Streak', '200 consecutive goal days', streak >= 200),
      _AwardItem('250 Day Streak', '250 consecutive goal days', streak >= 250),
      _AwardItem('300 Day Streak', '300 consecutive goal days', streak >= 300),
    ];

    final stepMilestoneItems = [
      _AwardItem('5k Steps', 'Walk 5,000 steps in a day', maxDaily >= 5000),
      _AwardItem('10k Steps', 'Walk 10,000 steps in a day', maxDaily >= 10000),
      _AwardItem('20k Steps', 'Walk 20,000 steps in a day', maxDaily >= 20000),
      _AwardItem('1 Mio Steps', '1,000,000 total steps', totalSteps >= 1000000),
      _AwardItem('5 Mio Steps', '5,000,000 total steps', totalSteps >= 5000000),
      _AwardItem('10 Mio Steps', '10,000,000 total steps', totalSteps >= 10000000),
    ];

    final visibleSteps = _showAllAwards
        ? stepMilestoneItems
        : stepMilestoneItems.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AwardSection(
          title: 'In Progress',
          items: inProgressItems,
          pal: pal,
        ),
        const SizedBox(height: 16),
        _AwardSection(
          title: 'Longest Streaks',
          items: longestStreakItems,
          pal: pal,
        ),
        const SizedBox(height: 16),
        _AwardSection(
          title: 'Steps',
          items: visibleSteps,
          pal: pal,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: () => setState(() => _showAllAwards = !_showAllAwards),
            style: OutlinedButton.styleFrom(
              foregroundColor: pal.textPrimary,
              side: BorderSide(color: pal.borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(_showAllAwards ? 'Show Less' : 'Show All'),
          ),
        ),
      ],
    );
  }

  String _dateKey(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  String _formatInt(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  String _metricDisplay(StepTrackHubController ctrl) {
    switch (ctrl.selectedMetric.value) {
      case 'Distance':
        return '${ctrl.todayDistanceKm.toStringAsFixed(2)} km';
      case 'Calories':
        return '${ctrl.todayCaloriesKcal} kcal';
      case 'Duration':
        return '${(ctrl.todaySteps.value / 100).round()} mins';
      default:
        return _formatInt(ctrl.todaySteps.value);
    }
  }
}

class _AwardItem {
  final String title;
  final String subtitle;
  final bool unlocked;

  const _AwardItem(this.title, this.subtitle, this.unlocked);
}

class _AwardSection extends StatelessWidget {
  final String title;
  final List<_AwardItem> items;
  final StepTrackPalette pal;

  const _AwardSection({
    required this.title,
    required this.items,
    required this.pal,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      pal: pal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: pal.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: item.unlocked
                        ? pal.accent.withValues(alpha: 0.2)
                        : pal.chipBg,
                    child: Icon(
                      item.unlocked
                          ? Icons.emoji_events
                          : Icons.lock_outline,
                      size: 18,
                      color: item.unlocked ? pal.accent : pal.textMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            color: pal.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            color: pal.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.unlocked ? 'Unlocked' : 'In Progress',
                    style: TextStyle(
                      color: item.unlocked ? pal.accent : pal.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  final StepTrackPalette pal;
  const _ProBadge({required this.pal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: pal.accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          color: pal.onAccent,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SubSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final StepTrackPalette pal;
  final VoidCallback onTap;

  const _SubSegment({
    required this.label,
    required this.selected,
    required this.pal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? pal.activeChipBg : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? pal.textPrimary : pal.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  final StepTrackPalette pal;
  const _CardContainer({required this.child, required this.pal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pal.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pal.borderColor.withValues(alpha: 0.45)),
      ),
      child: child,
    );
  }
}

class _DayTrendPainter extends CustomPainter {
  final List<int> values;
  final Color accent;

  const _DayTrendPainter({required this.values, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = values.isEmpty
        ? 1
        : values.reduce((a, b) => a > b ? a : b).clamp(1, 1000000);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1).clamp(1, 23)) * size.width;
      final norm = (values[i] / maxVal).clamp(0.0, 1.0);
      final y = size.height - (norm * (size.height - 16)) - 8;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DayTrendPainter oldDelegate) => true;
}
