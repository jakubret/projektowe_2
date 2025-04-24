import 'package:flutter/material.dart';
import 'landmark_recognition_screen.dart'; // Zaimportuj nowy ekran

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const LandmarkRecognitionScreen(); // Wyświetlaj LandmarkRecognitionScreen
  }
}