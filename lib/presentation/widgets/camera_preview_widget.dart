import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;
  final VoidCallback onRecordButtonPressed;
  final bool isRecording;

  const CameraPreviewWidget({
    Key? key,
    required this.controller,
    required this.onRecordButtonPressed,
    required this.isRecording,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CameraPreview(controller),
        Align(
          alignment: Alignment.bottomCenter,
          child: FloatingActionButton(
            onPressed: onRecordButtonPressed,
            backgroundColor: isRecording ? Colors.red : Colors.green,
            child: Icon(isRecording ? Icons.stop : Icons.videocam),
          ),
        ),
      ],
    );
  }
}