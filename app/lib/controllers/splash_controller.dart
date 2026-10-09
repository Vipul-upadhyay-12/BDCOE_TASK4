import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home.dart';
import '../screens/login_screen.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _handleRouting();
  }

  Future<void> _handleRouting() async {
    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;
    debugPrint(">>> Splash auth check: User is ${user?.uid}");

    if (user != null) {
      debugPrint(">>> Going to HomeScreen directly");
      Get.offAll(() => HomeScreen());
    } else {
      debugPrint(">>> Going to LoginScreen directly");
      Get.offAll(() => const LoginView());
    }
  }
}