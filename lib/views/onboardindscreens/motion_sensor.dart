import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

enum _PermanentlyDeniedAction { continueAnyway, openSettings }

class MotionSensorOnboardingScreen extends StatefulWidget {
  final int totalSteps;
  final int currentStep;
  final VoidCallback onContinue;
  final ValueChanged<bool>? onPermissionResult;

  const MotionSensorOnboardingScreen({
    super.key,
    this.totalSteps = 8,
    this.currentStep = 0,
    required this.onContinue,
    this.onPermissionResult,
  });

  @override
  State<MotionSensorOnboardingScreen> createState() =>
      _MotionSensorOnboardingScreenState();
}

class _MotionSensorOnboardingScreenState
    extends State<MotionSensorOnboardingScreen>
    with WidgetsBindingObserver {
  bool _isRequesting = false;
  bool _hasContinued = false;
  bool _waitingForSettings = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_continueIfPermissionIsGranted());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForSettings) {
      _waitingForSettings = false;
      unawaited(_continueIfPermissionIsGranted());
    }
  }

  Future<void> _continueIfPermissionIsGranted() async {
    if (!mounted || _hasContinued) return;

    try {
      final status = await Permission.activityRecognition.status;
      if (status.isGranted || status.isLimited) {
        _continueToNextStep(isGranted: true);
      }
    } catch (error, stackTrace) {
      debugPrint('Could not recheck Motion Sensor permission: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _continueToNextStep({required bool isGranted}) {
    if (!mounted || _hasContinued) return;

    widget.onPermissionResult?.call(isGranted);
    widget.onContinue();
    _hasContinued = true;
  }

  Future<void> _onAllowButtonPressed() async {
    if (_isRequesting || _hasContinued) return;
    setState(() => _isRequesting = true);

    bool isGranted = false;

    try {
      PermissionStatus status = await Permission.activityRecognition.status;

      if (!status.isGranted &&
          !status.isLimited &&
          !status.isPermanentlyDenied) {
        status = await Permission.activityRecognition.request();
      }

      isGranted = status.isGranted || status.isLimited;

      if (!isGranted && status.isPermanentlyDenied && mounted) {
        final action = await showDialog<_PermanentlyDeniedAction>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF14191F),
            title: const Text(
              'Activity Permission Needed',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Physical Activity permission helps StepTrack count your steps. '
              'You can enable it in Settings or continue without it.',
              style: TextStyle(color: Color(0xFF9EA7B3)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(
                  ctx,
                ).pop(_PermanentlyDeniedAction.continueAnyway),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: Color(0xFF7D858E)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(
                  ctx,
                ).pop(_PermanentlyDeniedAction.openSettings),
                child: const Text(
                  'Open Settings',
                  style: TextStyle(color: Color(0xFF4FD0F8)),
                ),
              ),
            ],
          ),
        );

        if (!mounted || action == null) {
          return;
        }

        if (action == _PermanentlyDeniedAction.openSettings) {
          _waitingForSettings = true;
          final settingsOpened = await openAppSettings();
          if (!settingsOpened) {
            _waitingForSettings = false;
            if (mounted) {
              Get.snackbar(
                'Could not open Settings',
                'You can enable Motion Sensor permission from your device settings.',
                backgroundColor: const Color(0xFF15222B),
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          }
          return;
        }
      }

      _continueToNextStep(isGranted: isGranted);
    } catch (error, stackTrace) {
      debugPrint('Permission request failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _hasContinued = false;
      if (mounted) {
        Get.snackbar(
          'Permission Error',
          'Could not check or request Motion Sensor permission.',
          backgroundColor: const Color(0xFF15222B),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int safeTotal = widget.totalSteps > 0 ? widget.totalSteps : 8;
    final int safeStep = widget.currentStep.clamp(0, safeTotal - 1);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D10),
      body: SafeArea(
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
                              ? const Color(0xFF19A7E6)
                              : const Color(0xFF1B2026),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const Spacer(flex: 3),

              // 2. Green Rounded Badge with Running Figure & Speed Lines
              Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  color: const Color(0xFF35D41B),
                  borderRadius: BorderRadius.circular(36),
                ),
                child: CustomPaint(painter: _RunnerBadgePainter()),
              ),

              const SizedBox(height: 30),

              // 3. Title: "Motion Sensor"
              const Text(
                'Motion Sensor',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 14),

              // 4. Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  'To count your steps, we need your\npermission to access activity\nrecognition.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7D858E),
                    fontSize: 16.5,
                    height: 1.38,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const Spacer(flex: 4),

              // 5. Bottom Cyan Pill Button: "Allow Motion Sensor"
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : _onAllowButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FD0F8),
                    foregroundColor: const Color(0xFF0A1014),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isRequesting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF0A1014),
                          ),
                        )
                      : const Text(
                          'Allow Motion Sensor',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0A1014),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunnerBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final speedPaint = Paint()
      ..color = const Color(0xFF7BE668)
      ..strokeWidth = 7.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.44),
      Offset(size.width * 0.43, size.height * 0.44),
      speedPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.19, size.height * 0.54),
      Offset(size.width * 0.40, size.height * 0.54),
      speedPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.24),
      size.width * 0.068,
      whitePaint,
    );

    strokePaint.strokeWidth = 12;
    canvas.drawLine(
      Offset(size.width * 0.58, size.height * 0.34),
      Offset(size.width * 0.49, size.height * 0.56),
      strokePaint,
    );

    strokePaint.strokeWidth = 9.5;
    final frontArm = Path()
      ..moveTo(size.width * 0.57, size.height * 0.37)
      ..lineTo(size.width * 0.71, size.height * 0.41)
      ..lineTo(size.width * 0.78, size.height * 0.35);
    canvas.drawPath(frontArm, strokePaint);

    final backArm = Path()
      ..moveTo(size.width * 0.55, size.height * 0.38)
      ..lineTo(size.width * 0.43, size.height * 0.46);
    canvas.drawPath(backArm, strokePaint);

    strokePaint.strokeWidth = 11.5;
    final frontLeg = Path()
      ..moveTo(size.width * 0.49, size.height * 0.56)
      ..lineTo(size.width * 0.63, size.height * 0.63)
      ..lineTo(size.width * 0.67, size.height * 0.79);
    canvas.drawPath(frontLeg, strokePaint);

    final backLeg = Path()
      ..moveTo(size.width * 0.49, size.height * 0.56)
      ..lineTo(size.width * 0.36, size.height * 0.67)
      ..lineTo(size.width * 0.27, size.height * 0.77);
    canvas.drawPath(backLeg, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
