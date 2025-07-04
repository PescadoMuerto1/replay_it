 import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Replay It',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Replay It Home Page'),
        ),
        body: Center(
          child: Text('Welcome to Replay It!'),
        ),
      ),
    );
  }
}