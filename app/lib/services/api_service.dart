import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Your deployed or local backend URL
  static const String baseUrl = 'https://bdcoe-task4.onrender.com';

  /// General file processing for notes/summaries
  static Future<Map<String, dynamic>> processFile({
    required File file,
    required String taskType,
  }) async {
    final uri = Uri.parse('$baseUrl/generate-quiz');
    final request = http.MultipartRequest('POST', uri);

    request.fields['num_questions'] = '5';
    request.fields['difficulty'] = 'Medium';
    request.fields['custom_prompt'] = 'Task: $taskType. Focus on generating detailed study notes.';

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Server error (${response.statusCode}): ${response.body}');
    }
  }

  /// Specialized quiz generation with full configuration options
  static Future<Map<String, dynamic>> generateQuiz({
    required File file,
    required int numQuestions,
    required String difficulty,
    String? customPrompt,
  }) async {
    final uri = Uri.parse('$baseUrl/generate-quiz');
    final request = http.MultipartRequest('POST', uri);

    request.fields['num_questions'] = numQuestions.toString();
    request.fields['difficulty'] = difficulty;
    if (customPrompt != null && customPrompt.trim().isNotEmpty) {
      request.fields['custom_prompt'] = customPrompt.trim();
    }

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Server error (${response.statusCode}): ${response.body}');
    }
  }
}