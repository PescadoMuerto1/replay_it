import 'package:camera/camera.dart';

class CameraRecorderController {
  late CameraController _cameraController;
  bool _isRecording = false;

  CameraController get cameraController => _cameraController;
  bool get isRecording => _isRecording;

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras.first, ResolutionPreset.high);
    await _cameraController.initialize();
  }

  Future<void> startRecording() async {
    if (!_cameraController.value.isInitialized || _isRecording) return;
    await _cameraController.startVideoRecording();
    _isRecording = true;
  }

  Future<void> stopRecording() async {
    if (!_cameraController.value.isInitialized || !_isRecording) return;
    await _cameraController.stopVideoRecording();
    _isRecording = false;
  }

  void dispose() {
    _cameraController.dispose();
  }
}