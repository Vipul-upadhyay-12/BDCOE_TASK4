import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../screens/quiz_config_screen.dart';

class FileProcessingController extends GetxController {
  var selectedFile = Rxn<File>();
  var fileName = 'No file selected'.obs;
  var isLoading = false.obs;

  // Pick file from device storage
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'mp3', 'mp4'],
    );

    if (result != null && result.files.single.path != null) {
      selectedFile.value = File(result.files.single.path!);
      fileName.value = result.files.single.name;
    }
  }

  // Handle Quiz Card Tap -> Goes to Configuration Screen
  void onQuizTapped() {
    if (selectedFile.value == null) {
      Get.snackbar(
        'File Required',
        'Please select a file first by tapping the file box.',
        backgroundColor: Colors.amber,
        colorText: Colors.black,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.to(() => QuizConfigScreen(file: selectedFile.value!));
  }

  // Trigger processing for Notes or Summaries
  Future<void> generateContent(String taskType) async {
    if (selectedFile.value == null) {
      Get.snackbar(
        'File Required',
        'Please select a file first by tapping the file box.',
        backgroundColor: Colors.amber,
        colorText: Colors.black,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(color: Color(0xffffd000)),
        ),
        barrierDismissible: false,
      );

      final data = await ApiService.processFile(
        file: selectedFile.value!,
        taskType: taskType,
      );

      Get.back();

      Get.snackbar(
        'Notes Ready',
        'Notes generated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Generation Failed',
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