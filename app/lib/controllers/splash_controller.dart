import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes/app_pages.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _handleRouting();
  }

  Future<void> _handleRouting() async {
    // 2-second delay for splash presentation
    await Future.delayed(const Duration(seconds: 2));

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // User is already signed in -> route to home/dashboard
      // Replace with Routes.HOME once built
      Get.offAllNamed(Routes.LOGIN);
    } else {
      Get.offAllNamed(Routes.LOGIN);
    }
  }
}