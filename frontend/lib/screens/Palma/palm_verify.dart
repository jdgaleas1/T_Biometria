import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class PalmVerify extends StatefulWidget {
  final String email;
  final VoidCallback onSuccess;

  const PalmVerify({super.key, required this.email, required this.onSuccess});

  @override
  State<PalmVerify> createState() => _PalmVerifyState();
}

class _PalmVerifyState extends State<PalmVerify> {
  String _resultado = '';
  bool _verificando = false;

  Future<void> _verificar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked == null) return;

    setState(() => _verificando = true);

    final nueva = img.decodeImage(await File(picked.path).readAsBytes());
    final dir = await getApplicationDocumentsDirectory();

    List<double> similitudes = [];

    for (int i = 1; i <= 5; i++) {
      final file = File('${dir.path}/palm_${widget.email}_$i.jpg');
      if (!file.existsSync()) continue;

      final ref = img.decodeImage(await file.readAsBytes());
      final sim = _calcularSimilitudPromedio(nueva!, ref!);
      similitudes.add(sim);
    }

    final promedio = similitudes.isNotEmpty
        ? similitudes.reduce((a, b) => a + b) / similitudes.length
        : 0.0;

    setState(() {
      _verificando = false;
      if (promedio >= 0.85) {
        _resultado =
            '✅ Palma verificada\nSimilaridad: ${(promedio * 100).toStringAsFixed(2)}%';
        widget.onSuccess();
      } else {
        _resultado =
            '❌ Palma no coincide\nSimilaridad: ${(promedio * 100).toStringAsFixed(2)}%';
      }
    });
  }

  double _calcularSimilitudPromedio(img.Image a, img.Image b) {
    final resizedA = img.copyResize(a, width: 128, height: 128);
    final resizedB = img.copyResize(b, width: 128, height: 128);

    double suma = 0.0;
    for (int y = 0; y < 128; y++) {
      for (int x = 0; x < 128; x++) {
        final p1 = resizedA.getPixel(x, y);
        final p2 = resizedB.getPixel(x, y);
        suma += (img.getLuminance(p1) - img.getLuminance(p2)).abs();
      }
    }
    final maxDiff = 128.0 * 128.0 * 255.0;
    return 1.0 - (suma / maxDiff);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('🖐️ Verificación de Palma'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pan_tool_alt_outlined,
                size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              "Captura una nueva foto de tu palma para comparar con las imágenes registradas",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text("Verificar Palma"),
              onPressed: _verificando ? null : _verificar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 18, 25, 121),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_verificando) const CircularProgressIndicator(),
            if (_resultado.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _resultado.startsWith('✅')
                      ? Colors.green[100]
                      : Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _resultado,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _resultado.startsWith('✅')
                        ? Colors.green[900]
                        : Colors.red[900],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
