import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxString username = "".obs;
  final RxString email = "".obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  void loadUserProfile() {
    isLoading.value = true;
    final user = _auth.currentUser;

    if (user != null) {
      email.value = user.email ?? "No Email";

      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        username.value = user.displayName!;
      } else if (user.email != null && user.email!.contains('@')) {
        final prefix = user.email!.split('@').first;
        username.value = prefix[0].toUpperCase() + prefix.substring(1);
      } else {
        username.value = "Learner";
      }
    }

    isLoading.value = false;
  }

  Future<void> updateUsername(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.updateDisplayName(trimmed);
        await user.reload();
        username.value = trimmed;

        Get.back(); // close dialog
        Get.snackbar(
          "Success",
          "Username updated to $trimmed",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xff242424),
          colorText: const Color(0xffffd000),
          margin: const EdgeInsets.all(16),
        );
      } catch (e) {
        Get.snackbar(
          "Update Failed",
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xff242424),
          colorText: Colors.redAccent,
          margin: const EdgeInsets.all(16),
        );
      }
    }
  }

  Future<void> sendPasswordReset() async {
    if (email.value.isEmpty || email.value == "No Email") return;

    try {
      await _auth.sendPasswordResetEmail(email: email.value);
      Get.snackbar(
        "Reset Link Sent",
        "A password reset link has been sent to ${email.value}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xff242424),
        colorText: const Color(0xffffd000),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xff242424),
        colorText: Colors.redAccent,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}