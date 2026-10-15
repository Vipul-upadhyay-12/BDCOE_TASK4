import 'package:app/screens/home.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});
  final ProfileController controller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff181818),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xffffd000)),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xffffd000),
                        size: 24,
                      ),
                      onPressed: () => Get.to(() => HomeScreen()),
                    ),
                    const Text(
                      'ToolForge',
                      style: TextStyle(
                        color: Color(0xffffd000),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // "Profile" Header with underline
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(
                        color: Color(0xffffcce9),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 105,
                      height: 2.5,
                      color: const Color(0xff555555),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Center Avatar with Yellow Ring
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xffffd000),
                            width: 3.5,
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 54,
                          backgroundColor: Color(0xff2a2a2a),
                          child: Icon(
                            Icons.person,
                            size: 68,
                            color: Color(0xff757575),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xff181818),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            size: 20,
                            color: Color(0xffffd000),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 1. Username (Editable)
                _buildField(
                  label: 'Username',
                  value: controller.username.value,
                  isEditable: true,
                  onTap: () => _showEditUsernameDialog(context),
                ),

                // 2. Email (Read-only)
                _buildField(
                  label: 'Email',
                  value: controller.email.value,
                  isEditable: false,
                ),

                const SizedBox(height: 12),

                // 3. Change Password Link
                GestureDetector(
                  onTap: () => controller.sendPasswordReset(),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Change Password',
                      style: TextStyle(
                        color: Color(0xffffd000),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String value,
    required bool isEditable,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xffffd000),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isEditable) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.edit, color: Color(0x66ffffff), size: 15),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUsernameDialog(BuildContext context) {
    final textController = TextEditingController(text: controller.username.value);

    Get.defaultDialog(
      title: "Edit Username",
      titleStyle: const TextStyle(
        color: Color(0xffffd000),
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      backgroundColor: const Color(0xff242424),
      radius: 14,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      content: TextField(
        controller: textController,
        autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: const InputDecoration(
          hintText: "Enter your name",
          hintStyle: TextStyle(color: Colors.white38),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xffffd000)),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xffffd000), width: 2),
          ),
        ),
      ),
      textConfirm: "Save",
      confirmTextColor: Colors.black,
      buttonColor: const Color(0xffffd000),
      textCancel: "Cancel",
      cancelTextColor: const Color(0xffffcce9),
      onConfirm: () => controller.updateUsername(textController.text),
    );
  }
}