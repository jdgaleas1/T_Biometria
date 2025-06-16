import 'package:flutter/material.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/biometric_verification.dart';
import 'screens/voice_register.dart';
import 'screens/ear_register.dart';
import 'screens/iris_register.dart';
import 'screens/palm_register.dart';
import 'screens/face_register.dart';
import 'package:camera/camera.dart';

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
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/': (context) => HomeScreen(), // ✅ esta línea es clave
        '/login': (context) => LoginScreen(),
        '/splash': (context) => SplashScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/iris_register': (context) => IrisRegister(onComplete: () {}),
        '/palm_register': (context) => PalmRegister(onComplete: () {}),
      },
    );
  }
}
