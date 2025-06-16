import 'package:flutter/material.dart';
import 'dart:math';
import 'biometric_verification.dart';
import 'register_screen.dart'; // para el link de Registrarse

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  List<String> biometricOptions = ["Voz", "Oído", "Iris", "Rostro", "Palma"];
  List<String> selectedBiometrics = [];

  void iniciarVerificacion() {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Por favor ingresa tu correo electrónico")),
      );
      return;
    }

    biometricOptions.shuffle(Random());
    selectedBiometrics = biometricOptions.take(2).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BiometricVerification(
          email: emailController.text,
          selected: selectedBiometrics,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icono nube
              Icon(Icons.cloud, size: 80, color: Colors.grey[400]),
              SizedBox(height: 10),

              // Texto Biometría Multimodal
              Text(
                'Biometría Multimodal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 50),

              // Titulo Inicio de Sesión
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Inicio de Sesión',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Campo Correo Electrónico
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  labelStyle: TextStyle(color: Colors.redAccent),
                  hintText: 'example@email.com',
                ),
              ),
              SizedBox(height: 30),

              // Botón iniciar verificación biométrica
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: iniciarVerificacion,
                  child: Text(
                    'Iniciar verificación biométrica',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

              SizedBox(height: 40),

              // Link Registrarse
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RegisterScreen()),
                  );
                },
                child: Text(
                  'Registrarse',
                  style: TextStyle(
                    color: Colors.redAccent,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
