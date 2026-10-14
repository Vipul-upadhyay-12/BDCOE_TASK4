import 'dart:convert';
import 'package:http/http.dart' as http;
import 'local_processing_service.dart';

class LocalPipelineApiService {
  static const String baseUrl = "https://bdcoe-task4-1.onrender.com";

  static Future<Map<String, dynamic>> sendExtractedData({
    required LocalProcessingResult result,
    required int numQuestions,
    required String difficulty,
    String? customPrompt,
  }) async {
    final uri = Uri.parse("$baseUrl/generate-quiz");
    final request = http.MultipartRequest("POST", uri);

    // Form metadata
    request.fields['num_questions'] = numQuestions.toString();
    request.fields['difficulty'] = difficulty;
    if (customPrompt != null && customPrompt.isNotEmpty) {
      request.fields['custom_prompt'] = customPrompt;
    }

    bool hasPayload = false;

    // 1. Attach on-screen visual/OCR text (PDFs, plain text, or sampled video frames)
    if (result.extractedText != null && result.extractedText!.trim().isNotEmpty) {
      request.fields['text'] = result.extractedText!.trim();
      hasPayload = true;
    }

    // 2. Attach media/audio stream (Standalone audio or video-extracted audio)
    if (result.processedAudio != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio_file',
          result.processedAudio!.path,
        ),
      );
      hasPayload = true;
    }

    if (!hasPayload) {
      throw Exception("No valid content found to send to the backend.");
    }

    // Increased to 90s to allow Whisper transcription + LLM synthesis on Render
    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Backend error [${response.statusCode}]: ${response.body}");
    }
  }
}