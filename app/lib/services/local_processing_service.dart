import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdfx/pdfx.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:get_thumbnail_video/index.dart';

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
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  // --- ARTIFACT CLEANER & SANITIZER ---
  // Fixes \f, /f, broken ligatures, OCR noise, and hyphenated split words
  String _sanitizeOcrText(String rawText) {
    return rawText
        // Strip control characters (including Form Feed \x0C / \f)
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), ' ')
        // Remove literal escaped form feed variations like \f or /f
        .replaceAll(RegExp(r'(\\|/)f\b'), ' ')
        // Fix split words across line breaks: "infor- \n mation" -> "information"
        .replaceAllMapped(RegExp(r'(\w+)-\s*\n\s*(\w+)'), (m) => '${m[1]}${m[2]}')
        // Eliminate repeated OCR junk symbols (e.g. /**-, ***, ----)
        .replaceAll(RegExp(r'[\/\\*_-]{3,}'), ' ')
        // Normalize spacing and consecutive empty lines
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
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

    // 3. Audio Only -> Upload directly for Whisper
    else if (path.endsWith('.mp3') ||
        path.endsWith('.wav') ||
        path.endsWith('.m4a') ||
        path.endsWith('.aac')) {
      return LocalProcessingResult(processedAudio: file, fileType: 'audio');
    }

    // 4. Video Files -> Sample Slides to .txt + Pass Media File for Whisper
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
      // Calculate dynamic step so processing stays fast regardless of book size
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

    // Assemble structured text file
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

  // Renders a page, runs ML Kit, sanitizes output, and deletes the image
  Future<String> _extractPageText(PdfDocument document, int pageNum, Directory tempDir) async {
    final page = await document.getPage(pageNum);
    // Render at 1.5x scale for sharp text legibility
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

  // --- VIDEO DUAL-PROCESSING ---
  Future<LocalProcessingResult> _processVideo(File videoFile) async {
    final tempDir = await getTemporaryDirectory();
    final StringBuffer slideBuffer = StringBuffer();
    final Set<String> seenSlides = {};

    // Sample a frame every 15s for up to 30 keypoints
    const int sampleIntervalMs = 15000;
    const int maxFrames = 30;

    for (int i = 0; i < maxFrames; i++) {
      final int timeMs = i * sampleIntervalMs;

      try {
        final thumbFile = await VideoThumbnail.thumbnailFile(
          video: videoFile.path,
          thumbnailPath: tempDir.path,
          imageFormat: ImageFormat.JPEG,
          timeMs: timeMs,
          quality: 65,
        );

        if (thumbFile.path.isNotEmpty) {
          final imgFile = File(thumbFile.path);
          if (await imgFile.exists()) {
            final inputImage = InputImage.fromFile(imgFile);
            final recognized = await _textRecognizer.processImage(inputImage);
            final cleanText = _sanitizeOcrText(recognized.text);

            if (cleanText.length > 20 && !seenSlides.contains(cleanText)) {
              seenSlides.add(cleanText);
              slideBuffer.writeln("[Slide @ ${timeMs ~/ 1000}s]:");
              slideBuffer.writeln(cleanText);
              slideBuffer.writeln();
            }

            await imgFile.delete();
          }
        }
      } catch (e) {
        break; // Stop if timestamp exceeds video length
      }
    }

    // Save slides to .txt file
    File? slideTxtFile;
    if (slideBuffer.isNotEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      slideTxtFile = File('${tempDir.path}/video_slides_$timestamp.txt');
      await slideTxtFile.writeAsString(slideBuffer.toString().trim());
    }

    return LocalProcessingResult(
      textFile: slideTxtFile,
      processedAudio: videoFile, // Whisper handles the audio stream
      fileType: 'video_composite',
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}