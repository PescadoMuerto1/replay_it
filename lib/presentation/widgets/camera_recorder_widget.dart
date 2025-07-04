import 'package:flutter/material.dart';
import 'package:replay_it/presentation/controllers/camera_recorder_controller.dart';
import 'camera_preview_widget.dart';

class CameraRecorderWidget extends StatefulWidget {
  const CameraRecorderWidget({Key? key}) : super(key: key);

  @override
  State<CameraRecorderWidget> createState() => _CameraRecorderWidgetState();
}

class _CameraRecorderWidgetState extends State<CameraRecorderWidget> {
  late CameraRecorderController _cameraRecorderController;

  @override
  void initState() {
    super.initState();
    _cameraRecorderController = CameraRecorderController();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraRecorderController.initializeCamera();
    setState(() {}); // Rebuild the widget once the camera is initialized.
  }

  @override
  void dispose() {
    _cameraRecorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraRecorderController.cameraController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return CameraPreviewWidget(
      controller: _cameraRecorderController.cameraController,
      isRecording: _cameraRecorderController.isRecording,
      onRecordButtonPressed: () async {
        if (_cameraRecorderController.isRecording) {
          await _cameraRecorderController.stopRecording();
        } else {
          await _cameraRecorderController.startRecording();
        }
        setState(() {}); // Update the UI after recording state changes.
      },
    );
  }
}