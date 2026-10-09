class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final String answer;
  final String? explanation;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json, int fallbackIndex) {
    return QuizQuestion(
      id: json['id'] is int ? json['id'] : fallbackIndex,
      question: json['question'] ?? '',
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      answer: json['answer'] ?? json['correct_answer'] ?? '',
      explanation: json['explanation'],
    );
  }
}