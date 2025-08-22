// ✅ HomeScreen mejorado con sincronización automática
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'biometric_db_helper.dart';
import 'sync_manager.dart'; // asegúrate de tener este archivo

class HomeScreen extends StatefulWidget {
  final String nombreUsuario; // este es el email

  const HomeScreen({super.key, required this.nombreUsuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    revisarYSincronizar();
  }

  Future<void> revisarYSincronizar() async {
    final resultado = await Connectivity().checkConnectivity();
    if (resultado != ConnectivityResult.none) {
      print("🔄 Conexión detectada, lanzando sincronización...");
      await SyncManager().iniciar();
    } else {
      print("❌ Sin conexión, no se puede sincronizar.");
    }
  }

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
        future: BiometricDBHelper().obtenerPerfil(widget.nombreUsuario),
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
                if (user['modalidades'] != null && user['modalidades'] is List)
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
                  })
                else
                  const Text("❗ No se encontraron modalidades biométricas"),
              ],
            ),
          );
        },
      ),
    );
  }
}
