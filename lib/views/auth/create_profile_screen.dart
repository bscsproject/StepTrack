import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_track/controller/auth_controller.dart';


class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _authController.profileName.value);
    _descController =
        TextEditingController(text: _authController.profileDescription.value);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            children: [
              // Top Bar: Centered "Create Profile" + Right "Continue"
              SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      'Create Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Obx(
                        () => GestureDetector(
                          onTap: _authController.isLoading.value
                              ? null
                              : () => _authController.saveProfileAndGoWelcome(
                                    name: _nameController.text,
                                    description: _descController.text,
                                  ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              color: Color(0xFF8C8C8C),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Double-ring Avatar Preview
              Obx(() {
                final color = _authController
                    .avatarColors[_authController.selectedColorIndex.value];
                return Container(
                  width: 146,
                  height: 146,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 3.5),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),

              const SizedBox(height: 18),

              const Text(
                'Edit Avatar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),

              // Shuffle Icon + Color Palette Swatches
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _authController.shuffleAvatarColor,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.shuffle,
                          color: Color(0xFFFF4DA6),
                          size: 18,
                        ),
                      ),
                    ),
                    ...List.generate(_authController.avatarColors.length, (i) {
                      final color = _authController.avatarColors[i];
                      final isSelected =
                          _authController.selectedColorIndex.value == i;
                      return GestureDetector(
                        onTap: () => _authController.selectAvatarColor(i),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Combined Name + Description Card
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF262626),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Name',
                        hintStyle: TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFF363636),
                      indent: 16,
                      endIndent: 16,
                    ),
                    TextField(
                      controller: _descController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Description',
                        hintStyle: TextStyle(
                          color: Color(0xFF757575),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}