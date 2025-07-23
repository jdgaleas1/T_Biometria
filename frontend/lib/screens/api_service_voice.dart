import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';

Future<void> enviarVoz(File archivoAudio, String email,
    {required Function(bool match, double similitud) onResultado}) async {
  final uri = Uri.parse('http:/192.168.10.11:8080/register');

  final request = http.MultipartRequest('POST', uri);
  request.fields['email'] = email;
  request.fields['frase'] = 'Esta es la frase esperada'; // si aplica

  request.files.add(await http.MultipartFile.fromPath(
    'audio',
    archivoAudio.path,
    filename: basename(archivoAudio.path),
    contentType: MediaType('audio', 'wav'),
  ));

  try {
    final response = await request.send();

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final similitud = double.tryParse(body.trim()) ?? 0.0;
      final match = similitud >= 0.85;

      print('✅ Similitud recibida: $similitud');
      onResultado(match, similitud);
    } else {
      print('❌ Error al enviar audio: ${response.statusCode}');
      onResultado(false, 0.0);
    }
  } catch (e) {
    print('❌ Error de conexión: $e');
    onResultado(false, 0.0);
  }
}
