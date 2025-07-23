import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../biometric_db_helper.dart';
import 'ear_feature_extractor_simple.dart';
import '../api_service_ear.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class EarRegister extends StatefulWidget {
  final VoidCallback? onComplete;
  final void Function(List<double>)? onCompleteWithFeatures;
  final String? email;

  const EarRegister({
    super.key,
    this.onComplete,
    this.onCompleteWithFeatures,
    this.email,
  });

  @override
  State<EarRegister> createState() => _EarRegisterState();
}

class _EarRegisterState extends State<EarRegister> {
  List<File> capturedImages = [];
  bool _procesando = false;
  late Interpreter _interpreter;

  @override
  void initState() {
    super.initState();
    _loadInterpreter();
  }

  Future<void> _loadInterpreter() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/models/modelo_oreja.tflite');
      print("✅ Modelo TFLite cargado correctamente");
    } catch (e) {
      print("❌ Error cargando el modelo TFLite: $e");
    }
  }

  Future<bool> _esOrejaClara(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return false;

      final resized = img.copyResize(image, width: 224, height: 224);
      final input = List.generate(
        1,
        (_) => List.generate(
          224,
          (y) => List.generate(
            224,
            (x) {
              final p = resized.getPixel(x, y);
              return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
            },
          ),
        ),
      );

      final output = List.generate(1, (_) => List.filled(3, 0.0));
      _interpreter.run(input, output);
      final pred = output[0];
      print("🔢 Output: $pred");

      final maxIndex =
          pred.indexWhere((e) => e == pred.reduce((a, b) => a > b ? a : b));
      const clases = ['oreja_clara', 'oreja_borrosa', 'no_oreja'];
      final clase = clases[maxIndex];
      final confianza = pred[maxIndex];

      print(
          "🔍 Clasificación: $clase (confianza: ${confianza.toStringAsFixed(2)})");

      return clase == 'oreja_clara' && confianza >= 0.65;
    } catch (e) {
      print("❌ Error clasificando imagen: $e");
      return false;
    }
  }

  Future<void> _pickImage() async {
    await Permission.camera.request();
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final file = File(image.path);
      final esOreja = await _esOrejaClara(file);

      if (!esOreja) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Imagen no válida de oreja clara')),
        );
        return;
      }

      setState(() => capturedImages.add(file));
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
      final connectivity = await Connectivity().checkConnectivity();
      final hayInternet = connectivity != ConnectivityResult.none;

      if (widget.email != null) {
        bool enviado = false;

        if (hayInternet) {
          try {
            await verificarOidoHibrido(
              features: vectorPromedio,
              imagenes: capturedImages,
              email: widget.email!,
              onResultado: (match, similitud) {
                print("✅ Enviado al backend correctamente");
                enviado = true;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      "✅ Enviado al servidor. Similitud: ${similitud.toStringAsFixed(2)}"),
                ));
              },
            );
          } catch (e) {
            print("⚠️ Falló el backend, se guardará localmente: $e");
          }
        }

        if (!enviado) {
          await BiometricDBHelper()
              .insertTemplate(widget.email!, 'ear', vectorPromedio);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("📥 Registro guardado localmente")),
          );
        }

        widget.onComplete?.call();
        widget.onCompleteWithFeatures?.call(vectorPromedio);
        Navigator.pop(context);
      }
    } catch (e) {
      print("❌ Error procesando oído: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error procesando las imágenes')),
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
        title: const Text('👂 Registro de Oído'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: _procesando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    const Text('📷 Captura de imágenes del oído',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                        'Faltan $restantes ${restantes == 1 ? 'imagen' : 'imágenes'}',
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    if (capturedImages.isEmpty)
                      const Icon(Icons.camera_alt,
                          size: 100, color: Colors.grey),
                    if (capturedImages.isNotEmpty)
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          height: 160,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: capturedImages.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (_, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(capturedImages[i],
                                  width: 100, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera),
                      label: Text(restantes > 0
                          ? 'Tomar imagen ($restantes restantes)'
                          : 'Máximo alcanzado'),
                      onPressed: restantes > 0 ? _pickImage : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
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
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirmar Registro'),
                      onPressed: capturedImages.length == 7
                          ? _procesarYConfirmar
                          : null,
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
