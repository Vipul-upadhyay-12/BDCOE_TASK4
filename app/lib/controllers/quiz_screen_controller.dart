import 'dart:async';
import 'package:get/get.dart';
import '../models/quiz_question.dart';

class QuizScreenController extends GetxController {
  final questions = <QuizQuestion>[].obs;
  
  // Maps question index -> selected option string
  final selectedAnswers = <int, String>{}.obs;
  // Set of question indices marked for review
  final markedQuestions = <int>{}.obs;

  final timerSeconds = (10 * 60).obs; // Default 10 minutes
  Timer? _timer;

  void initQuiz(Map<String, dynamic> quizData, int initialMinutes) {
    final rawList = (quizData['quiz'] ?? quizData['questions']) as List<dynamic>? ?? [];
    questions.value = rawList
        .asMap()
        .entries
        .map((entry) => QuizQuestion.fromJson(entry.value, entry.key + 1))
        .toList();

    timerSeconds.value = initialMinutes * 60;
    startTimer();
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timerSeconds.value > 0) {
        timerSeconds.value--;
      } else {
        t.cancel();
      }
    });
  }

  String get formattedTimer {
    final m = timerSeconds.value ~/ 60;
    final s = timerSeconds.value % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void selectOption(int questionIndex, String option) {
    // If already attempted, lock or allow re-selection (here we store the attempt)
    if (!selectedAnswers.containsKey(questionIndex)) {
      selectedAnswers[questionIndex] = option;
    }
  }

  void toggleMark(int questionIndex) {
    if (markedQuestions.contains(questionIndex)) {
      markedQuestions.remove(questionIndex);
    } else {
      markedQuestions.add(questionIndex);
    }
  }

  int get triedCount => selectedAnswers.length;
  int get markedCount => markedQuestions.length;
  int get untriedCount => (questions.length - selectedAnswers.length).clamp(0, questions.length);

  int calculateScore() {
    int score = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i].answer) {
        score++;
      }
    }
    return score;
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}