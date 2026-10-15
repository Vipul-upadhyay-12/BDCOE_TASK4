package com.example.app


import android.graphics.Bitmap
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.toolforge.media/pipeline"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getVideoDuration" -> {
                    val videoPath = call.argument<String>("videoPath") ?: return@setMethodCallHandler result.error("ARG_ERROR", "videoPath missing", null)
                    val retriever = MediaMetadataRetriever()
                    try {
                        retriever.setDataSource(videoPath)
                        val durationStr = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                        val durationMs = durationStr?.toLongOrNull() ?: 0L
                        result.success(durationMs)
                    } catch (e: Exception) {
                        result.error("DURATION_ERROR", e.localizedMessage, null)
                    } finally {
                        retriever.release()
                    }
                }

                "extractAudioTrack" -> {
                    val videoPath = call.argument<String>("videoPath") ?: return@setMethodCallHandler result.error("ARG_ERROR", "videoPath missing", null)
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val outputPath = demuxAudioTrack(videoPath)
                            withContext(Dispatchers.Main) { result.success(outputPath) }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) { result.error("AUDIO_ERROR", e.localizedMessage, null) }
                        }
                    }
                }

                "extractKeyframes" -> {
                    val videoPath = call.argument<String>("videoPath") ?: return@setMethodCallHandler result.error("ARG_ERROR", "videoPath missing", null)
                    val timestampsMs = call.argument<List<Int>>("timestampsMs") ?: emptyList()
                    val targetWidth = call.argument<Int>("targetWidth") ?: 854
                    val targetHeight = call.argument<Int>("targetHeight") ?: 480

                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val framePaths = extractKeyframes480p(videoPath, timestampsMs, targetWidth, targetHeight)
                            withContext(Dispatchers.Main) { result.success(framePaths) }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) { result.error("FRAME_ERROR", e.localizedMessage, null) }
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    // 1. FAST NATIVE AUDIO DEMUXING (<500ms)
    private fun demuxAudioTrack(videoPath: String): String {
        val extractor = MediaExtractor()
        extractor.setDataSource(videoPath)

        var audioTrackIndex = -1
        var audioFormat: MediaFormat? = null

        for (i in 0 until extractor.trackCount) {
            val format = extractor.getTrackFormat(i)
            val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
            if (mime.startsWith("audio/")) {
                audioTrackIndex = i
                audioFormat = format
                break
            }
        }

        if (audioTrackIndex == -1 || audioFormat == null) {
            extractor.release()
            throw IllegalStateException("No audio track detected in the video container.")
        }

        extractor.selectTrack(audioTrackIndex)
        val outputFile = File(cacheDir, "extracted_audio_${System.currentTimeMillis()}.m4a")
        val muxer = MediaMuxer(outputFile.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        val muxerTrackIndex = muxer.addTrack(audioFormat)
        muxer.start()

        val maxBufferSize = if (audioFormat.containsKey(MediaFormat.KEY_MAX_INPUT_SIZE)) {
            audioFormat.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE)
        } else {
            1024 * 1024
        }
        val buffer = ByteBuffer.allocate(maxBufferSize)
        val bufferInfo = MediaCodec.BufferInfo()

        while (true) {
            bufferInfo.offset = 0
            bufferInfo.size = extractor.readSampleData(buffer, 0)
            if (bufferInfo.size < 0) break

            bufferInfo.presentationTimeUs = extractor.sampleTime
            bufferInfo.flags = extractor.sampleFlags
            muxer.writeSampleData(muxerTrackIndex, buffer, bufferInfo)
            extractor.advance()
        }

        muxer.stop()
        muxer.release()
        extractor.release()
        return outputFile.absolutePath
    }

    // 2. HARDWARE-ACCELERATED 480P KEYFRAME EXTRACTION
    private fun extractKeyframes480p(
        videoPath: String,
        timestampsMs: List<Int>,
        width: Int,
        height: Int
    ): List<String> {
        val retriever = MediaMetadataRetriever()
        retriever.setDataSource(videoPath)
        val outputPaths = mutableListOf<String>()

        for ((index, timeMs) in timestampsMs.withIndex()) {
            val timeUs = timeMs * 1000L
            val bitmap = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                retriever.getScaledFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC, width, height)
            } else {
                retriever.getFrameAtTime(timeUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
            }

            if (bitmap != null) {
                val frameFile = File(cacheDir, "frame_${System.currentTimeMillis()}_$index.jpg")
                FileOutputStream(frameFile).use { out ->
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 70, out)
                }
                bitmap.recycle()
                outputPaths.add(frameFile.absolutePath)
            }
        }

        retriever.release()
        return outputPaths
    }
}