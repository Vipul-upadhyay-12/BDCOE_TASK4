import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

    Future<void> signInWithGoogle() async {
      try {
        isLoading.value = true;

        // 1. Trigger the Google Authentication flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        // If user cancels the prompt
        if (googleUser == null) {
          isLoading.value = false;
          return;
        }

        // 2. Obtain auth details
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // 3. Create a credential for Firebase
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // 4. Sign in to Firebase with the credential
        final UserCredential userCredential = await _auth.signInWithCredential(credential);

        Get.snackbar(
          'Success',
          'Signed in as ${userCredential.user?.displayName ?? "User"}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        // 5. Navigate to your app's home or dashboard
        // Get.offAllNamed(Routes.HOME);

      } on FirebaseAuthException catch (e) {
        Get.snackbar(
          'Authentication Error',
          e.message ?? 'Failed to sign in with Google',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          e.toString(),
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        isLoading.value = false;
      }
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