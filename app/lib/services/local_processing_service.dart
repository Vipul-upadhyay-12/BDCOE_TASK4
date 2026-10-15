import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdfx/pdfx.dart';

class LocalProcessingResult {
  final File? textFile;
  final File? processedAudio;
  final String fileType; // 'pdf', 'text', 'audio', or 'video_composite'

  LocalProcessingResult({
    this.textFile,
    this.processedAudio,
    required this.fileType,
  });
}

class LocalProcessingService {
  static const MethodChannel _nativeChannel = MethodChannel("com.toolforge.media/pipeline");
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  // Non-destructive cleaner: cleans non-printable control codes while strictly preserving
  // mathematical exponents (2^2), subscripts (x_1), operators (+, -, *, /), Markdown, and code
  String _sanitizeOcrText(String rawText) {
    return rawText
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'(?:\\|/)f(?![a-zA-Z0-9])'), ' ')
        .replaceAllMapped(RegExp(r'([a-zA-Z]{2,})-\s*\n\s*([a-zA-Z]{2,})'), (m) => '${m[1]}${m[2]}')
        .replaceAll(RegExp(r'[ \t]{3,}'), ' ')
        .replaceAll(RegExp(r'\n{4,}'), '\n\n')
        .trim();
  }

  // Jaccard word-set similarity ratio (0.0 to 1.0) to filter redundant/unchanged slides
  double _similarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    final words1 = s1.toLowerCase().split(RegExp(r'\s+')).toSet();
    final words2 = s2.toLowerCase().split(RegExp(r'\s+')).toSet();
    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;
    return union == 0 ? 0.0 : intersection / union;
  }

  Future<LocalProcessingResult> processFile(File file) async {
    final path = file.path.toLowerCase();

    // 1. PDF Documents -> Index (1-10) + Smart Dynamic Sampling (11+) to .txt file
    if (path.endsWith('.pdf')) {
      final textFile = await _processPdf(file.path);
      return LocalProcessingResult(textFile: textFile, fileType: 'pdf');
    }

    // 2. Plain Text -> Pass file directly
    else if (path.endsWith('.txt')) {
      return LocalProcessingResult(textFile: file, fileType: 'text');
    }

    // 3. Audio Only -> Upload directly for backend Whisper
    else if (path.endsWith('.mp3') ||
        path.endsWith('.wav') ||
        path.endsWith('.m4a') ||
        path.endsWith('.aac')) {
      return LocalProcessingResult(processedAudio: file, fileType: 'audio');
    }

    // 4. Video Files -> Native 480p Keyframes + Fast Demuxed .m4a Audio
    else if (path.endsWith('.mp4') ||
        path.endsWith('.mkv') ||
        path.endsWith('.mov') ||
        path.endsWith('.webm')) {
      return await _processVideo(file);
    } else {
      throw Exception("Unsupported file format.");
    }
  }

  // --- PDF PROCESSING (INDEX + SAMPLED CONTENT) ---
  Future<File> _processPdf(String filePath) async {
    final document = await PdfDocument.openFile(filePath);
    final tempDir = await getTemporaryDirectory();
    final int totalPages = document.pagesCount;

    final StringBuffer indexBuffer = StringBuffer();
    final StringBuffer contentBuffer = StringBuffer();

    // SECTION 1: Pages 1 to 10 (Mandatory Table of Contents & Syllabus Outline)
    final int indexEndPage = totalPages < 10 ? totalPages : 10;
    print(">>> Extracting Syllabus Index from pages 1 to $indexEndPage...");

    for (int i = 1; i <= indexEndPage; i++) {
      final text = await _extractPageText(document, i, tempDir);
      if (text.length > 25) {
        indexBuffer.writeln("[Index/ToC Page $i]:");
        indexBuffer.writeln(text);
        indexBuffer.writeln();
      }
    }

    // SECTION 2: Pages 11+ (Evenly Sampled Across All Remaining Chapters)
    if (totalPages > 10) {
      const int targetBodySamples = 40;
      final int remainingPages = totalPages - 10;
      final int step = (remainingPages / targetBodySamples).ceil().clamp(1, 8);

      print(">>> Sampling body pages from 11 to $totalPages with step $step...");

      for (int i = 11; i <= totalPages; i += step) {
        final text = await _extractPageText(document, i, tempDir);
        if (text.length > 40) {
          contentBuffer.writeln("[Content Sample Page $i / $totalPages]:");
          contentBuffer.writeln(text);
          contentBuffer.writeln();
        }
      }
    }

    await document.close();

    final StringBuffer fullDocument = StringBuffer();
    fullDocument.writeln("=== SECTION 1: TABLE OF CONTENTS & SYLLABUS INDEX (PAGES 1-10) ===");
    fullDocument.writeln(indexBuffer.toString().trim());
    fullDocument.writeln("\n\n=== SECTION 2: SAMPLED CHAPTER CONTENT & PRACTICE QUESTIONS ===");
    fullDocument.writeln(contentBuffer.toString().trim());

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputFile = File('${tempDir.path}/extracted_pdf_$timestamp.txt');
    await outputFile.writeAsString(fullDocument.toString());

    print(">>> Saved clean structured text to: ${outputFile.path} (${outputFile.lengthSync()} bytes)");
    return outputFile;
  }

  Future<String> _extractPageText(PdfDocument document, int pageNum, Directory tempDir) async {
    final page = await document.getPage(pageNum);
    final pageImage = await page.render(
      width: page.width * 1.5,
      height: page.height * 1.5,
      format: PdfPageImageFormat.jpeg,
    );
    await page.close();

    if (pageImage == null) return "";

    final imgFile = File('${tempDir.path}/temp_p$pageNum.jpg');
    await imgFile.writeAsBytes(pageImage.bytes);

    final inputImage = InputImage.fromFile(imgFile);
    final recognized = await _textRecognizer.processImage(inputImage);
    final cleanText = _sanitizeOcrText(recognized.text);

    if (await imgFile.exists()) {
      await imgFile.delete();
    }

    return cleanText;
  }

  // --- VIDEO DUAL-PROCESSING (480P KEYFRAMES + DEMUXED AUDIO) ---
  Future<LocalProcessingResult> _processVideo(File videoFile) async {
    final tempDir = await getTemporaryDirectory();
    final String videoPath = videoFile.path;

    // 1. Demux audio track natively to .m4a (<500ms)
    print(">>> Native demuxing audio from video...");
    final String audioPath = await _nativeChannel.invokeMethod('extractAudioTrack', {'videoPath': videoPath});
    final File demuxedAudio = File(audioPath);
    print(">>> Demuxed audio size: ${demuxedAudio.lengthSync() / (1024 * 1024)} MB");

    // 2. Query total duration
    final int durationMs = (await _nativeChannel.invokeMethod<int>('getVideoDuration', {'videoPath': videoPath})) ?? 0;
    print(">>> Total video duration: ${durationMs ~/ 1000} seconds");

    // 3. Adaptive Sampling Schedule:
    // First 2 mins: every 20 seconds (6 frames)
    // Remaining time: dynamically stepped across 70 frames max (capped strictly under 76 total)
    final List<int> introTimestamps = [];
    final List<int> bodyTimestamps = [];

    final int introEndMs = durationMs < 120000 ? durationMs : 120000;
    for (int t = 10000; t <= introEndMs; t += 20000) {
      introTimestamps.add(t);
    }

    if (durationMs > 120000) {
      const int targetBodyBudget = 70;
      final int remainingMs = durationMs - 120000;
      final int stepMs = (remainingMs ~/ targetBodyBudget).clamp(60000, 300000);

      for (int t = 120000 + stepMs; t < durationMs; t += stepMs) {
        bodyTimestamps.add(t);
      }
    }

    final allTimestamps = [...introTimestamps, ...bodyTimestamps];
    print(">>> Requesting ${allTimestamps.length} native keyframes at 480p...");

    // 4. Batch native 480p extraction (OPTION_CLOSEST_SYNC)
    final List<dynamic> rawPaths = await _nativeChannel.invokeMethod('extractKeyframes', {
      'videoPath': videoPath,
      'timestampsMs': allTimestamps,
      'targetWidth': 854,
      'targetHeight': 480,
    });
    final List<String> framePaths = rawPaths.cast<String>();

    // 5. OCR & Similarity De-duplication
    final StringBuffer introBuffer = StringBuffer();
    final StringBuffer bodyBuffer = StringBuffer();
    String previousSlideText = "";

    for (int i = 0; i < framePaths.length; i++) {
      final imgFile = File(framePaths[i]);
      if (await imgFile.exists()) {
        final inputImage = InputImage.fromFile(imgFile);
        final recognized = await _textRecognizer.processImage(inputImage);
        final cleanText = _sanitizeOcrText(recognized.text);

        await imgFile.delete(); // Delete keyframe immediately to prevent storage buildup

        if (cleanText.length > 25 && _similarity(previousSlideText, cleanText) < 0.75) {
          previousSlideText = cleanText;
          final int timeSec = allTimestamps[i] ~/ 1000;

          if (i < introTimestamps.length) {
            introBuffer.writeln("[Agenda/Intro Slide @ ${timeSec}s]:\n$cleanText\n");
          } else {
            bodyBuffer.writeln("[Content Slide @ ${timeSec}s]:\n$cleanText\n");
          }
        }
      }
    }

    // 6. Assemble into Structured Text File
    final StringBuffer fullText = StringBuffer();
    fullText.writeln("=== SECTION 1: LECTURE OVERVIEW & AGENDA SLIDES (FIRST 2 MINS) ===");
    fullText.writeln(introBuffer.toString().trim());
    fullText.writeln("\n\n=== SECTION 2: SAMPLED SLIDES & EQUATIONS (BODY CONTENT) ===");
    fullText.writeln(bodyBuffer.toString().trim());

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final textFile = File('${tempDir.path}/video_slides_$timestamp.txt');
    await textFile.writeAsString(fullText.toString());

    print(">>> Video OCR complete. Saved ${textFile.lengthSync()} bytes of slide text.");

    return LocalProcessingResult(
      textFile: textFile,
      processedAudio: demuxedAudio,
      fileType: 'video_composite',
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}