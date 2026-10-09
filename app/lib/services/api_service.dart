import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Replace with your actual Render deployment URL (no trailing slash)
  static const String baseUrl = 'https://bdcoe-task4-1.onrender.com/';

  /// Upload file and generate quiz or notes
  /// [taskType]: 'quiz' or 'notes'
  static Future<Map<String, dynamic>> processFile({
    required File file,
    required String taskType,
  }) async {
    final uri = Uri.parse('$baseUrl/generate');

    final request = http.MultipartRequest('POST', uri)
      ..fields['task_type'] = taskType
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Server error (${response.statusCode}): ${response.body}');
    }
  }

  /// Process via URL endpoint if needed
  static Future<Map<String, dynamic>> processUrl({
    required String url,
    required String taskType,
  }) async {
    final uri = Uri.parse('$baseUrl/process-url');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'url': url, 'task_type': taskType}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Server error (${response.statusCode}): ${response.body}');
    }
  }
}