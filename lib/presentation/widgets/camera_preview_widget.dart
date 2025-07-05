import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;
  final VoidCallback onRecordButtonPressed;
  final VoidCallback onSaveResentRecordingPressed;
  final bool isRecording;

  const CameraPreviewWidget({
    Key? key,
    required this.controller,
    required this.onRecordButtonPressed,
    required this.onSaveResentRecordingPressed, 
    required this.isRecording,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CameraPreview(controller),
        Align(
          alignment: Alignment.bottomCenter,
          child: Row( // Changed to Row for horizontal alignment
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                onPressed: onRecordButtonPressed,
                backgroundColor: isRecording ? Colors.red : Colors.green,
                child: Icon(isRecording ? Icons.stop : Icons.videocam),
              ),
              SizedBox(width: 16), 
              FloatingActionButton( 
                onPressed: onSaveResentRecordingPressed, 
                backgroundColor: Colors.blue,
                child: Icon(Icons.camera), 
              ),
            ],
          ),
          ),
      ],
    );
  }
}