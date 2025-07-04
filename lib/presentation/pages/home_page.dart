import 'package:flutter/material.dart';
import 'package:replay_it/presentation/widgets/camera_recorder_widget.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
        child: CameraRecorderWidget(),
      ),
    );
  }
}
