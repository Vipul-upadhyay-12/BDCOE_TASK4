import 'package:app/controllers/file_processing_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class fileUpload extends StatelessWidget {
  fileUpload({super.key});
  final controller = Get.find(FileProcessingController());
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff181818),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xffffd000), size: 24),
                    onPressed: () => Get.back(),
                  ),
                  const Text(
                    'ToolForge',
                    style: TextStyle(
                      color: Color(0xffffd000),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const Text(
                'Choose a feature to compose\nfrom the file\'s content',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xffF5C700),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 28),

              GestureDetector(
                onTap: controller.pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xff242424),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xffF5C700),
                      width: 2.5,
                    ),
                  ),
                  child: Center(
                    child: Obx(() => Text(
                      controller.fileName.value,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xffffcce9),
                        fontWeight: FontWeight.w500,
                      ),
                    )),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/long.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Generate',
                style: TextStyle(
                  color: Color(0xffffd000),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),

              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 12.0;
                  final itemWidth = (constraints.maxWidth - (gap * 2)) / 3;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFeatureCard('assets/quiz.png', itemWidth, controller.onQuizTapped),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              const Text(
                'Video, Audio and Text files supported\nspecific- mp4, mp3, txt, pdf\nMax. Size: 28 Mb',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xffffcce9),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String assetPath, double width, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}