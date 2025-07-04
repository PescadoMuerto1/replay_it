import 'package:flutter/material.dart';
import 'package:replay_it/presention/pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'play_shot',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}