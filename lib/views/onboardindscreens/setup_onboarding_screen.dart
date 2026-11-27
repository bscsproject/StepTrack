import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/auth_service.dart';
import 'goal_onboarding_screen.dart';

/// StepTrack color palette.
/// Dark mode only.
class AppColors {
  AppColors._();

  // Brand colors
  static const Color primary = Color(0xFF8265FF);
  static const Color secondary = Color(0xFF35B9FF);
  static const Color success = Color(0xFF55E6C1);

  // Dark surfaces
  static const Color background = Color(0xFF0D1020);
  static const Color surface = Color(0xFF1D2340);
  static const Color surfaceElevated = Color(0xFF252C4B);
  static const Color border = Color(0xFF343B5C);

  // Text
  static const Color textPrimary = Color(0xFFF7F7FF);
  static const Color textSecondary = Color(0xFFA5AAC1);
  static const Color textMuted = Color(0xFF737B98);

  // Utility
  static const Color error = Color(0xFFFF647C);
  static const Color warning = Color(0xFFFFC76A);
  static const Color disabled = Color(0xFF515873);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF121832), background],
  );
}

class SetupOnboardingScreen extends StatefulWidget {
  final int totalSteps;
  final int currentStep;
  final VoidCallback? onNext;
  final VoidCallback? onContinue;

  const SetupOnboardingScreen({
    super.key,
    this.totalSteps = 8,
    this.currentStep = 1,
    this.onNext,
    this.onContinue,
  });

  @override
  State<SetupOnboardingScreen> createState() => _SetupOnboardingScreenState();
}

class _SetupOnboardingScreenState extends State<SetupOnboardingScreen> {
  final AuthService _authService = AuthService();

  String? _gender;
  int? _yearOfBirth;
  double? _weightKg;
  double? _heightCm;
  bool _isSaving = false;
  bool _hasNavigated = false;

  bool get _isFormComplete =>
      _gender != null &&
      _yearOfBirth != null &&
      _weightKg != null &&
      _heightCm != null;

  @override
  void initState() {
    super.initState();
    _loadSavedMetrics();
  }

  void _loadSavedMetrics() {
    try {
      final data = _authService.getCachedSetupMetrics();
      if (data != null && mounted) {
        setState(() {
          _gender = data['gender'] as String?;
          _yearOfBirth = data['yearOfBirth'] is int
              ? data['yearOfBirth'] as int
              : int.tryParse(data['yearOfBirth']?.toString() ?? '');
          _weightKg = data['weightKg'] is num
              ? (data['weightKg'] as num).toDouble()
              : double.tryParse(data['weightKg']?.toString() ?? '');
          _heightCm = data['heightCm'] is num
              ? (data['heightCm'] as num).toDouble()
              : double.tryParse(data['heightCm']?.toString() ?? '');
        });
      }
    } catch (e) {
      debugPrint('Setup load cache warning: $e');
    }
  }

