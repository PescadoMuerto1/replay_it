import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_preview_widget.dart';

class CameraRecorderWidget extends StatefulWidget {
  @override
  _CameraRecorderWidgetState createState() => _CameraRecorderWidgetState();
}

class _CameraRecorderWidgetState extends State<CameraRecorderWidget> {
  late CameraController _controller;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _controller = CameraController(cameras.last, ResolutionPreset.high);
      await _controller.initialize();
      setState(() {});
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _controller.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
    } else {
      await _controller.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller.value.isInitialized
          ? CameraPreviewWidget(
              controller: _controller,
              isRecording: _isRecording,
              onRecordButtonPressed: _toggleRecording,
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}