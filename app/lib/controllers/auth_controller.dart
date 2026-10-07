import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes/app_pages.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Login inputs
  late final TextEditingController loginEmailController;
  late final TextEditingController loginPasswordController;

  // Register inputs
  late final TextEditingController registerEmailController;
  late final TextEditingController registerContactController;
  late final TextEditingController registerPasswordController;
  late final TextEditingController registerConfirmPasswordController;

  // Reactive state
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loginEmailController = TextEditingController();
    loginPasswordController = TextEditingController();
    registerEmailController = TextEditingController();
    registerContactController = TextEditingController();
    registerPasswordController = TextEditingController();
    registerConfirmPasswordController = TextEditingController();
  }

  // --- Login Action ---
  Future<void> login() async {
    final email = loginEmailController.text.trim();
    final password = loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Required',
        'Please provide both email and password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Get.snackbar(
        'Success',
        'Logged in successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      // Get.offAllNamed(Routes.HOME);
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Login Failed',
        e.message ?? 'An error occurred during authentication',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // --- Register Action ---
  Future<void> register() async {
    final email = registerEmailController.text.trim();
    final contact = registerContactController.text.trim();
    final password = registerPasswordController.text.trim();
    final confirmPassword = registerConfirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      Get.snackbar(
        'Required',
        'Please fill in all mandatory fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    if (password != confirmPassword) {
      Get.snackbar(
        'Validation Error',
        'Passwords do not match',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      // NOTE: Store extra fields like contact number in Firestore/Supabase here if needed
      Get.snackbar(
        'Success',
        'Account created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      // Get.offAllNamed(Routes.HOME);
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Registration Failed',
        e.message ?? 'Could not create account',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    registerEmailController.dispose();
    registerContactController.dispose();
    registerPasswordController.dispose();
    registerConfirmPasswordController.dispose();
    super.onClose();
  }
}