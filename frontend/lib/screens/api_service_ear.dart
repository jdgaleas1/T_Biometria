import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';
import './biometric_db_helper.dart';

Future<void> verificarOidoHibrido({
  required List<double> features,
  required List<File> imagenes,
  required String email,
  required Function(bool match, double similitud) onResultado,
}) async {
  final connectivityResult = await Connectivity().checkConnectivity();

  if (connectivityResult != ConnectivityResult.none) {
    try {
      final uri = Uri.parse('http://10.43.114.144:8080/registro');
      final request = http.MultipartRequest('POST', uri);

      for (int i = 0; i < imagenes.length; i++) {
        request.files.add(await http.MultipartFile.fromPath(
          'img_$i',
          imagenes[i].path,
          filename: basename(imagenes[i].path),
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        print('🌐 [Remoto] Registro enviado correctamente');
        onResultado(true, 1.0); // Simulamos similitud máxima
        return;
      } else {
        print('⚠️ Fallo remoto: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Excepción en conexión remota: $e');
    }
  }

  // Si no hay internet o falla el backend
  try {
    final templateLocal = await BiometricDBHelper().getTemplate(email, 'ear');

    if (templateLocal == null) {
      print('❌ No se encontró plantilla local para $email');
      onResultado(false, 0.0);
      return;
    }

    double similitud = 0.0;
    for (int i = 0; i < features.length; i++) {
      similitud += 1 - ((features[i] - templateLocal[i]).abs());
    }
    similitud /= features.length;

    final match = similitud >= 0.85;
    print('📦 [Local] Similitud calculada: $similitud');
    onResultado(match, similitud);
  } catch (e) {
    print('❌ Error en comparación local: $e');
    onResultado(false, 0.0);
  }
}
