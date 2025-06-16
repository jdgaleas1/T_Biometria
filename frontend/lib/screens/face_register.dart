import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceRegister extends StatefulWidget {
  final VoidCallback onComplete;
  FaceRegister({required this.onComplete});

  @override
  _FaceRegisterState createState() => _FaceRegisterState();
}

class _FaceRegisterState extends State<FaceRegister> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

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

  Future<bool> contieneRostro(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
    );
    final faceDetector = FaceDetector(options: options);
    final faces = await faceDetector.processImage(inputImage);
    await faceDetector.close();
    return faces.isNotEmpty;
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = path.join(directory.path, 'rostro_photo.jpg');
      final file = await _controller.takePicture();
      await file.saveTo(imagePath);
      print("📸 Imagen de rostro guardada: $imagePath");

      final tieneRostro = await contieneRostro(File(imagePath));

      if (!tieneRostro) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('❌ No se detectó ningún rostro. Intenta de nuevo.')),
        );
        return;
      }

      print("✅ Rostro detectado en la imagen");
      widget.onComplete();
      Navigator.pop(context);
    } catch (e) {
      print("❌ Error al tomar la foto: $e");
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
                      "Enfoca bien tu rostro en la cámara",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        backgroundColor: Colors.black54,
                      ),
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
