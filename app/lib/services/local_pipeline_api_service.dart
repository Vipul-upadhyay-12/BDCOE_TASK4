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
    if (customPrompt != null && customPrompt.trim().isNotEmpty) {
      request.fields['custom_prompt'] = customPrompt.trim();
    }

    bool hasPayload = false;

    // 1. Attach extracted .txt file (PDF syllabus/content or video slide OCR)
    if (result.textFile != null && await result.textFile!.exists()) {
      final int textSize = await result.textFile!.length();
      if (textSize > 0) {
        request.files.add(
          await http.MultipartFile.fromPath('text_file', result.textFile!.path),
        );
        hasPayload = true;
      }
    }

    // 2. Attach audio stream (Standalone audio or native demuxed video audio)
    if (result.processedAudio != null && await result.processedAudio!.exists()) {
      final int audioSize = await result.processedAudio!.length();
      if (audioSize > 0) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'audio_file',
            result.processedAudio!.path,
          ),
        );
        hasPayload = true;
      }
    }

    if (!hasPayload) {
      throw Exception("No valid content found to send to the backend.");
    }

    try {
      // 180s window accommodates Whisper transcription of 1hr+ audio plus LLM synthesis on Render
      final streamedResponse = await request.send().timeout(const Duration(seconds: 180));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        String serverDetail = response.body;
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson is Map && errorJson.containsKey("detail")) {
            serverDetail = errorJson["detail"].toString();
          }
        } catch (_) {}
        throw Exception("Backend error [${response.statusCode}]: $serverDetail");
      }
    } finally {
      // Cleanup transient extracted files from local app cache
      try {
        if (result.textFile != null && await result.textFile!.exists()) {
          await result.textFile!.delete();
        }
        if (result.processedAudio != null && await result.processedAudio!.exists()) {
          // Only delete if it was a generated/demuxed composite audio file, not user's original audio file
          if (result.fileType == 'video_composite') {
            await result.processedAudio!.delete();
          }
        }
      } catch (_) {}
    }
  }
}