import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:math';

class FaceVerify extends StatefulWidget {
  final String identificador;
  final VoidCallback onSuccess;

  const FaceVerify(
      {super.key, required this.identificador, required this.onSuccess});

  @override
  State<FaceVerify> createState() => _FaceVerifyState();
}

class _FaceVerifyState extends State<FaceVerify> {
  final ImagePicker _picker = ImagePicker();
  late Interpreter _interpreter;
  String _resultado = '';
  bool _verificando = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    _interpreter =
        await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
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

  double _cosineDistance(List<double> a, List<double> b) {
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    return 1 - (dot / (sqrt(normA) * sqrt(normB)));
  }

  Future<void> _verifyFace() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    setState(() => _verificando = true);

    final newEmbedding = await _getEmbedding(File(pickedFile.path));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/face_embedding_${widget.identificador}.txt');

    if (!file.existsSync()) {
      setState(() {
        _resultado = "❌ No hay registro previo para este usuario.";
        _verificando = false;
      });
      return;
    }

    final referenceEmbedding =
        file.readAsStringSync().split(',').map(double.parse).toList();
    final distance = _cosineDistance(referenceEmbedding, newEmbedding);

    setState(() {
      _verificando = false;
      if (distance < 0.4) {
        _resultado =
            '✅ Rostro verificado (distancia: ${distance.toStringAsFixed(3)})';
        widget.onSuccess();
      } else {
        _resultado =
            '❌ Rostro no coincide (distancia: ${distance.toStringAsFixed(3)})';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('🔍 Verificación Facial'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.face_retouching_natural,
                size: 100, color: Colors.deepPurple),
            const SizedBox(height: 20),
            Text(
              "Presiona el botón para capturar tu rostro",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _verificando ? null : _verifyFace,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Verificar Rostro"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_resultado.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _resultado.contains('✅')
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _resultado.contains('✅') ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  _resultado,
                  style: TextStyle(
                    fontSize: 16,
                    color: _resultado.contains('✅')
                        ? Colors.green[800]
                        : Colors.red[800],
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
          ],
        ),
      ),
    );
  }
}
