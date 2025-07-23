import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'face_utils.dart'; // Ajusta la ruta si es distinta

class FaceUtils {
  static late Interpreter _interpreter;
  static bool _modelLoaded = false;

  static Future<void> cargarModelo() async {
    if (_modelLoaded) return;
    _interpreter =
        await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
    _modelLoaded = true;
  }

  static Future<List<double>> obtenerEmbedding(File imagen) async {
    await cargarModelo();

    final bytes = await imagen.readAsBytes();
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

  static Future<void> guardarEmbedding(
      String email, List<double> embedding) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/face_$email.txt');
    await file.writeAsString(embedding.join(','));
  }

  static Future<List<double>?> cargarEmbedding(String email) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/face_$email.txt');
    if (!file.existsSync()) return null;
    final contenido = await file.readAsString();
    return contenido.split(',').map(double.parse).toList();
  }

  static double distanciaCoseno(List<double> a, List<double> b) {
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    return 1 - (dot / (sqrt(normA) * sqrt(normB)));
  }
}
