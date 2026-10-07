import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../routes/app_pages.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151515),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          children: [
            const SizedBox(height: 30),
            const Text(
              'Login',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 36),

            // Email Field
            TextFormField(
              controller: controller.loginEmailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Email Address'),
            ),
            const SizedBox(height: 18),

            // Password Field
            TextFormField(
              controller: controller.loginPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Password'),
            ),

            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[800])),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('or', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider(color: Colors.grey[800])),
              ],
            ),
            const SizedBox(height: 20),

            // Social Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Image.asset(
                      'assets/images/glogo.png',
                      height: 22,
                      width: 22,
                    ),
                    label: const Text('Google', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.amber),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.apple, color: Colors.white, size: 24),
                    label: const Text('Apple', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.amber),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // Reactive Submit Button with Obx
            Obx(
              () => ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Route to Register
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.REGISTER),
                  child: const Text(
                    'Sign-up',
                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}