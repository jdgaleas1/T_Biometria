import 'dart:io';
import 'dart:math'; // Necesario para sqrt y pow
import 'package:image/image.dart' as img;

class EarFeatureExtractorSimple {
  /// Extrae un histograma normalizado en escala de grises (256 bins)
  static Future<List<double>> extractHistogram(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes)!;
    final gray = img.grayscale(image);

    final histogram = List<int>.filled(256, 0);

    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final pixel = gray.getPixel(x, y).r.toInt();
        histogram[pixel]++;
      }
    }

    final totalPixels = gray.width * gray.height;
    return histogram.map((e) => e / totalPixels).toList();
  }

  /// Calcula el promedio de una lista de vectores
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

  /// ✅ Similitud coseno entre dos vectores (rango: -1 a 1, ideal > 0.85)
  static double calcularSimilitud(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Los vectores deben tener la misma longitud');
    }

    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    final denominator = sqrt(normA) * sqrt(normB);
    return denominator == 0 ? 0.0 : dotProduct / denominator;
  }

  /// 🚨 Alternativa: distancia euclidiana (0 = iguales, >0 = más distintos)
  static double distanciaEuclidiana(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Los vectores deben tener la misma longitud');
    }

    double suma = 0.0;
    for (int i = 0; i < a.length; i++) {
      suma += pow(a[i] - b[i], 2);
    }

    return sqrt(suma);
  }
}
