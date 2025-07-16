// MODIFICADO: Registro con 7 fotos y embedding promedio
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

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
  late Interpreter _interpreter;
  int _captureCount = 0;
  List<List<double>> _embeddings = [];

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
    _loadModel();
  }

  Future<void> _loadModel() async {
    _interpreter =
        await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
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

  Future<bool> contieneRostro(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final options =
        FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate);
    final faceDetector = FaceDetector(options: options);
    final faces = await faceDetector.processImage(inputImage);
    await faceDetector.close();
    return faces.isNotEmpty;
  }

  Future<List<double>> _getEmbedding(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes)!;
    final resized = img.copyResizeCropSquare(image, size: 112);

    var input = List.generate(
        1,
        (_) => List.generate(
            112, (_) => List.generate(112, (_) => List.filled(3, 0.0))));
    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        final pixel = resized.getPixel(x, y);
        input[0][y][x][0] = (pixel.r - 128) / 128.0;
        input[0][y][x][1] = (pixel.g - 128) / 128.0;
        input[0][y][x][2] = (pixel.b - 128) / 128.0;
      }
    }

    var output = List.filled(192, 0.0).reshape([1, 192]);
    _interpreter.run(input, output);
    return List<double>.from(output[0]);
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final directory = await getApplicationDocumentsDirectory();
      final imagePath =
          path.join(directory.path, 'face_photo_${_captureCount + 1}.jpg');
      final file = await _controller.takePicture();
      await file.saveTo(imagePath);
      final imageFile = File(imagePath);

      if (!await contieneRostro(imageFile)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('❌ No se detectó ningún rostro. Intenta de nuevo.')),
        );
        return;
      }

      final embedding = await _getEmbedding(imageFile);
      _embeddings.add(embedding);
      _captureCount++;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('📸 Captura $_captureCount/7 completada')),
      );

      if (_captureCount == 7) {
        // calcular promedio
        List<double> promedio = List.filled(192, 0.0);
        for (var vec in _embeddings) {
          for (int i = 0; i < 192; i++) {
            promedio[i] += vec[i];
          }
        }
        for (int i = 0; i < 192; i++) {
          promedio[i] /= 7;
        }

        final outputFile =
            File('${directory.path}/face_embedding_${widget.email}.txt');
        await outputFile
            .writeAsString(promedio.map((e) => e.toString()).join(','));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("✅ Embedding guardado")));
        widget.onComplete();
        Navigator.pop(context);
      }
    } catch (e) {
      print("❌ Error al tomar la foto: \$e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar Rostro')),
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      "Captura ${_captureCount + 1}/7 - Enfoca bien tu rostro",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          backgroundColor: Colors.black54),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 30),
                    child: FloatingActionButton(
                      onPressed: _takePicture,
                      child: Icon(Icons.camera_alt),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
