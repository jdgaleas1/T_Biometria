import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';
import './biometric_db_helper.dart';
import 'dart:typed_data';

Future<void> verificarOidoHibrido({
  required List<double> features,
  required List<File> imagenes,
  required String identificador,
  required Function(bool match, double similitud) onResultado,
}) async {
  final connectivityResult = await Connectivity().checkConnectivity();
  bool enviadoRemotamente = false;

  if (connectivityResult != ConnectivityResult.none) {
    try {
      final uri = Uri.parse('http://192.168.100.98:8080//oreja/autenticar');
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
        enviadoRemotamente = true;
        onResultado(true, 1.0); // Similitud máxima (simulada)
      } else {
        print('⚠️ Fallo remoto: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Excepción en conexión remota: $e');
    }
  }

  if (!enviadoRemotamente) {
    try {
      final idUsuario =
          await BiometricDBHelper().obtenerIdUsuario(identificador);

      if (idUsuario == null) {
        print('❌ Usuario no encontrado: $identificador');
        onResultado(false, 0.0);
        return;
      }

      await BiometricDBHelper().insertarCredencialBiometrica(
        idUsuario: idUsuario,
        tipoBiometria: 'oido',
        features: features,
        versionAlgoritmo: '1.0',
      );

      print('📥 [Local] Template oído guardado en BD local');
    } catch (e) {
      print('❌ No se pudo guardar localmente: $e');
    }

    // Intentar comparar con el template local si ya existe
    try {
      final idUsuario =
          await BiometricDBHelper().obtenerIdUsuario(identificador);
      if (idUsuario == null) {
        onResultado(false, 0.0);
        return;
      }

      final credenciales =
          await BiometricDBHelper().obtenerCredenciales(idUsuario);

      final entry = credenciales.firstWhere(
        (c) => c['tipo_biometria'] == 'oido',
        orElse: () => {},
      );

      if (entry.isEmpty) {
        print('❌ No se encontró plantilla local para $identificador');
        onResultado(false, 0.0);
        return;
      }

      final blob = entry['template'] as Uint8List;
      final templateLocal = Float64List.view(blob.buffer).toList();

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
}
