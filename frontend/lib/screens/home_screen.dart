// ✅ HomeScreen mejorado con datos del usuario desde la BD
import 'package:flutter/material.dart';
import 'biometric_db_helper.dart';

class HomeScreen extends StatelessWidget {
  final String nombreUsuario; // este es el email

  const HomeScreen({super.key, required this.nombreUsuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Principal'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (_) => false);
            },
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: BiometricDBHelper().obtenerPerfil(nombreUsuario),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola, ${user['nombres']} ${user['apellidos']}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('📧 ${user['email']}'),
                Text('🌍 País: ${user['pais']}'),
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),
                Text('🔒 Biometrías registradas:',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ...List.generate(user['modalidades'].length, (i) {
                  final modalidad = user['modalidades'][i];
                  return Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.teal, size: 20),
                      const SizedBox(width: 8),
                      Text(modalidad)
                    ],
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
