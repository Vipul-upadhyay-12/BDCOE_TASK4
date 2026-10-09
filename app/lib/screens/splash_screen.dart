import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart'; // import your actual controller

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    // Registers the controller handling the 2-second timer & auth check
    Get.put(SplashController());

    return Scaffold(
      backgroundColor: const Color(0xFF151515),
      body: SizedBox.expand(
        child: SvgPicture.asset(
          'assets/splashbg.svg',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}