import 'package:app/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'fileUpload.dart';
import 'transferUrl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _leftController;
  late AnimationController _rightController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    _leftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _rightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    super.dispose();
  }

  // Resolves the correct name across Firestore, Google Auth, and Email logins
  Future<String> _resolveUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Friend';

    // 1. Google Auth or updated display name
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim().split(' ').first;
    }

    // 2. Cloud Firestore saved profile record
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final storedName = doc.data()!['name']?.toString().trim();
        if (storedName != null && storedName.isNotEmpty) {
          return storedName.split(' ').first;
        }
      }
    } catch (_) {}

    // 3. Fallback: Parse prefix of email (e.g. "alex" from alex@domain.com)
    if (user.email != null && user.email!.contains('@')) {
      final prefix = user.email!.split('@').first;
      return prefix[0].toUpperCase() + prefix.substring(1);
    }

    return 'Friend';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xff181818),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.menu, color: Color(0xffffd000), size: 30),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
              const SizedBox(height: 24),

              // Dynamic Greeting with Firestore/Auth fallback
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: _resolveUserName(),
                      builder: (context, snapshot) {
                        final name = snapshot.data ?? 'Friend';
                        return Text(
                          'Hey $name,',
                          style: const TextStyle(
                            color: Color(0xffffcce9),
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 170,
                      height: 2,
                      color: const Color(0xff9b7d8e),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // Subheading
              const Text(
                'Upload a file or URL and get\nchoicest extracts from it',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xffffd000),
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),

              // Responsive Two Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  const cardGap = 14.0;
                  final cardWidth = (constraints.maxWidth - cardGap) / 2;
                  final cardHeight = cardWidth * 2.1;
                  final scale = cardWidth / 175;

                  return SizedBox(
                    height: cardHeight + 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // -------------------------------------------------------------
                        // Left Card: Transfer a URL (Image pushed UP)
                        // -------------------------------------------------------------
                        AnimatedBuilder(
                          animation: _leftController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _leftController.value * 12 - 6),
                              child: child,
                            );
                          },
                          child: GestureDetector(
                            onTap: () => Get.to(() => const transferUrl()),
                            child: Container(
                              width: cardWidth,
                              height: cardHeight,
                              decoration: BoxDecoration(
                                color: const Color(0xff242424),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xffffd000), width: 2.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13.5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Top Image Box with negative Y-offset
                                    SizedBox(
                                      height: cardHeight * 0.52,
                                      width: double.infinity,
                                      child: ClipRect(
                                        child: Transform.translate(
                                          offset: const Offset(0, -12), // Pushes image UP past the edge
                                          child: Image.asset(
                                            'assets/card2.png',
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: (cardHeight * 0.52) + 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Bottom Content
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Spacer(),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.baseline,
                                              textBaseline: TextBaseline.alphabetic,
                                              children: [
                                                Text(
                                                  'T',
                                                  style: TextStyle(
                                                    color: const Color(0xffffd000),
                                                    fontSize: 55 * scale,
                                                    fontWeight: FontWeight.w900,
                                                    height: 1,
                                                  ),
                                                ),
                                                Text(
                                                  'ransfer',
                                                  style: TextStyle(
                                                    color: const Color(0xffffcce9),
                                                    fontSize: 20 * scale,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'a url',
                                              style: TextStyle(
                                                color: const Color(0xffffcce9),
                                                fontSize: 20 * scale,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Spacer(),
                                            const Align(
                                              alignment: Alignment.bottomLeft,
                                              child: Text(
                                                'Click',
                                                style: TextStyle(color: Color(0xffa9a9a9), fontSize: 11),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // -------------------------------------------------------------
                        // Right Card: File Upload (Image pushed DOWN)
                        // -------------------------------------------------------------
                        AnimatedBuilder(
                          animation: _rightController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, -(_rightController.value * 12 - 6)),
                              child: child,
                            );
                          },
                          child: GestureDetector(
                            onTap: () => Get.to(() => FileUpload()),
                            child: Container(
                              width: cardWidth,
                              height: cardHeight,
                              decoration: BoxDecoration(
                                color: const Color(0xff242424),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xffffd000), width: 2.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13.5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Top Content
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Spacer(),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.baseline,
                                              textBaseline: TextBaseline.alphabetic,
                                              children: [
                                                Text(
                                                  'F',
                                                  style: TextStyle(
                                                    color: const Color(0xffffd000),
                                                    fontSize: 55 * scale,
                                                    fontWeight: FontWeight.w900,
                                                    height: 1,
                                                  ),
                                                ),
                                                Text(
                                                  'ile',
                                                  style: TextStyle(
                                                    color: const Color(0xffffcce9),
                                                    fontSize: 20 * scale,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'upload',
                                              style: TextStyle(
                                                color: const Color(0xffffcce9),
                                                fontSize: 20 * scale,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Spacer(),
                                            const Align(
                                              alignment: Alignment.bottomRight,
                                              child: Text(
                                                'Click',
                                                style: TextStyle(color: Color(0xffa9a9a9), fontSize: 11),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Bottom Image Box with positive Y-offset
                                    SizedBox(
                                      height: cardHeight * 0.52,
                                      width: double.infinity,
                                      child: ClipRect(
                                        child: Transform.translate(
                                          offset: const Offset(0, 12), // Pushes image DOWN past the edge
                                          child: Image.asset(
                                            'assets/card.png',
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: (cardHeight * 0.52) + 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              const Center(
                child: Text(
                  'Upload Specs Below',
                  style: TextStyle(
                    color: Color(0xffffcce9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Video, Audio and Text files supported\nspecific: mp4, mp3, txt, pdf\nMax. Size: 160 MB (Video) | 25 MB (Audio/Doc)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xffffcce9),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}