import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/notes_screen.dart';
import '../services/storage_service.dart';
import 'quiz_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<SavedSession> sessions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => isLoading = true);
    final data = await StorageService.getSessions();
    setState(() {
      sessions = data;
      isLoading = false;
    });
  }

  Future<void> _deleteSession(String id) async {
    await StorageService.deleteSession(id);
    _loadSessions();
    Get.snackbar(
      'Deleted',
      'Session removed from Library',
      backgroundColor: const Color(0xff242424),
      colorText: const Color(0xffffd000),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xffffd000),
                      size: 24,
                    ),
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
                  const SizedBox(width: 24),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Top Header Row: Library on Left, Lamp Image on Right
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Library Header & Underline
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Library',
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
                            const SizedBox(height: 20),
                            const Text(
                              'Saved',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const Text(
                              'Quizzes',
                              style: TextStyle(
                                color: Color(0xffffd000),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),

                        // Right: Lamp Image (~48% width, sharp rendering)
                        SizedBox(
                          width: screenWidth * 0.48,
                          child: Image.asset(
                            'assets/quiz_config.png',
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            isAntiAlias: true,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 95,
                                decoration: BoxDecoration(
                                  color: const Color(0xff242424),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.menu_book_rounded,
                                  color: Color(0xffffd000),
                                  size: 36,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 2. Body: Loading / Empty / Loaded Sessions List
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(
                          child: CircularProgressIndicator(color: Color(0xffffd000)),
                        ),
                      )
                    else if (sessions.isEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 40),
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: const Color(0xff222222),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xff333333),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: const [
                            Icon(
                              Icons.folder_open_outlined,
                              color: Color(0xffffd000),
                              size: 48,
                            ),
                            SizedBox(height: 14),
                            Text(
                              'No saved quizzes or notes yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Quizzes you generate will appear here automatically for review and retesting.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        itemCount: sessions.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final quizList =
                              (session.quizData['quiz'] as List<dynamic>?) ?? [];
                          final questionCount = quizList.length;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xff242424),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xffffd000),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title and Delete Button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        session.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      onPressed: () => _deleteSession(session.id),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Date and Question Count Badges
                                Row(
                                  children: [
                                    Text(
                                      session.date,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xff181818),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$questionCount Qs',
                                        style: const TextStyle(
                                          color: Color(0xffffd000),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Action Buttons (View Notes + Start Quiz)
                                Row(
                                  children: [
                                    // 1. View Notes
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xffffd000),
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                        ),
                                        onPressed: () {
                                          Get.to(
                                            () => NotesScreen(
                                              title: session.title,
                                              notes: session.notes,
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'View Notes',
                                          style: TextStyle(
                                            color: Color(0xffffd000),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // 2. Start Quiz
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xffffd000),
                                          foregroundColor: Colors.black,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                        ),
                                        onPressed: () {
                                          Get.to(
                                            () => QuizScreen(
                                              quizData: session.quizData,
                                              timerMinutes: 10,
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Start Quiz',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}