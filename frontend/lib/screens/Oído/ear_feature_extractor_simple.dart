import 'dart:io';
import 'package:image/image.dart' as img;

class EarFeatureExtractorSimple {
  static List<double> promediarVectores(List<List<double>> vectores) {
    final dim = vectores[0].length;
    final promedio = List<double>.filled(dim, 0.0);

    for (var vec in vectores) {
      for (int i = 0; i < dim; i++) {
        promedio[i] += vec[i];
      }
    }

    for (int i = 0; i < dim; i++) {
      promedio[i] /= vectores.length;
    }

    return promedio;
  }

  static Future<List<double>> extractHistogram(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes)!;
    final gray = img.grayscale(image);

    final histogram = List<int>.filled(256, 0);

    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final pixel = gray.getPixel(x, y).r;
        histogram[pixel.toInt()]++;
      }
    }

    final totalPixels = gray.width * gray.height;
    return histogram.map((e) => e / totalPixels).toList();
  }
}
