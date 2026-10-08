import 'package:flutter/material.dart';

class fileUpload extends StatelessWidget {
  const fileUpload({super.key});

  @override
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
                SizedBox(height: 40),
                Text(
                  'choose a feature to conpose\n'
                  'from the files content',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xffF5C700).withValues(alpha: 0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
                //const SizedBox(height: 25),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final scale = constraints.maxWidth / 370;

                    return Align(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          SizedBox(height: 30 * scale),
                          SizedBox(
                            width: 370 * scale,
                            height: 55 * scale,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xff242424),
                                      borderRadius:
                                          BorderRadius.circular(16 * scale),
                                      border: Border.all(
                                        color: const Color(0xffF5C700)
                                            .withValues(alpha: 0.9),
                                        width: 3 * scale,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Center(
                                    child: Text(
                                      'File Name Here.txt',
                                      style: TextStyle(
                                        fontSize: 15 * scale,
                                        color: const Color(0xffffcce9),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 30 * scale),
                          SizedBox(
                            width: 370 * scale,
                            height: 216 * scale,
                            child: Image.asset(
                              'assets/long.png',
                              fit: BoxFit.fill,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 25),
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Generate',
                    style: TextStyle(
                      color: Color(0xffffd000),
                      fontSize: 20,
                      height: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 8.0;
                    final cardWidth = (constraints.maxWidth - gap * 2) / 3;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          child: Image.asset(
                            'assets/notes.png',
                            width: cardWidth,
                          ),
                        ),
                        const SizedBox(width: gap),
                        GestureDetector(
                          child: Image.asset(
                            'assets/quiz.png',
                            width: cardWidth,
                          ),
                        ),
                        const SizedBox(width: gap),
                        GestureDetector(
                          child: Image.asset(
                            'assets/other.png',
                            width: cardWidth,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 20),

                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      'Video, Audio and Text files supported\n'
                      'specific- mp4, mp3, txt, pdf\n'
                      'Max. Size: 28 Mb',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xffffcce9),
                        fontSize: 15,
                        height: 1.55,
                      ),
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
