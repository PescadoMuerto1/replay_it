import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:replay_it/domain/use_cases/convertFrameToVideo.dart';

class CameraRecorderController {
  late CameraController _cameraController;
  bool _isRecording = false;

  CameraController get cameraController => _cameraController;
  bool get isRecording => _isRecording;

  final List<CameraImage> _frameBuffer = [];
  late int timestampStart;
  late int timestampEnd;

  late double framesPerSecond;
  int videoTimeLimit = 6; // seconds

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.last,
      ResolutionPreset.low,
      fps: 30,
    );
    await _cameraController.initialize();
  }

  Future<void> startRecording() async {
    if (!_cameraController.value.isInitialized || _isRecording) return;
    timestampStart = DateTime.now().millisecondsSinceEpoch;
    _frameBuffer.clear();
    _cameraController.startImageStream((CameraImage image) {
      if (_isRecording) {
        _frameBuffer.add(image);
        final currentTimestamp = DateTime.now().millisecondsSinceEpoch;

        if (currentTimestamp > timestampStart + videoTimeLimit * 1000) {
          _frameBuffer.removeAt(0);
        }
      }
    });
    _isRecording = true;
  }

  Future<void> stopRecording() async {
    if (!_cameraController.value.isInitialized || !_isRecording) return;
    await _cameraController.stopImageStream();
    _isRecording = false;
  }

  Future<void> saveRecentRecording() async {
    if (_frameBuffer.isEmpty) return;
    timestampEnd = DateTime.now().millisecondsSinceEpoch;
    await convertFramesToVideo(
      _frameBuffer,
      getVideoFrameRate(timestampEnd, timestampStart, _frameBuffer.length),
      getVideoDimensions(),
    );
    print("Saving recent recording...");
  }

  Size getVideoDimensions() {
    final resolution = _cameraController.value.previewSize;
    if (resolution == null) {
      throw Exception("Camera preview size is not available.");
    }
    return Size(resolution.width, resolution.height);
  }

  getVideoFrameRate(timestampEnd, timestampStart, framesLength) {
    if (_cameraController.value.isInitialized) {
      double videoDuration = ((timestampEnd - timestampStart) / 1000);
      double adjustedVideoDuration =  videoDuration < videoTimeLimit.toDouble() ? videoDuration : videoTimeLimit.toDouble(); 
      return (framesLength / adjustedVideoDuration);
    }
    return;
  }

  void dispose() {
    _cameraController.dispose();
  }
}