  void _forceNavigateNext() {
    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;

    debugPrint('SETUP: Next pressed, navigation started');

    // Controller navigation callback
    if (widget.onContinue != null) {
      widget.onContinue!.call();
      return;
    }

    // Alternative callback
    if (widget.onNext != null) {
      widget.onNext!.call();
      return;
    }

    // Direct fallback navigation
    final int safeTotal = widget.totalSteps > 0 ? widget.totalSteps : 8;
    final int nextStep = (widget.currentStep + 1).clamp(0, safeTotal - 1);

    final nextScreen = GoalOnboardingScreen(
      totalSteps: safeTotal,
      currentStep: nextStep,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  Future<void> _pickGender() async {
    const options = ['Male', 'Female', 'Other'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Gender',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...options.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    item,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  trailing: _gender == item
                      ? const Icon(Icons.check_circle, color: AppColors.secondary)
                      : null,
                  onTap: () => Navigator.pop(context, item),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _gender = selected);
    }
  }

  Future<void> _pickYearOfBirth() async {
    final currentYear = DateTime.now().year;
    final years = List.generate(80, (i) => currentYear - 10 - i);
    int tempYear = _yearOfBirth ?? 2000;

    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Year of Birth',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(
                  height: 180,
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 42,
                    controller: FixedExtentScrollController(
                      initialItem: years
                          .indexOf(tempYear)
                          .clamp(0, years.length - 1),
                    ),
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (idx) {
                      setModalState(() => tempYear = years[idx]);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: years.length,
                      builder: (context, index) {
                        final y = years[index];
                        final active = y == tempYear;
                        return Center(
                          child: Text(
                            '$y',
                            style: TextStyle(
                              color: active
                                  ? AppColors.secondary
                                  : AppColors.textSecondary,
                              fontSize: active ? 22 : 17,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, tempYear),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _yearOfBirth = selected);
    }
  }

  Future<void> _pickWeight() async {
    double tempWeight = _weightKg ?? 65.0;

    final selected = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Weight (kg)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${tempWeight.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Slider(
                  value: tempWeight.clamp(30.0, 200.0),
                  min: 30.0,
                  max: 200.0,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.surfaceElevated,
                  onChanged: (val) {
                    setModalState(() {
                      tempWeight = (val * 2).round() / 2.0;
                    });
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, tempWeight),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _weightKg = selected);
    }
  }

  Future<void> _pickHeight() async {
    double tempHeight = _heightCm ?? 170.0;

    final selected = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Height (cm)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${tempHeight.round()} cm',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Slider(
                  value: tempHeight.clamp(100.0, 230.0),
                  min: 100.0,
                  max: 230.0,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.surfaceElevated,
                  onChanged: (val) {
                    setModalState(() => tempHeight = val.roundToDouble());
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, tempHeight),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _heightCm = selected);
    }
  }

  Future<void> _onNextPressed() async {
    if (!mounted || _hasNavigated) return;

    debugPrint('SETUP: Next button tapped');

    // Navigate immediately, saving should not block navigation.
    _forceNavigateNext();

    // Save setup metrics separately.
    try {
      await _authService.saveUserSetupMetrics(
        gender: _gender ?? 'Not specified',
        yearOfBirth: _yearOfBirth ?? 2000,
        weightKg: _weightKg ?? 65.0,
        heightCm: _heightCm ?? 170.0,
      );

      debugPrint('SETUP: Metrics saved successfully');
    } catch (e) {
      debugPrint('SETUP: Metrics save error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final int safeTotal = widget.totalSteps > 0 ? widget.totalSteps : 8;
    final int safeStep = widget.currentStep.clamp(0, safeTotal - 1);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
            child: Column(
              children: [
                // 1. Top Segmented Onboarding Progress Bars (8 steps consistent)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Row(
                    children: List.generate(safeTotal, (index) {
                      final bool isActive = index <= safeStep;
                      return Expanded(
                        child: Container(
                          height: 4.5,
                          margin: EdgeInsets.only(
                            right: index == safeTotal - 1 ? 0 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.secondary
                                : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 36),

                // 2. Title & Subtitle
                const Text(
                  'Setup',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'For accurate steps, distance and\ncalories calculations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 17,
                    height: 1.38,
                  ),
                ),

                const SizedBox(height: 34),

                // 3. Setup Options Card (Gender, Year of birth, Weight, Height)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _SetupOptionTile(
                        iconWidget: const Icon(
                          Icons.directions_walk,
                          color: AppColors.secondary,
                          size: 22,
                        ),
                        title: 'Gender',
                        valueText: _gender ?? 'Choose',
                        hasValue: _gender != null,
                        onTap: _pickGender,
                      ),
                      const _TileDivider(),
                      _SetupOptionTile(
                        iconWidget: const Icon(
                          Icons.cake_outlined,
                          color: AppColors.secondary,
                          size: 21,
                        ),
                        title: 'Year of birth',
                        valueText:
                            _yearOfBirth != null ? '$_yearOfBirth' : 'Choose',
                        hasValue: _yearOfBirth != null,
                        onTap: _pickYearOfBirth,
                      ),
                      const _TileDivider(),
                      _SetupOptionTile(
                        iconWidget: const Icon(
                          Icons.monitor_weight_outlined,
                          color: AppColors.secondary,
                          size: 21,
                        ),
                        title: 'Weight',
                        valueText: _weightKg != null
                            ? '${_weightKg!.toStringAsFixed(1)} kg'
                            : 'Choose',
                        hasValue: _weightKg != null,
                        onTap: _pickWeight,
                      ),
                      const _TileDivider(),
                      _SetupOptionTile(
                        iconWidget: const Icon(
                          Icons.height,
                          color: AppColors.secondary,
                          size: 22,
                        ),
                        title: 'Height',
                        valueText: _heightCm != null
                            ? '${_heightCm!.round()} cm'
                            : 'Choose',
                        hasValue: _heightCm != null,
                        onTap: _pickHeight,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // 4. Bottom "Next" Button using AppColors palette
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _isFormComplete && !_isSaving
                        ? AppColors.primaryGradient
                        : null,
                    color: _isFormComplete && !_isSaving
                        ? null
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ElevatedButton(
                    onPressed: _onNextPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppColors.textPrimary,
                      disabledForegroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : const Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupOptionTile extends StatelessWidget {
  final Widget iconWidget;
  final String title;
  final String valueText;
  final bool hasValue;
  final VoidCallback onTap;

  const _SetupOptionTile({
    required this.iconWidget,
    required this.title,
    required this.valueText,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(11),
              ),
              alignment: Alignment.center,
              child: iconWidget,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              valueText,
              style: TextStyle(
                color: hasValue ? AppColors.secondary : AppColors.textMuted,
                fontSize: 16,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 74,
      endIndent: 18,
      color: AppColors.border,
    );
  }
}