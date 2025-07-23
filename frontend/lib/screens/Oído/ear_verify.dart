import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../biometric_db_helper.dart';
import 'ear_feature_extractor_simple.dart';
import '../api_service_ear.dart';
import 'dart:typed_data';

class EarVerify extends StatefulWidget {
  final String identificador;
  final VoidCallback onSuccess;
  final void Function(List<double>)? onCompleteWithFeatures;

  const EarVerify({
    super.key,
    required this.identificador,
    required this.onSuccess,
    this.onCompleteWithFeatures,
  });

  @override
  State<EarVerify> createState() => _EarVerifyState();
}

class _EarVerifyState extends State<EarVerify> {
  List<File> capturedImages = [];
  bool _procesando = false;

  Future<void> _pickImage() async {
    await Permission.camera.request();
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() => capturedImages.add(File(image.path)));
    }
  }

  Future<void> _verificar() async {
    if (capturedImages.length < 1) return;
    setState(() => _procesando = true);

    try {
      final allFeatures = <List<double>>[];

      for (var img in capturedImages) {
        final features = await EarFeatureExtractorSimple.extractHistogram(img);
        allFeatures.add(features);
      }

      final vectorPromedio =
          EarFeatureExtractorSimple.promediarVectores(allFeatures);

      final connectivity = await Connectivity().checkConnectivity();
      final hayInternet = connectivity != ConnectivityResult.none;

      final idUsuario =
          await BiometricDBHelper().obtenerIdUsuario(widget.identificador);

      if (idUsuario == null) {
        throw Exception("Usuario no encontrado");
      }

      if (hayInternet) {
        await verificarOidoHibrido(
          features: vectorPromedio,
          imagenes: capturedImages,
          identificador: widget.identificador, // usado como ID lógico remoto
          onResultado: (match, similitud) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                match
                    ? '✅ Verificación remota exitosa (similitud: $similitud)'
                    : '❌ Verificación remota fallida (similitud: $similitud)',
              ),
            ));
            if (match) widget.onSuccess();
          },
        );
      } else {
        final credenciales =
            await BiometricDBHelper().obtenerCredenciales(idUsuario);

        final storedEntry = credenciales.firstWhere(
          (c) => c['tipo_biometria'] == 'oido',
          orElse: () => {},
        );

        if (storedEntry.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("❌ No hay datos locales para comparar")),
          );
        } else {
          final blob = storedEntry['template'] as Uint8List;
          final stored = Float64List.view(blob.buffer).toList();
          final similitud = EarFeatureExtractorSimple.calcularSimilitud(
              stored, vectorPromedio);
          final match = similitud >= 0.8;

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(match
                ? '✅ Verificación local exitosa (similitud: $similitud)'
                : '❌ Verificación local fallida (similitud: $similitud)'),
          ));

          if (match) widget.onSuccess();
        }
      }

      Navigator.pop(context);
    } catch (e) {
      print("❌ Error en verificación: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error durante la verificación')),
      );
    } finally {
      setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final restantes = 1 - capturedImages.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Verificar Oído'),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: Center(
        child: _procesando
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '📸 Captura al menos 1 imágenes de tu oído',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Text('Faltan $restantes imágenes',
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    if (capturedImages.isEmpty)
                      const Icon(Icons.camera_alt,
                          size: 100, color: Colors.grey),
                    if (capturedImages.isNotEmpty)
                      SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: capturedImages.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              capturedImages[i],
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera),
                      label: Text(
                        restantes > 0
                            ? 'Tomar imagen ($restantes restantes)'
                            : 'Máximo alcanzado',
                      ),
                      onPressed: restantes > 0 ? _pickImage : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.verified),
                      label: const Text('Verificar Oído'),
                      onPressed: capturedImages.length == 1 ? _verificar : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
