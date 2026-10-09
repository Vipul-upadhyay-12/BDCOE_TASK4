import 'package:app/screens/quiz_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/quiz_screen_controller.dart';
import '../widgets/quiz_question_card.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xff121214),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header[cite: 2]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Color(0xfff5c700), size: 28),
                    onPressed: () => Get.back(),
                  ),
                  const Text(
                    'ToolForge',
                    style: TextStyle(
                      color: Color(0xfff5c700),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    children: [
                      // Golden Banner with Title & Time Info[cite: 2]
                      Container(
                        padding: const EdgeInsets.all(18),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xfff5c700), Color(0xff8a6a00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Quiz',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(color: Colors.white38, thickness: 1.2),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Obx(() => Text(
                                      'Max Marks: ${controller.questions.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )),
                                Text(
                                  'Time: $timerMinutes min',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Repeatable Question Cards[cite: 2]
                      Obx(() => Column(
                            children: List.generate(
                              controller.questions.length,
                              (idx) => QuizQuestionCard(
                                index: idx,
                                question: controller.questions[idx],
                              ),
                            ),
                          )),
                    ],
                  ),

                  // Floating Stat Bar matching the yellow bar in the Figma screenshot[cite: 2]
                  Positioned(
                    bottom: 74,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xfff5c700),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 8,
                            offset: Offset(0, -2),
                          )
                        ],
                      ),
                      child: Obx(() => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatColumn('Tried', '${controller.triedCount}'),
                              _buildStatColumn('Marked', '${controller.markedCount}'),
                              _buildStatColumn('Untried', '${controller.untriedCount}'),
                              _buildStatColumn('Timer', controller.formattedTimer),
                              const Icon(Icons.more_vert, color: Colors.black),
                            ],
                          )),
                    ),
                  ),

                  // Bottom Yellow Submit Button[cite: 2]
                  Positioned(
                    bottom: 12,
                    left: 20,
                    right: 20,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xfff5c700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                        onPressed: () => _showSubmissionDialog(context, controller),
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            color: Colors.black,
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

  void _showSubmissionDialog(BuildContext context, QuizScreenController controller) {
    final score = controller.calculateScore();
    final total = controller.questions.length;

    void _showSubmissionDialog(BuildContext context, QuizScreenController controller) {
      Get.to(() => QuizResultScreen(
        questions: controller.questions,
        userAnswers: controller.selectedAnswers,
        notes: quizData['notes'] ?? '', // use `quizData` directly if StatelessWidget, or `widget.quizData` if StatefulWidget
      ));
    }

    Get.defaultDialog(
      title: 'Quiz Finished!',
      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      backgroundColor: const Color(0xff222222),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(
              'Your Score: $score / $total',
              style: const TextStyle(color: Color(0xfff5c700), fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Attempted: ${controller.triedCount} | Untried: ${controller.untriedCount}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
      textConfirm: 'Review / Exit',
      confirmTextColor: Colors.black,
      buttonColor: const Color(0xfff5c700),
      onConfirm: () {
        Get.back(); // close dialog
        Get.back(); // exit to home
      },
    );
  }
}