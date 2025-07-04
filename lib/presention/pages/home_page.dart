import 'package:flutter/material.dart';
import 'package:replay_it/presention/widgets/camera_preview_widget.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
        child: CameraPreviewWidget(),
      ),
    );
  }
}
