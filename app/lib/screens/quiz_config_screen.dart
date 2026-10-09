import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class QuizConfigScreen extends StatefulWidget {
  final File file;

  const QuizConfigScreen({super.key, required this.file});

  @override
  State<QuizConfigScreen> createState() => _QuizConfigScreenState();
}

class _QuizConfigScreenState extends State<QuizConfigScreen> {
  // Config state
  String structure = 'Multiple Choice Questions';
  String content = 'Mixed';
  String difficulty = 'Medium';
  int numQuestions = 5;
  int timerMinutes = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff181818),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Nav Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.menu, color: Color(0xffffd000), size: 30),
                    onPressed: () => Get.back(),
                  ),
                  const Text(
                    'ToolForge',
                    style: TextStyle(
                      color: Color(0xffffd000),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title and Character Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quiz',
                        style: TextStyle(
                          color: Color(0xffffcce9),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 130,
                        height: 2,
                        color: const Color(0xff9b7d8e),
                      ),
                    ],
                  ),
                  Image.asset(
                    'assets/card.png',
                    height: 85,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Structure Card
              _buildSectionBox(
                title: 'Structure',
                child: Column(
                  children: [
                    _buildOptionRow('Multiple Choice Questions', structure, (v) => setState(() => structure = v)),
                    _buildOptionRow('True/False', structure, (v) => setState(() => structure = v)),
                    _buildOptionRow('Subjective', structure, (v) => setState(() => structure = v)),
                  ],
                ),
              ),

              // 2. Content Card
              _buildSectionBox(
                title: 'Content',
                child: Column(
                  children: [
                    _buildOptionRow('Topic Wise', content, (v) => setState(() => content = v)),
                    _buildOptionRow('Mixed', content, (v) => setState(() => content = v)),
                  ],
                ),
              ),

              // 3. Difficulty Level Card
              _buildSectionBox(
                title: 'Difficulty Level',
                child: Column(
                  children: [
                    _buildOptionRow('Easy', difficulty, (v) => setState(() => difficulty = v)),
                    _buildOptionRow('Medium', difficulty, (v) => setState(() => difficulty = v)),
                    _buildOptionRow('Hard', difficulty, (v) => setState(() => difficulty = v)),
                  ],
                ),
              ),

              // 4. Number of Questions Card
              _buildSectionBox(
                title: 'Number of Questions',
                child: _buildGridOptions(
                  values: const [5, 10, 20, 30, 45, 60],
                  selectedValue: numQuestions,
                  onSelect: (v) => setState(() => numQuestions = v),
                  suffix: '',
                ),
              ),

              // 5. Timer Card
              _buildSectionBox(
                title: 'Timer',
                child: _buildGridOptions(
                  values: const [5, 10, 20, 30, 45, 60],
                  selectedValue: timerMinutes,
                  onSelect: (v) => setState(() => timerMinutes = v),
                  suffix: ' min',
                ),
              ),
              const SizedBox(height: 12),

              // Generate Action Button
              ElevatedButton(
                onPressed: () {
                  // We will plug in the fun facts loading screen here next!
                  Get.snackbar(
                    'Config Selected',
                    '$numQuestions Questions | $timerMinutes min | $difficulty',
                    backgroundColor: const Color(0xffffd000),
                    colorText: Colors.black,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xfff5c700),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Generate',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionBox({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff222222),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffffd000), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildOptionRow(String label, String groupValue, Function(String) onSelect) {
    final isSelected = label == groupValue;
    return GestureDetector(
      onTap: () => onSelect(label),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xffffd000) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white70, width: 1.5),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridOptions({
    required List<int> values,
    required int selectedValue,
    required Function(int) onSelect,
    required String suffix,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 4.0,
      children: values.map((val) {
        final isSelected = selectedValue == val;
        return GestureDetector(
          onTap: () => onSelect(val),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xffffd000) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white70, width: 1.5),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.black)
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                '$val$suffix',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}