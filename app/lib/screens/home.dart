import 'package:flutter/material.dart';

import 'package:helloworld/fileUpload.dart';
import 'transferUrl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _leftController;
  late AnimationController _rightController;

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

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff181818),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 20,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(
                      Icons.menu,
                      color: Color(0xffffd000),
                      size: 30,
                    ),
                    const Text(
                      'ToolForge',
                      style: TextStyle(
                        color: Color(0xffffd000),
                        fontFamily: 'TwCenMT',
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hey Yash,',
                        style: TextStyle(
                          color: Color(0xffffcce9),
                          fontSize: 31,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 190,
                        height: 2,
                        color: const Color(0xff9b7d8e),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Upload a file or URL and get\n'
                  'choicest extracts from it',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xffffd000),
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 30),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth + 15) / 2;
                    final cardHeight = cardWidth * 400 / 185;
                    final imageHeight = cardWidth * 216 / 185;
                    final scale = cardWidth / 185;

                    return Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        height: cardHeight + 20,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 20,
                              child: AnimatedBuilder(
                                animation: _leftController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      _leftController.value * 16 - 8,
                                    ),
                                    child: child,
                                  );
                                },
                                child: Container(
                                  width: cardWidth,
                                  height: cardHeight,
                                  decoration: BoxDecoration(
                                    color: const Color(0xff242424),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xffffd000),
                                      width: 3,
                                    ),
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // TEXT AREA
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        top: 205 * scale,
                                        bottom: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    transferUrl(),
                                              ),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            child: Column(
                                              children: [
                                                const SizedBox(height: 25),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'T',
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xffffd000),
                                                        fontSize: 80 * scale,
                                                        height: 1,
                                                      ),
                                                    ),
                                                    Transform.translate(
                                                      offset: Offset(
                                                        -10 * scale,
                                                        19 * scale,
                                                      ),
                                                      child: Text(
                                                        'ransfer',
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xffffcce9,
                                                          ),
                                                          fontSize: 25 * scale,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  'a url',
                                                  style: TextStyle(
                                                    color: Color(0xffffcce9),
                                                    fontSize: 25 * scale,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Align(
                                                  alignment:
                                                      Alignment.bottomLeft,
                                                  child: Text(
                                                    'Click',
                                                    style: TextStyle(
                                                      color: Color(0xffa9a9a9),
                                                      fontSize: 11 * scale,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: -3,
                                        top: -4,
                                        width: cardWidth,
                                        height: imageHeight,
                                        child: Image.asset(
                                          'assets/card2.png',
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: AnimatedBuilder(
                                animation: _rightController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      -(_rightController.value * 16 - 8),
                                    ),
                                    child: child,
                                  );
                                },
                                child: Container(
                                  width: cardWidth,
                                  height: cardHeight,
                                  decoration: BoxDecoration(
                                    color: const Color(0xff242424),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xffffd000),
                                      width: 3,
                                    ),
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        top: 0,
                                        bottom: 0,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      fileUpload(),
                                                ),
                                              );
                                            },
                                            child: Column(
                                              children: [
                                                SizedBox(height: 30),
                                                RichText(
                                                  textAlign: TextAlign.center,
                                                  text: TextSpan(
                                                    children: [
                                                      TextSpan(
                                                        text: 'F',
                                                        style: TextStyle(
                                                          color:
                                                              Color(0xffffd000),
                                                          fontSize: 80 * scale,
                                                          height: 0.9,
                                                        ),
                                                      ),
                                                      TextSpan(
                                                        text: 'ile',
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xffffcce9,
                                                          ),
                                                          fontSize: 25 * scale,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  'upload',
                                                  style: TextStyle(
                                                    color: Color(0xffffcce9),
                                                    fontSize: 25 * scale,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Align(
                                                  alignment:
                                                      Alignment.bottomRight,
                                                  child: Transform.translate(
                                                    offset: Offset(
                                                      0,
                                                      -210 * scale,
                                                    ),
                                                    child: Text(
                                                      'Click',
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xffa9a9a9),
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      // IMAGE
                                      Positioned(
                                        left: -3,
                                        bottom: -3,
                                        width: cardWidth,
                                        height: imageHeight,
                                        child: Image.asset(
                                          'assets/card.png',
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 25),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Upload Specs Below',
                    style: const TextStyle(
                      color: Color(0xffffcce9),
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Video, Audio and Text files supported\n'
                    'specific- mp4, mp3, txt, pdf\n'
                    'Max. Size: 28 Mb',
                    style: const TextStyle(
                      color: Color(0xffffcce9),
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
