import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/controller/auth_controller.dart';
import 'package:step_track/views/auth/login_screen.dart';
import 'package:step_track/views/auth/signup_screen.dart';

class WelcomeAuthScreen extends StatelessWidget {
  WelcomeAuthScreen({super.key});

  final AuthController _authController = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1016),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF101921),
              Color(0xFF070B0E),
              Color(0xFF05080A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Column(
              children: [
                // 1. Top Row: "Sign In" (Left) & "Skip" (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Get.to(() => const LoginScreen()),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: Color(0xFFB0BAC5),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _authController.skipToOnboarding(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Color(0xFFB0BAC5),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // 2. Exact "STEPTRACK" Logo with Cyan Pulse replacing 'A'
                const _StepTrackPulseLogo(),

                const Spacer(flex: 2),

                // 3. Center Dotted World Map + Glowing Trails + 3 Avatars
                SizedBox(
                  height: 235,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Dotted World Map + Glowing Curves
                      CustomPaint(
                        size: const Size(330, 220),
                        painter: _WorldMapAndTrailsPainter(),
                      ),
                      // Top Cyan Avatar
                      const Positioned(
                        top: 14,
                        right: 68,
                        child: _CommunityAvatar(
                          ringColor: Color(0xFF00D8FF),
                          avatarBg: Color(0xFFE8F4F8),
                          icon: Icons.face_6,
                          iconColor: Color(0xFF2B3A4A),
                        ),
                      ),
                      // Middle Purple Avatar
                      const Positioned(
                        top: 86,
                        right: 92,
                        child: _CommunityAvatar(
                          ringColor: Color(0xFF9B51E0),
                          avatarBg: Color(0xFFF3E8FF),
                          icon: Icons.face_3,
                          iconColor: Color(0xFF4A2B5A),
                        ),
                      ),
                      // Bottom Green Avatar
                      const Positioned(
                        bottom: 42,
                        right: 48,
                        child: _CommunityAvatar(
                          ringColor: Color(0xFF4CD964),
                          avatarBg: Color(0xFFE8F8EC),
                          icon: Icons.face,
                          iconColor: Color(0xFF1F3D28),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // 4. Headline Text
                const Text(
                  'Welcome to the #1 Step\nCounting Community',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    height: 1.28,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 28),

                // 5. White Pill Button: "Continue with Google"
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _authController.isGoogleLoading.value
                          ? null
                          : () => _authController.continueWithGoogle(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _authController.isGoogleLoading.value
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF00B4F0),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(22, 22),
                                  painter: _GoogleLogoPainter(),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1C2228),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 6. Dark Slate Pill Button: "Sign up with Email"
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Get.to(() => const SignupScreen()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B242C),
                      foregroundColor: const Color(0xFF29B6F6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Sign up with Email',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF29B6F6),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 7. Footer: Terms of Service & Privacy Policy
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      color: Color(0xFF8E99A4),
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: const TextStyle(
                          color: Color(0xFF29B6F6),
                          fontWeight: FontWeight.w500,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = () {},
                      ),
                      const TextSpan(text: ' and\n'),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: const TextStyle(
                          color: Color(0xFF29B6F6),
                          fontWeight: FontWeight.w500,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = () {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom STEPTRACK Logo with Glowing Cyan Heartbeat Peak forming the 'A'
class _StepTrackPulseLogo extends StatelessWidget {
  const _StepTrackPulseLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glowing Cyan Pulse Underline + Peak for 'A'
          CustomPaint(
            size: const Size(255, 56),
            painter: _LogoPulsePainter(),
          ),
          // Letters: STEPTR [pulse A] CK
          Positioned(
            top: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'STEPTR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(width: 28), // Space where the cyan pulse forms 'A'
                Text(
                  'CK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoPulsePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = const Color(0xFF00D2FF).withOpacity(0.45)
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final linePaint = Paint()
      ..color = const Color(0xFF00D2FF)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(8, 42)
      ..lineTo(148, 42)
      ..lineTo(154, 49)
      ..lineTo(168, 12) // High peak forming the 'A'
      ..lineTo(181, 53) // Deep dip
      ..lineTo(188, 42)
      ..lineTo(246, 42);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Community Circular Avatar with Colored Ring & Glow
class _CommunityAvatar extends StatelessWidget {
  final Color ringColor;
  final Color avatarBg;
  final IconData icon;
  final Color iconColor;

  const _CommunityAvatar({
    required this.ringColor,
    required this.avatarBg,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        color: avatarBg,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: ringColor.withOpacity(0.45),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(icon, color: iconColor, size: 28),
    );
  }
}

/// Dotted World Map & 3 Glowing Curved Trails Painter
class _WorldMapAndTrailsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    // World map continent grid approximation
    const rows = 22;
    const cols = 38;
    final dx = size.width / cols;
    final dy = size.height / rows;

    for (int r = 2; r < rows - 2; r++) {
      for (int c = 2; c < cols - 2; c++) {
        if (_isContinentDot(r, c)) {
          canvas.drawCircle(Offset(c * dx, r * dy), 2.1, dotPaint);
        }
      }
    }

    // 1. Cyan Trail
    _drawGlowingTrail(
      canvas,
      size,
      const Color(0xFF00D8FF),
      Path()
        ..moveTo(45, 132)
        ..quadraticBezierTo(135, 118, 222, 32),
    );

    // 2. Purple Trail
    _drawGlowingTrail(
      canvas,
      size,
      const Color(0xFF9B51E0),
      Path()
        ..moveTo(52, 148)
        ..quadraticBezierTo(140, 146, 204, 104),
    );

    // 3. Green Trail
    _drawGlowingTrail(
      canvas,
      size,
      const Color(0xFF4CD964),
      Path()
        ..moveTo(78, 178)
        ..quadraticBezierTo(165, 174, 245, 148),
    );
  }

  void _drawGlowingTrail(
      Canvas canvas, Size size, Color color, Path path) {
    final glow = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.0), color.withOpacity(0.55)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final stroke = Paint()
      ..shader = LinearGradient(
        colors: [color.withOpacity(0.05), color],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 6.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, glow);
    canvas.drawPath(path, stroke);
  }

  bool _isContinentDot(int r, int c) {
    // North America
    if (r >= 4 && r <= 10 && c >= 4 && c <= 13 && (r + c) % 1 == 0) {
      if (r == 4 && (c < 7 || c > 11)) return false;
      if (r == 10 && c > 9) return false;
      return true;
    }
    // South America
    if (r >= 12 && r <= 18 && c >= 10 && c <= 15) {
      if (r >= 16 && c > 13) return false;
      return true;
    }
    // Europe & Africa
    if (r >= 4 && r <= 17 && c >= 18 && c <= 25) {
      if (r >= 11 && c < 19) return false;
      if (r >= 15 && c > 23) return false;
      return true;
    }
    // Asia & Australia
    if (r >= 5 && r <= 16 && c >= 25 && c <= 34) {
      if (r >= 12 && r <= 13 && c >= 27) return false;
      if (r >= 14 && (c < 29 || c > 33)) return false;
      return true;
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Multi-Color Google 'G' Icon Painter
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 4.2;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Blue arc
    canvas.drawArc(
      rect,
      -0.4,
      1.6,
      false,
      Paint()
        ..color = const Color(0xFF4285F4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    // Green arc
    canvas.drawArc(
      rect,
      1.2,
      1.2,
      false,
      Paint()
        ..color = const Color(0xFF34A853)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    // Yellow arc
    canvas.drawArc(
      rect,
      2.4,
      1.1,
      false,
      Paint()
        ..color = const Color(0xFFFBBC05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    // Red arc
    canvas.drawArc(
      rect,
      3.5,
      1.6,
      false,
      Paint()
        ..color = const Color(0xFFEA4335)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Blue horizontal bar
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(size.width - 1, center.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}