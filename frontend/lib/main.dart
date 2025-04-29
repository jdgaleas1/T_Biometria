import 'package:flutter/material.dart';
import 'screens/home_page.dart';

void main() {
  runApp(BiometriaApp());
}

class BiometriaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biometría Multimodal',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
