import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxString username = "".obs;
  final RxString email = "".obs;
  final RxString phoneNumber = "-".obs;
  final RxString recoveryEmail = "-".obs;
  final RxInt quizzesMade = 0.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    isLoading.value = true;
    final user = _auth.currentUser;

    if (user != null) {
      email.value = user.email ?? "No Email";
      
      // Determine display name
      if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
        username.value = user.displayName!;
      } else if (user.email != null && user.email!.contains('@')) {
        final prefix = user.email!.split('@').first;
        username.value = prefix[0].toUpperCase() + prefix.substring(1);
      } else {
        username.value = "Learner";
      }

      // Fetch extra fields and quiz count from Firestore
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          if (data['name'] != null && data['name'].toString().isNotEmpty) {
            username.value = data['name'];
          }
          phoneNumber.value = data['phoneNumber'] ?? user.phoneNumber ?? "-";
          recoveryEmail.value = data['recoveryEmail'] ?? "-";
        }

        // Count total quizzes created by this user
        final quizSnapshot = await _firestore
            .collection('quizzes')
            .where('userId', isEqualTo: user.uid)
            .get();
        quizzesMade.value = quizSnapshot.docs.length;
      } catch (e) {
        print(">>> Firestore read warning: $e");
      }
    }

    isLoading.value = false;
  }

  Future<void> updateUserData({required String newName, required String newPhone}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 1. Update Firebase Auth Profile
      await user.updateDisplayName(newName.trim());
      await user.reload();

      // 2. Persist in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'name': newName.trim(),
        'phoneNumber': newPhone.trim(),
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      username.value = newName.trim();
      phoneNumber.value = newPhone.trim().isEmpty ? "-" : newPhone.trim();

      Get.back(); // close dialog
      Get.snackbar(
        "Success",
        "Profile updated successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xff242424),
        colorText: const Color(0xffffd000),
      );
    } catch (e) {
      Get.snackbar(
        "Update Failed",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xff242424),
        colorText: Colors.redAccent,
      );
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
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }
}