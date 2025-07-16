import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:math';

class FaceVerify extends StatefulWidget {
  final String email;
  final VoidCallback onSuccess;

  FaceVerify({required this.email, required this.onSuccess});

  @override
  _FaceVerifyState createState() => _FaceVerifyState();
}

class _FaceVerifyState extends State<FaceVerify> {
  final ImagePicker _picker = ImagePicker();
  late Interpreter _interpreter;
  String _result = '';

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

    final newEmbedding = await _getEmbedding(File(pickedFile.path));
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/face_embedding_${widget.email}.txt');

    if (!file.existsSync()) {
      setState(() {
        _result = "❌ No hay registro previo para este usuario.";
      });
      return;
    }

    final referenceEmbedding =
        file.readAsStringSync().split(',').map(double.parse).toList();
    final distance = _cosineDistance(referenceEmbedding, newEmbedding);

    setState(() {
      if (distance < 0.4) {
        _result =
            '✅ Rostro verificado automáticamente (distancia: ${distance.toStringAsFixed(3)})';
        widget.onSuccess();
      } else {
        _result =
            '❌ Rostro no coincide (distancia: ${distance.toStringAsFixed(3)})';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verificar Rostro')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.verified_user),
              label: Text("Verificar con Foto"),
              onPressed: _verifyFace,
            ),
            const SizedBox(height: 20),
            Text(_result, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
