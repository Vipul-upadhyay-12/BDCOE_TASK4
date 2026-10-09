import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SavedSession {
  final String id;
  final String title;
  final String date;
  final String notes;
  final Map<String, dynamic> quizData;

  SavedSession({
    required this.id,
    required this.title,
    required this.date,
    required this.notes,
    required this.quizData,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'date': date,
    'notes': notes,
    'quizData': quizData,
  };

  factory SavedSession.fromMap(Map<String, dynamic> map) => SavedSession(
    id: map['id'] ?? '',
    title: map['title'] ?? 'Untitled Session',
    date: map['date'] ?? '',
    notes: map['notes'] ?? '',
    quizData: Map<String, dynamic>.from(map['quizData'] ?? {}),
  );
}

class StorageService {
  static const String _key = 'saved_study_sessions';

  static Future<void> saveSession({
    required String title,
    required String notes,
    required Map<String, dynamic> quizData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existingList = await getSessions();

    final newSession = SavedSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.isNotEmpty ? title : 'Study Session ${DateTime.now().day}/${DateTime.now().month}',
      date: '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      notes: notes,
      quizData: quizData,
    );

    existingList.insert(0, newSession);

    final rawJsonList = existingList.map((s) => jsonEncode(s.toMap())).toList();
    await prefs.setStringList(_key, rawJsonList);
  }

  static Future<List<SavedSession>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_key) ?? [];
    return rawList.map((item) => SavedSession.fromMap(jsonDecode(item))).toList();
  }

  static Future<void> deleteSession(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getSessions();
    list.removeWhere((item) => item.id == id);
    final rawJsonList = list.map((s) => jsonEncode(s.toMap())).toList();
    await prefs.setStringList(_key, rawJsonList);
  }
}