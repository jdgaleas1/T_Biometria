import 'package:flutter/material.dart';
import 'dart:math';
import 'biometric_verification.dart';
import 'register_screen.dart';
import 'biometric_db_helper.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  List<String> biometricOptions = ["Voz", "Oído", "Iris", "Rostro", "Palma"];
  List<String> selectedBiometrics = [];

  void iniciarVerificacion() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showSnack("Por favor ingresa tu correo electrónico");
      return;
    }

    final existe = await BiometricDBHelper().existeUsuario(email);

    if (!existe) {
      _showSnack("❌ Correo no registrado. Por favor regístrate primero.");
      return;
    }

    biometricOptions.shuffle(Random());
    selectedBiometrics = biometricOptions.take(2).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BiometricVerification(
          email: email,
          selected: selectedBiometrics,
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_rounded,
                  size: 80, color: Colors.teal[300]),
              const SizedBox(height: 12),
              Text(
                'Biometría Multimodal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 50),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Inicio de Sesión',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildInputField(
                  emailController, 'Correo Electrónico', 'ejemplo@correo.com'),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.login, color: Colors.white),
                  label: Text('Iniciar verificación biométrica'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: iniciarVerificacion,
                ),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterScreen()),
                ),
                child: Text(
                  '¿No tienes cuenta? Registrarse',
                  style: TextStyle(
                    color: Colors.teal[700],
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
      TextEditingController controller, String label, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: Colors.teal[700]),
        hintStyle: TextStyle(color: Colors.grey),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.teal.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.teal, width: 2),
        ),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }
}
