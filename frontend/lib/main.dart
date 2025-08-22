import 'package:flutter/material.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/biometric_verification.dart';
import 'screens/Voz/voice_register.dart';
import 'screens/Oído/ear_register.dart';
import 'screens/Iris/iris_register.dart';
import 'screens/Palma/palm_register.dart';
import 'screens/Rostro/face_register.dart';
import 'package:camera/camera.dart';
import 'screens/biometric_db_helper.dart';

void main() async {
  //WidgetsFlutterBinding.ensureInitialized();
  //await BiometricDBHelper().dropTables();
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
        '/login': (context) => LoginScreen(),
        '/splash': (context) => SplashScreen(),
        '/register': (context) => RegisterScreen(),
      },
    );
  }
}
