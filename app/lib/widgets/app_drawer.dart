import 'package:app/routes/app_pages.dart';
import 'package:app/screens/login_Screen.dart';
import 'package:app/services/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/library_screen.dart'; // We'll link this next

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xff18181a),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              const Text(
                'ToolForge',
                style: TextStyle(
                  color: Color(0xfff5c700),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white12, thickness: 1),
              const SizedBox(height: 28),

              // Nav Items
              _drawerItem(
                label: 'Home',
                color: const Color(0xfff5c700),
                onTap: () => Get.back(),
              ),
              const SizedBox(height: 20),

              _drawerItem(
                label: 'Library',
                color: Colors.white,
                onTap: () {
                  Get.back();
                  Get.to(() => const LibraryScreen());
                },
              ),
              const SizedBox(height: 20),

              _drawerItem(
                label: 'Profile',
                color: Colors.white,
                onTap: () => Get.back(),
              ),
              const SizedBox(height: 20),

              _drawerItem(
                label: 'Settings',
                color: Colors.white,
                onTap: () => Get.back(),
              ),
              const SizedBox(height: 20),

              _drawerItem(
                label: 'Contact us',
                color: Colors.white,
                onTap: () => Get.back(),
              ),

              const Spacer(),

              // Red Logout at Bottom matching design
              InkWell(
                onTap: () async {
    
                  await StorageService.clearAllData();

                  // 2. Sign out of Firebase Auth
                  await FirebaseAuth.instance.signOut();

                  // 3. Clear GetX navigation stack and redirect to Login
                  Get.offAllNamed(Routes.LOGIN);
                },
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent, size: 24),
                    SizedBox(width: 16),
                    Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem({required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}