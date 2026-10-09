import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/quiz_question.dart';
import '../controllers/quiz_screen_controller.dart';

class QuizQuestionCard extends StatelessWidget {
  final int index;
  final QuizQuestion question;

  const QuizQuestionCard({
    super.key,
    required this.index,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuizScreenController>();

    return Obx(() {
      final selected = controller.selectedAnswers[index];
      final isAttempted = selected != null;

      return Container(
        margin: const EdgeInsets.only(bottom: 22),
        decoration: BoxDecoration(
          color: const Color(0xff1f1f23),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xfff5c700),
            width: 1.6,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Question badge at the top-left (cutout effect matching Figma)
            Positioned(
              top: -1,
              left: -1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: const BoxDecoration(
                  color: Color(0xfff5c700),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  '${index + 1}.',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 38, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question statement
                  Text(
                    question.question,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option rows[cite: 2]
                  ...question.options.map((option) {
                    final isThisOptionChosen = selected == option;
                    final isCorrect = option == question.answer;

                    Color boxBg = const Color(0xff2b2b30);
                    Color borderColor = Colors.white24;
                    Widget? trailingIcon;

                    if (isAttempted) {
                      if (isCorrect) {
                        boxBg = const Color(0xff1b3e2b);
                        borderColor = Colors.greenAccent;
                        trailingIcon = const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20);
                      } else if (isThisOptionChosen) {
                        boxBg = const Color(0xff442020);
                        borderColor = Colors.redAccent;
                        trailingIcon = const Icon(Icons.cancel, color: Colors.redAccent, size: 20);
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => controller.selectOption(index, option),
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: boxBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor, width: 1.2),
                          ),
                          child: Row(
                            children: [
                              // Square checkbox indicator matching design[cite: 2]
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: isThisOptionChosen ? const Color(0xfff5c700) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isThisOptionChosen ? const Color(0xfff5c700) : Colors.white54,
                                    width: 1.6,
                                  ),
                                ),
                                child: isThisOptionChosen
                                    ? const Icon(Icons.check, size: 14, color: Colors.black)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (trailingIcon != null) trailingIcon,
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}