import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:math';

class FaceVerify extends StatefulWidget {
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
    _interpreter = await Interpreter.fromAsset('mobile_facenet.tflite');
  }

  Future<List<double>> _getEmbedding(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes)!;
    final resized = img.copyResizeCropSquare(image, size: 112);

    var input = List.generate(
      1,
      (_) => List.generate(
        112,
        (_) => List.generate(112, (_) => List.filled(3, 0.0)),
      ),
    );

    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        final pixel = resized.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;

        input[0][y][x][0] = (r - 128) / 128.0;
        input[0][y][x][1] = (g - 128) / 128.0;
        input[0][y][x][2] = (b - 128) / 128.0;
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
    final file = File('${dir.path}/face_embedding_user001.txt');
    if (!file.existsSync()) {
      setState(() {
        _result = "No hay registro previo.";
      });
      return;
    }

    final referenceEmbedding =
        file.readAsStringSync().split(',').map(double.parse).toList();

    final distance = _cosineDistance(referenceEmbedding, newEmbedding);

    setState(() {
      _result = distance < 0.4
          ? '✅ Rostro verificado (distancia: ${distance.toStringAsFixed(3)})'
          : '❌ Rostro no coincide (distancia: ${distance.toStringAsFixed(3)})';
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
              style: ElevatedButton.styleFrom(minimumSize: Size(200, 48)),
            ),
            SizedBox(height: 20),
            Text(_result, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
