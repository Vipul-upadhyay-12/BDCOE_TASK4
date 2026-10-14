import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/local_processing_service.dart';
import '../services/local_pipeline_api_service.dart';
import '../screens/quiz_screen.dart';
import '../services/storage_service.dart';

class OptimizedQuizController extends GetxController {
  final LocalProcessingService _localService = LocalProcessingService();

  var selectedFile = Rxn<File>();
  var numQuestions = 5.obs;
  var difficulty = 'Medium'.obs;
  var customPrompt = ''.obs;

  var isProcessing = false.obs;
  var mainStatus = ''.obs;
  var subStatus = ''.obs;

  void setFile(File file) {
    selectedFile.value = file;
  }

  Future<void> startGenerationPipeline() async {
    if (selectedFile.value == null) {
      Get.snackbar(
        'File Missing',
        'Please select a file first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isProcessing.value = true;
    
    // --- STAGE 1: LOCAL EXTRACTION ---
    mainStatus.value = "Processing upload...";
    subStatus.value = "Extracting content locally on your device";

    Get.dialog(
      PopScope(
        canPop: false,
        child: Obx(
          () => AlertDialog(
            backgroundColor: const Color(0xFF222222),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xffffd000), width: 1.5),
            ),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xffffd000)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    mainStatus.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subStatus.value,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      // 1. Run local extraction
      final localResult = await _localService.processFile(selectedFile.value!);

      // --- STAGE 2: BACKEND GENERATION ---
      mainStatus.value = "Generating output...";
      subStatus.value = "Groq LPU is synthesizing notes & quiz questions";

      // 2. Transmit to backend
      final responseData = await LocalPipelineApiService.sendExtractedData(
        result: localResult,
        numQuestions: numQuestions.value,
        difficulty: difficulty.value,
        customPrompt: customPrompt.value.isEmpty ? null : customPrompt.value,
      );

      // Save locally
      try {
        await StorageService.saveSession(
          title: responseData['title'] ?? 'Study Notes & Quiz',
          notes: responseData['notes'] ?? '',
          quizData: responseData,
        );
      } catch (_) {}

      // Close modal
      if (Get.isDialogOpen ?? false) Get.back();
      isProcessing.value = false;

      // Navigate to Quiz
      Get.to(() => QuizScreen(
            quizData: responseData,
            timerMinutes: 10,
          ));
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      isProcessing.value = false;

      Get.snackbar(
        'Generation Failed',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  void onClose() {
    _localService.dispose();
    super.onClose();
  }
}