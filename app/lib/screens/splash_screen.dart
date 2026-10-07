import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151515),
      body: SizedBox.expand(
        child: SvgPicture.asset(
          'assets/images/splashbg.svg',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}