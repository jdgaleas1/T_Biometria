import 'package:flutter/material.dart';
import 'dart:math';
import 'biometric_verification.dart';

class HomeScreen extends StatelessWidget {
  final String nombreUsuario;

  HomeScreen({this.nombreUsuario = "Usuario"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel Principal'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (_) => false);
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Bienvenido, $nombreUsuario!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Divider(height: 40),
            Text('¿Qué deseas hacer hoy?', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildOption(context, Icons.person, 'Ver Perfil', () {
                  // ir a perfil
                }),
                _buildOption(context, Icons.security, 'Verificar otra vez', () {
                  List<String> biometricOptions = [
                    "Voz",
                    "Oído",
                    "Iris",
                    "Rostro",
                    "Palma"
                  ];
                  biometricOptions.shuffle(Random());
                  List<String> selectedBiometrics =
                      biometricOptions.take(2).toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BiometricVerification(
                        email: nombreUsuario,
                        selected: selectedBiometrics,
                      ),
                    ),
                  );
                }),
                _buildOption(context, Icons.settings, 'Configuración', () {
                  // ir a configuración
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.deepPurple),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
