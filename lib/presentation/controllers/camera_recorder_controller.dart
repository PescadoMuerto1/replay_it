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
    _cameraController.startImageStream((CameraImage image){
      if (_isRecording) {
        _frameBuffer.add(image);
      }
    });
    _isRecording = true;
  }

  Future<void> stopRecording() async {
    if (!_cameraController.value.isInitialized || !_isRecording) return;
    await _cameraController.stopImageStream();
    timestampEnd = DateTime.now().millisecondsSinceEpoch;
    convertFramesToVideo(_frameBuffer, getVideoFrameRate(timestampEnd, timestampStart, _frameBuffer.length), getVideoDimensions());
    _isRecording = false;
  } 

  Size getVideoDimensions() {
    final resolution = _cameraController.value.previewSize;
    if (resolution != null) {
      return Size(resolution.width, resolution.height);
    }
    return Size(0, 0);
  }
    
  getVideoFrameRate(timestampEnd,timestampStart,framesLength){
    if (_cameraController.value.isInitialized) {
     double videoDuration = ((timestampEnd - timestampStart) / 1000);
           return(framesLength / videoDuration);
    }
    return;
  }

  void dispose() {
    _cameraController.dispose();
  }
}
