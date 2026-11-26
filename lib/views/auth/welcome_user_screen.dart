import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/controller/auth_controller.dart';


class WelcomeUserScreen extends StatelessWidget {
  const WelcomeUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'Welcome!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(flex: 2),

              // Initial Circle + Name + Edit Profile
              Obx(() {
                final name = authController.profileName.value.trim().isEmpty
                    ? 'User'
                    : authController.profileName.value.trim();
                final initial = name[0].toUpperCase();
                final color = authController
                    .avatarColors[authController.selectedColorIndex.value];

                return Column(
                  children: [
                    Container(
                      width: 152,
                      height: 152,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 64,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Color(0xFF00B4F0),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              }),

              const Spacer(flex: 3),

              // Subscribe to Newsletter Card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subscribe to Newsletter',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Obx(
                      () => Switch(
                        value: authController.subscribeNewsletter.value,
                        activeColor: const Color(0xFF050505),
                        activeTrackColor: const Color(0xFF00C2FF),
                        onChanged: (val) =>
                            authController.subscribeNewsletter.value = val,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'I want to hear about new apps, offers and\npromos. No spam, promise!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6E6E6E),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // Cyan Continue Button -> OnboardingScreen
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: authController.isLoading.value
                        ? null
                        : () => authController.completeWelcomeToOnboarding(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C2FF),
                      foregroundColor: const Color(0xFF050505),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: authController.isLoading.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}