import 'dart:ui';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:replay_it/domain/use_cases/convertFrameToVideo.dart';

class CameraRecorderController {
  late CameraController _cameraController;
  late CameraDescription _cameraDescription;
  bool _isRecording = false;

  CameraController get cameraController => _cameraController;
  bool get isRecording => _isRecording;

  // Hybrid RAM + Disk circular buffer
  late Directory _tempDir;
  
  // RAM buffer for current 5-second chunk
  final List<Uint8List> _ramBuffer = [];
  
  // Disk buffer for previous chunks
  final List<String> _chunkFiles = [];
  
  // Track actual frame counts per chunk (for accurate frame rate calculation)
  final List<int> _chunkFrameCounts = [];
  
  late int timestampStart;
  late int timestampEnd;

  late double framesPerSecond;
  int videoTimeLimit = 60; // seconds - now supports up to 1 minute
  int framesPerChunk = 150; // 5 seconds * 30 fps
  int maxChunks = 12; // 12 chunks = 60 seconds total

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    _cameraDescription = cameras.last;
    _cameraController = CameraController(
      _cameraDescription,
      ResolutionPreset.veryHigh, // Highest quality
      fps: 30,
    );
    await _cameraController.initialize();
    
    // Set up temporary directory for frame storage
    _tempDir = await getTemporaryDirectory();
    final bufferDir = Directory('${_tempDir.path}/frame_buffer');
    if (await bufferDir.exists()) {
      await bufferDir.delete(recursive: true);
    }
    await bufferDir.create();
    _tempDir = bufferDir;
  }

  Future<void> startRecording() async {
    if (!_cameraController.value.isInitialized || _isRecording) return;
    timestampStart = DateTime.now().millisecondsSinceEpoch;
    
    // Clear existing frame files
    await _clearFrameBuffer();
    
    _isRecording = true;
    
    _cameraController.startImageStream((CameraImage image) async {
      if (_isRecording) {
        // Add frame to RAM buffer
        final yuvData = _convertCameraImageToYUV(image);
        _ramBuffer.add(yuvData);
        
        // When RAM buffer hits 5 seconds (150 frames), write chunk to disk
        if (_ramBuffer.length >= framesPerChunk) {
          await _writeChunkToDisk();
          _ramBuffer.clear();
        }
      }
    });
  }

  Future<void> stopRecording() async {
    if (!_cameraController.value.isInitialized || !_isRecording) return;
    await _cameraController.stopImageStream();
    _isRecording = false;
  }

  Future<void> saveRecentRecording() async {
    if (_chunkFiles.isEmpty && _ramBuffer.isEmpty) {
      print("No recording data available to save");
      return;
    }
    
    timestampEnd = DateTime.now().millisecondsSinceEpoch;
    
    // If there's data in RAM buffer, write it as final chunk
    if (_ramBuffer.isNotEmpty) {
      print("Writing current RAM buffer (${_ramBuffer.length} frames) to disk...");
      await _writeCurrentRamBufferToDisk();
    }
    
    if (_chunkFiles.isEmpty) {
      print("No chunk files available after processing RAM buffer");
      return;
    }
    
    print("Starting video conversion with ${_chunkFiles.length} chunks...");
    await convertChunksToVideo(
      _chunkFiles,
      getVideoFrameRate(timestampEnd, timestampStart, _getTotalFrameCount()),
      getVideoDimensions(),
      getCameraRotation(),
    );
    print("Video conversion completed!");
  }

  Size getVideoDimensions() {
    final resolution = _cameraController.value.previewSize;
    if (resolution == null) {
      throw Exception("Camera preview size is not available.");
    }
    return Size(resolution.width, resolution.height);
  }

  int getCameraRotation() {
    // Get sensor orientation from camera description (0, 90, 180, or 270 degrees)
    // This tells us how the camera sensor is mounted relative to the device
    return _cameraDescription.sensorOrientation;
  }

  double getVideoFrameRate(timestampEnd, timestampStart, framesLength) {
    if (_cameraController.value.isInitialized) {
      double videoDuration = ((timestampEnd - timestampStart) / 1000);
      double adjustedVideoDuration = videoDuration < videoTimeLimit.toDouble() ? videoDuration : videoTimeLimit.toDouble();
      return (framesLength / adjustedVideoDuration);
    }
    return 30.0; // Default fallback
  }

  Future<void> _writeChunkToDisk() async {
    try {
      final chunkPath = '${_tempDir.path}/chunk_${DateTime.now().millisecondsSinceEpoch}.yuv';
      final chunkFile = File(chunkPath);
      
      // Write entire 5-second chunk at once
      final sink = chunkFile.openWrite();
      for (final frameData in _ramBuffer) {
        sink.add(frameData);
      }
      await sink.close();
      
      final frameCount = _ramBuffer.length;
      _chunkFiles.add(chunkPath);
      _chunkFrameCounts.add(frameCount);
      
      // Remove oldest chunk when buffer is full
      if (_chunkFiles.length > maxChunks) {
        final oldestChunk = _chunkFiles.removeAt(0);
        _chunkFrameCounts.removeAt(0);
        final oldFile = File(oldestChunk);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }
    } catch (e) {
      print('Error writing chunk to disk: $e');
    }
  }
  
  Future<void> _writeCurrentRamBufferToDisk() async {
    if (_ramBuffer.isEmpty) return;
    
    final chunkPath = '${_tempDir.path}/final_chunk_${DateTime.now().millisecondsSinceEpoch}.yuv';
    final chunkFile = File(chunkPath);
    
    final sink = chunkFile.openWrite();
    for (final frameData in _ramBuffer) {
      sink.add(frameData);
    }
    await sink.close();
    
    final frameCount = _ramBuffer.length;
    _chunkFiles.add(chunkPath);
    _chunkFrameCounts.add(frameCount);
  }
  
  int _getTotalFrameCount() {
    // Sum actual frame counts from all chunks plus current RAM buffer
    final chunkFramesTotal = _chunkFrameCounts.fold(0, (sum, count) => sum + count);
    return chunkFramesTotal + _ramBuffer.length;
  }

  Uint8List _convertCameraImageToYUV(CameraImage image) {
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final width = image.width;
    final height = image.height;
    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    final yuvData = <int>[];

    // Write Y plane (Luma)
    for (int row = 0; row < height; row++) {
      yuvData.addAll(
          yPlane.bytes.sublist(row * yRowStride, row * yRowStride + width));
    }

    // Write UV planes (Chroma) in NV21 format
    for (int row = 0; row < height ~/ 2; row++) {
      for (int col = 0; col < width ~/ 2; col++) {
        int uvIndex = row * uvRowStride + col * uvPixelStride;
        yuvData.add(vPlane.bytes[uvIndex]);
        yuvData.add(uPlane.bytes[uvIndex]);
      }
    }

    return Uint8List.fromList(yuvData);
  }

  Future<void> _clearFrameBuffer() async {
    // Clear RAM buffer
    _ramBuffer.clear();
    
    // Delete existing chunk files
    for (final chunkPath in _chunkFiles) {
      final chunkFile = File(chunkPath);
      if (await chunkFile.exists()) {
        await chunkFile.delete();
      }
    }
    _chunkFiles.clear();
    _chunkFrameCounts.clear();
  }

  void dispose() {
    _cameraController.dispose();
    // Clean up temporary files and RAM buffer
    _clearFrameBuffer();
  }
}
