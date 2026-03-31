import 'package:flutter/material.dart';
import 'plant_recognition.dart';

class ChooseModel extends StatelessWidget {
  final int initialModel;
  const ChooseModel({super.key, required this.initialModel});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PlantSpeciesRecognition(initialModel),
        ),
      );
    });
    return const Scaffold(
      backgroundColor: Color(0xFF0F0F1A),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      ),
    );
  }
}