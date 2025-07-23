import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'face_utils.dart';

class FaceRegister extends StatefulWidget {
  final VoidCallback onComplete;
  final String email;

  FaceRegister({required this.onComplete, required this.email});

  @override
  _FaceRegisterState createState() => _FaceRegisterState();
}

class _FaceRegisterState extends State<FaceRegister> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _captureCount = 0;
  List<List<double>> _embeddings = [];
  bool _camaraActiva = false;
  List<File> _capturedImages = [];

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _controller = CameraController(frontCamera, ResolutionPreset.medium);
    await _controller.initialize();
  }

  Future<void> _procesarImagen(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        print("❌ Archivo no disponible");
        return;
      }

      final inputImage = InputImage.fromFile(imageFile);
      final faceDetector = FaceDetector(
        options:
            FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
      );
      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ No se detectó rostro')),
        );
        return;
      }

      final rect = faces.first.boundingBox;
      final width = MediaQuery.of(context).size.width;
      final centerX = rect.left + rect.width / 2;

      if (centerX < width * 0.2 || centerX > width * 0.8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('🧭 Alinea el rostro al centro del óvalo')),
        );
        return;
      }

      List<double> embedding;
      try {
        embedding = await FaceUtils.obtenerEmbedding(imageFile);
      } catch (e) {
        print("❌ Error al obtener embedding: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Error al procesar imagen")),
        );
        return;
      }

      _embeddings.add(embedding);

      setState(() {
        _capturedImages.add(imageFile);
        _captureCount++;
      });

      if (_captureCount == 3) {
        final promedio = List<double>.filled(192, 0.0);
        for (var vec in _embeddings) {
          for (int i = 0; i < 192; i++) {
            promedio[i] += vec[i];
          }
        }
        for (int i = 0; i < 192; i++) {
          promedio[i] /= 3;
        }

        await FaceUtils.guardarEmbedding(widget.email, promedio);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Rostro guardado correctamente")),
        );

        widget.onComplete();
        setState(() => _camaraActiva = false);
      }
    } catch (e) {
      print("❌ Error procesando imagen: $e");
    }
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      if (!_controller.value.isInitialized) {
        print("⚠️ Cámara no inicializada");
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final imagePath =
          path.join(directory.path, 'face_photo_${_captureCount + 1}.jpg');

      final file = await _controller.takePicture();
      await file.saveTo(imagePath);

      await _procesarImagen(imagePath);
    } catch (e) {
      print("❌ Error al tomar la foto: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error al capturar imagen")),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faltan = 3 - _capturedImages.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧑‍🦱 Registro de Rostro'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // IMÁGENES CAPTURADAS
          if (_capturedImages.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _capturedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _capturedImages[i],
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Captura 3 imágenes alineando tu rostro al óvalo",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),

          const SizedBox(height: 10),

          // CÁMARA o INSTRUCCIONES
          Expanded(
            child: Center(
              child: _camaraActiva && _capturedImages.length < 3
                  ? FutureBuilder(
                      future: _initializeControllerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return AspectRatio(
                            aspectRatio: 3 / 4,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.rotationY(3.14159),
                                  child: CameraPreview(_controller),
                                ),
                                CustomPaint(
                                  painter: OvalPainter(),
                                  size: Size.infinite,
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const CircularProgressIndicator();
                        }
                      },
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam,
                            size: 80, color: Colors.teal),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera),
                          label: const Text("Activar cámara"),
                          onPressed: () async {
                            await _initializeControllerFuture;
                            if (!mounted) return;

                            // BORRAR FOTOS ANTERIORES
                            for (var f in _capturedImages) {
                              if (await f.exists()) await f.delete();
                            }

                            setState(() {
                              _camaraActiva = true;
                              _capturedImages.clear();
                              _embeddings.clear();
                              _captureCount = 0;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 30),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 10),

          // BOTÓN TOMAR FOTO
          if (_camaraActiva && _capturedImages.length < 3)
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: Text("Tomar Foto ($faltan restantes)"),
              onPressed: () async {
                await _takePicture();
                if (_capturedImages.length == 3) {
                  setState(() => _camaraActiva = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),

          const SizedBox(height: 10),

          // BOTÓN FINALIZAR
          if (_capturedImages.length == 3)
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Finalizar Registro"),
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class OvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final ovalWidth = size.width * 0.75;
    final ovalHeight = size.height * 0.55;

    final center = Offset(size.width / 2, size.height / 2);
    final rect =
        Rect.fromCenter(center: center, width: ovalWidth, height: ovalHeight);

    // Dibuja el fondo oscurecido con un óvalo recortado
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(rect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Dibuja el borde del óvalo
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawOval(rect, border);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
