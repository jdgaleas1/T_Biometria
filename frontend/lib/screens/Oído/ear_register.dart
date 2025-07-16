import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../biometric_db_helper.dart';
import 'ear_feature_extractor_simple.dart';
import '../api_service_ear.dart';

class EarRegister extends StatefulWidget {
  final VoidCallback? onComplete;
  final void Function(List<double>)? onCompleteWithFeatures;
  final bool isVerification;
  final String? email;

  const EarRegister({
    super.key,
    this.onComplete,
    this.onCompleteWithFeatures,
    this.isVerification = false,
    this.email,
  });

  @override
  State<EarRegister> createState() => _EarRegisterState();
}

class _EarRegisterState extends State<EarRegister> {
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

  Future<void> _procesarYConfirmar() async {
    if (capturedImages.length < 7) return;

    setState(() => _procesando = true);

    try {
      List<List<double>> allFeatures = [];

      for (var img in capturedImages) {
        final features = await EarFeatureExtractorSimple.extractHistogram(img);
        allFeatures.add(features);
      }

      final vectorPromedio =
          EarFeatureExtractorSimple.promediarVectores(allFeatures);

      if (widget.isVerification && widget.email != null) {
        await verificarOidoHibrido(
          features: vectorPromedio,
          imagenes: capturedImages,
          email: widget.email!,
          onResultado: (match, similitud) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  match
                      ? '✅ Verificación exitosa (similitud: $similitud)'
                      : '❌ Verificación fallida (similitud: $similitud)',
                ),
              ),
            );
          },
        );
      } else if (widget.email != null) {
        // Enviar imágenes al backend
        await verificarOidoHibrido(
          features: vectorPromedio,
          imagenes: capturedImages,
          email: widget.email!,
          onResultado: (match, similitud) async {
            // Guarda local luego de enviar al backend
            await BiometricDBHelper().insertTemplate(
              widget.email!,
              'ear',
              vectorPromedio,
            );
            print('✅ Vector de oído guardado local para ${widget.email}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      '✅ Registro remoto completado. Similitud: $similitud')),
            );
            widget.onComplete?.call();
          },
        );
      }

      Navigator.pop(context);
    } catch (e) {
      print("❌ Error procesando oído: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error procesando imágenes')),
      );
    } finally {
      setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final restantes = 7 - capturedImages.length;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.isVerification ? 'Verificar Oído' : 'Registrar Oído'),
      ),
      body: Center(
        child: _procesando
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (capturedImages.isEmpty)
                    const Text("Captura 7 imágenes del oído"),
                  if (capturedImages.isNotEmpty)
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: capturedImages.length,
                        itemBuilder: (_, i) =>
                            Image.file(capturedImages[i], width: 100),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: Text("Tomar imagen ($restantes restantes)"),
                    onPressed: restantes > 0 ? _pickImage : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: Text(widget.isVerification
                        ? 'Verificar Oído'
                        : 'Confirmar Registro'),
                    onPressed:
                        capturedImages.length == 7 ? _procesarYConfirmar : null,
                  ),
                ],
              ),
      ),
    );
  }
}
