import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../screens/quiz_config_screen.dart';

class FileProcessingController extends GetxController {
  // Observables
  final RxString fileName = "Tap to choose a file".obs;
  final RxBool isProcessing = false.obs;

  // Stored File reference
  File? selectedFile;

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'txt', 'mp3', 'wav', 'm4a', 'aac', 'mp4', 'mkv', 'mov', 'webm'
        ],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final fileData = result.files.first;
      final rawPath = fileData.path;

      if (rawPath == null) {
        Get.snackbar(
          "Error",
          "Could not retrieve file path. Please try selecting the file again.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xff242424),
          colorText: Colors.redAccent,
        );
        return;
      }

      final picked = File(rawPath);
      if (!await picked.exists()) {
        Get.snackbar(
          "Error",
          "File does not exist or cannot be accessed.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xff242424),
          colorText: Colors.redAccent,
        );
        return;
      }

      // Robust extension extraction (handles Android null extension bug)
      String extension = (fileData.extension ?? '').toLowerCase();
      if (extension.isEmpty && rawPath.contains('.')) {
        extension = rawPath.split('.').last.toLowerCase();
      }
      if (extension.isEmpty && fileData.name.contains('.')) {
        extension = fileData.name.split('.').last.toLowerCase();
      }

      final isVideo = ['mp4', 'mkv', 'mov', 'webm'].contains(extension);
      final double maxAllowedMb = isVideo ? 160.0 : 25.0;

      final int fileSizeBytes = await picked.length();
      final double fileSizeMb = fileSizeBytes / (1024 * 1024);

      if (fileSizeMb > maxAllowedMb) {
        selectedFile = null;
        fileName.value = "Tap to choose a file";

        Get.snackbar(
          "File Too Large",
          isVideo
              ? "Video is ${fileSizeMb.toStringAsFixed(1)} MB. Max limit for video is 160 MB."
              : "File is ${fileSizeMb.toStringAsFixed(1)} MB. Max limit is 25 MB.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xff242424),
          colorText: const Color(0xffffd000),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Store verified file and update UI label
      selectedFile = picked;
      fileName.value = fileData.name;
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to pick file: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xff242424),
        colorText: Colors.redAccent,
      );
    }
  }

  void onQuizTapped() {
    if (selectedFile == null || !selectedFile!.existsSync()) {
      Get.snackbar(
        "No File Selected",
        "Please select a file first.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xff242424),
        colorText: const Color(0xffffd000),
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    print(">>> Proceeding with file: ${selectedFile!.path}");
    Get.to(() => QuizConfigScreen(file: selectedFile!));
  }
}