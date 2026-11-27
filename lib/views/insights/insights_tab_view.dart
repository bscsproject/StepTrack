import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/controller/step_track_hub_controller.dart';
import 'package:step_track/themes/step_track_theme.dart';
import 'package:step_track/widgets/hub_navigation_widgets.dart';

class InsightsTabView extends StatelessWidget {
  const InsightsTabView({super.key});

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
                    ? '${ctrl.awardsCount.value} goal days unlocked'
                    : 'Trends. Totals. Records',
                style: TextStyle(color: pal.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 18),
              if (!isAwards) ...[
                _CardContainer(
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
                            value: ctrl.selectedMetric.value,
                            dropdownColor: pal.elevatedBg,
                            underline: const SizedBox.shrink(),
                            style: TextStyle(
                              color: pal.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            items: const ['Steps', 'Distance', 'Calories']
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) ctrl.selectedMetric.value = v;
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
                                _formatInt(usualVal),
                                style: TextStyle(
                                  color: pal.textPrimary,
                                  fontSize: 28,
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
                            style: TextStyle(
                              color: pal.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Live',
                            style: TextStyle(
                              color: pal.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        diffText,
                        style: TextStyle(
                          color: pal.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _CardContainer(
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
                                  style: TextStyle(
                                    color: pal.textSecondary,
                                    fontSize: 14,
                                  ),
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
                              border: Border.all(
                                color: pal.borderColor,
                                width: 8,
                              ),
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
                          onPressed: ctrl.enableGoalHistory,
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
                ),
              ] else ...[
                _CardContainer(
                  pal: pal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlocked Goal Days: ${ctrl.awardsCount.value}',
                        style: TextStyle(
                          color: pal.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Daily target: ${_formatInt(ctrl.dailyStepGoal.value)} steps',
                        style: TextStyle(color: pal.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
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
      default:
        return _formatInt(ctrl.todaySteps.value);
    }
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