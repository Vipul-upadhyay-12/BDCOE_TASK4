import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/quiz_screen_controller.dart';
import '../widgets/quiz_question_card.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatelessWidget {
  final Map<String, dynamic> quizData;
  final int timerMinutes;

  const QuizScreen({
    super.key,
    required this.quizData,
    this.timerMinutes = 10,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(QuizScreenController());
    controller.initQuiz(quizData, timerMinutes);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xff181818),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xffffd000), size: 28),
                    onPressed: () => Get.back(),
                  ),
                  const Text(
                    'ToolForge',
                    style: TextStyle(
                      color: Color(0xffffd000),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 28),
                ],
              ),
            ),

            // Scrollable Question List
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Top Row: "Quiz" on left, Lamp image on right
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: "Quiz" title with underline
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quiz',
                              style: TextStyle(
                                color: Color(0xffffcce9),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 80,
                              height: 2,
                              color: const Color(0xff555555),
                            ),
                          ],
                        ),

                        // Right: Lamp image scaled to ~48% screen width
                        SizedBox(
                          width: screenWidth * 0.48,
                          child: Image.asset(
                            'assets/lamp.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 2. Stats Row: Max Marks & Time locked to the EXACT same horizontal baseline
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left: "Max" above "Marks: X"
                        Obx(
                          () => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Max',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              Text(
                                'Marks: ${controller.questions.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right: "Time: X min"
                        Text(
                          'Time: $timerMinutes min',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Repeatable Question Cards
                    Obx(
                      () => Column(
                        children: List.generate(
                          controller.questions.length,
                          (idx) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: QuizQuestionCard(
                              index: idx,
                              question: controller.questions[idx],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Submit Button at bottom of questions
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffffd000),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          onPressed: () => _handleSubmit(context, controller),
                          child: const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Persistent Floating Stats Bar docked at bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xffffd000),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 6,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('Tried', '${controller.triedCount}'),
                    _buildStatColumn('Marked', '${controller.markedCount}'),
                    _buildStatColumn('Untried', '${controller.untriedCount}'),
                    _buildStatColumn('Timer', controller.formattedTimer),
                    const Icon(Icons.more_vert, color: Colors.black, size: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _handleSubmit(BuildContext context, QuizScreenController controller) {
    final total = controller.questions.length;

    Get.defaultDialog(
      title: 'Submit Quiz?',
      titleStyle: const TextStyle(color: Color(0xffffd000), fontWeight: FontWeight.bold),
      backgroundColor: const Color(0xff242424),
      radius: 14,
      contentPadding: const EdgeInsets.all(16),
      content: Text(
        'You have attempted ${controller.triedCount} of $total questions.\nDo you want to submit and see results?',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      textConfirm: 'Submit',
      confirmTextColor: Colors.black,
      buttonColor: const Color(0xffffd000),
      textCancel: 'Keep Going',
      cancelTextColor: const Color(0xffffcce9),
      onConfirm: () {
        Get.back();
        Get.off(
          () => QuizResultScreen(
            questions: controller.questions,
            userAnswers: controller.selectedAnswers,
            notes: quizData['notes'] ?? '',
          ),
        );
      },
    );
  }
}