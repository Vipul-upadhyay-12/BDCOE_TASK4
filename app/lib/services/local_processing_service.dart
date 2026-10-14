import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdfx/pdfx.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:get_thumbnail_video/index.dart';

class LocalProcessingResult {
  final String? extractedText;
  final File? processedAudio;
  final String fileType; // 'text', 'audio', or 'video_composite'

  LocalProcessingResult({
    this.extractedText,
    this.processedAudio,
    required this.fileType,
  });
}

class LocalProcessingService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<LocalProcessingResult> processFile(File file) async {
    final path = file.path.toLowerCase();

    // 1. PDF Documents -> Page Render + OCR
    if (path.endsWith('.pdf')) {
      final text = await _processPdf(file.path);
      return LocalProcessingResult(extractedText: text, fileType: 'text');
    }

    // 2. Plain Text
    else if (path.endsWith('.txt')) {
      final text = await file.readAsString();
      return LocalProcessingResult(extractedText: text, fileType: 'text');
    }

    // 3. Audio Only -> Upload directly for Whisper
    else if (path.endsWith('.mp3') ||
        path.endsWith('.wav') ||
        path.endsWith('.m4a') ||
        path.endsWith('.aac')) {
      return LocalProcessingResult(processedAudio: file, fileType: 'audio');
    }

    // 4. Video Files -> Extract Frames for OCR + Pass Media File for Whisper
    else if (path.endsWith('.mp4') ||
        path.endsWith('.mkv') ||
        path.endsWith('.mov') ||
        path.endsWith('.webm')) {
      return await _processVideo(file);
    } else {
      throw Exception("Unsupported file format.");
    }
  }

  // --- VIDEO DUAL-PROCESSING ---
  Future<LocalProcessingResult> _processVideo(File videoFile) async {
    final tempDir = await getTemporaryDirectory();
    final StringBuffer slideBuffer = StringBuffer();
    final Set<String> seenSlides = {};

    // Sample a frame every 15s for up to 20 keypoints
    const int sampleIntervalMs = 15000;
    const int maxFrames = 20;

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

            final text = recognized.text.trim();
            if (text.length > 20 && !seenSlides.contains(text)) {
              seenSlides.add(text);
              slideBuffer.writeln("[Slide @ ${timeMs ~/ 1000}s]:");
              slideBuffer.writeln(text);
              slideBuffer.writeln();
            }

            await imgFile.delete();
          }
        }
      } catch (e) {
        // Stop if timestamp exceeds video duration
        break;
      }
    }

    return LocalProcessingResult(
      extractedText: slideBuffer.toString().trim(),
      processedAudio: videoFile, // Whisper extracts the audio stream directly
      fileType: 'video_composite',
    );
  }

  // --- PDF PROCESSING ---
  Future<String> _processPdf(String filePath, {int maxPages = 20}) async {
    final document = await PdfDocument.openFile(filePath);
    final StringBuffer buffer = StringBuffer();
    final tempDir = await getTemporaryDirectory();

    final int pagesToScan =
        document.pagesCount > maxPages ? maxPages : document.pagesCount;

    for (int i = 1; i <= pagesToScan; i++) {
      final page = await document.getPage(i);
      final pageImage = await page.render(
        width: page.width / 1.5,
        height: page.height / 1.5,
        format: PdfPageImageFormat.jpeg,
      );
      await page.close();

      if (pageImage != null) {
        final imgFile = File('${tempDir.path}/page_$i.jpg');
        await imgFile.writeAsBytes(pageImage.bytes);

        final inputImage = InputImage.fromFile(imgFile);
        final recognized = await _textRecognizer.processImage(inputImage);

        if (recognized.text.trim().isNotEmpty) {
          buffer.writeln("--- Page $i ---");
          buffer.writeln(recognized.text);
        }

        if (await imgFile.exists()) {
          await imgFile.delete();
        }
      }
    }

    await document.close();
    return buffer.toString().trim();
  }

  void dispose() {
    _textRecognizer.close();
  }
}