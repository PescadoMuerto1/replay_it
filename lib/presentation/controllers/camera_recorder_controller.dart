import 'package:camera/camera.dart';

class CameraRecorderController {
  late CameraController _cameraController;
  bool _isRecording = false;

  CameraController get cameraController => _cameraController;
  bool get isRecording => _isRecording;

  final List<CameraImage> _frameBuffer = [];

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      fps: 30,
    );
    await _cameraController.initialize();
  }

  Future<void> startRecording() async {
    if (!_cameraController.value.isInitialized || _isRecording) return;
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
    _isRecording = false;
  }

  void dispose() {
    _cameraController.dispose();
  }
}
