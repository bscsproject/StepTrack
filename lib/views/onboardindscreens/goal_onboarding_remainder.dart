import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/auth_service.dart';

class GoalReminderOnboardingScreen extends StatefulWidget {
  final int totalSteps;
  final int currentStep;
  final VoidCallback? onContinue;

  const GoalReminderOnboardingScreen({
    super.key,
    this.totalSteps = 9,
    this.currentStep = 3,
    this.onContinue,
  });

  @override
  State<GoalReminderOnboardingScreen> createState() =>
      _GoalReminderOnboardingScreenState();
}

class _GoalReminderOnboardingScreenState
    extends State<GoalReminderOnboardingScreen> {
  final AuthService _authService = AuthService();
  bool _isRequesting = false;

  Future<void> _requestNotificationAndContinue() async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);

    try {
      PermissionStatus status = await Permission.notification.status;

      if (status.isDenied) {
        status = await Permission.notification.request();
      }

      final bool isAllowed = status.isGranted || status.isLimited;

      await _authService.saveGoalReminderPermission(
        reminderEnabled: isAllowed,
        permissionStatus: status.name,
      );

      if (status.isPermanentlyDenied) {
        Get.snackbar(
          'Notifications Disabled',
          'Reminders ke liye Settings se Notifications allow karein.',
          backgroundColor: const Color(0xFF1A252E),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          mainButton: TextButton(
            onPressed: () => openAppSettings(),
            child: const Text(
              'Open Settings',
              style: TextStyle(color: Color(0xFF4FD0F8), fontWeight: FontWeight.bold),
            ),
          ),
        );
      }

      if (widget.onContinue != null) {
        widget.onContinue!();
      } else {
        Get.snackbar(
          isAllowed ? 'Reminders Enabled' : 'Saved',
          isAllowed
              ? 'Goal Reminder notifications activate ho gayi hain.'
              : 'Preference save ho gayi hai.',
          backgroundColor: const Color(0xFF15222B),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080A0C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
          child: Column(
            children: [
              // 1. Top Segmented Onboarding Progress Bars (4th bar active)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Row(
                  children: List.generate(widget.totalSteps, (index) {
                    final bool isActive = index == widget.currentStep;
                    return Expanded(
                      child: Container(
                        height: 4.5,
                        margin: EdgeInsets.only(
                          right: index == widget.totalSteps - 1 ? 0 : 8,
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

              // 2. Green Rounded Badge with Ringing Bell & Sound Waves
              Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  color: const Color(0xFF35D41B),
                  borderRadius: BorderRadius.circular(36),
                ),
                child: CustomPaint(
                  painter: _BellBadgePainter(),
                ),
              ),

              const SizedBox(height: 30),

              // 3. Title: "Goal Reminder"
              const Text(
                'Goal Reminder',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 14),

              // 4. Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  'Activating reminders boosts goal\nachievement by 89%!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7D858E),
                    fontSize: 17,
                    height: 1.38,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const Spacer(flex: 4),

              // 5. Bottom Cyan "Continue" Pill Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _isRequesting ? null : _requestNotificationAndContinue,
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
                          'Continue',
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

/// Custom Painter for White Ringing Bell + Left & Right Arcs inside Green Badge
class _BellBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final wavePaint = Paint()
      ..color = const Color(0xFF7BE668)
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.5;

    // Left outer & inner wave arcs
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.49),
        width: size.width * 0.68,
        height: size.height * 0.56,
      ),
      2.65,
      0.85,
      false,
      wavePaint,
    );

    // Right outer & inner wave arcs
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, size.height * 0.49),
        width: size.width * 0.68,
        height: size.height * 0.56,
      ),
      -0.36,
      0.85,
      false,
      wavePaint,
    );

    // Top bell knob
    canvas.drawCircle(
      Offset(cx, size.height * 0.235),
      size.width * 0.042,
      whitePaint,
    );

    // Bell dome & flared rim
    final bellPath = Path()
      ..moveTo(cx - size.width * 0.16, size.height * 0.58)
      ..quadraticBezierTo(
        cx - size.width * 0.15,
        size.height * 0.28,
        cx,
        size.height * 0.28,
      )
      ..quadraticBezierTo(
        cx + size.width * 0.15,
        size.height * 0.28,
        cx + size.width * 0.16,
        size.height * 0.58,
      )
      ..lineTo(cx + size.width * 0.22, size.height * 0.64)
      ..lineTo(cx - size.width * 0.22, size.height * 0.64)
      ..close();

    canvas.drawPath(bellPath, whitePaint);

    // Bottom clapper
    canvas.drawCircle(
      Offset(cx, size.height * 0.71),
      size.width * 0.058,
      whitePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}