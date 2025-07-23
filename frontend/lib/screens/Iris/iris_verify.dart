import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class IrisVerify extends StatefulWidget {
  final String identificador;
  final VoidCallback onSuccess;

  const IrisVerify({
    super.key,
    required this.identificador,
    required this.onSuccess,
  });

  @override
  State<IrisVerify> createState() => _IrisVerifyState();
}

class _IrisVerifyState extends State<IrisVerify> {
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

    for (int i = 1; i <= 3; i++) {
      final file = File('${dir.path}/iris_${widget.identificador}_$i.jpg');
      if (!file.existsSync()) continue;

      final ref = img.decodeImage(await file.readAsBytes());
      final sim = _calcularSimilitud(nueva!, ref!);
      similitudes.add(sim);
    }

    final promedio = similitudes.isNotEmpty
        ? similitudes.reduce((a, b) => a + b) / similitudes.length
        : 0.0;

    setState(() {
      _verificando = false;
      if (promedio >= 0.70) {
        _resultado =
            '✅ Iris verificado\n(Similitud: ${promedio.toStringAsFixed(3)})';
        widget.onSuccess();
      } else {
        _resultado =
            '❌ Iris no coincide\n(Similitud: ${promedio.toStringAsFixed(3)})';
      }
    });
  }

  double _calcularSimilitud(img.Image a, img.Image b) {
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
      appBar: AppBar(
        title: const Text('👁️ Verificación de Iris'),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[100],
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _verificando ? 0.4 : 1.0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal,
                ),
                child: const Icon(Icons.remove_red_eye,
                    size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Presiona el botón para escanear tu iris.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800]),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text("Verificar Iris"),
              onPressed: _verificando ? null : _verificar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
            const SizedBox(height: 30),
            if (_resultado.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _resultado.contains("✅")
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _resultado,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _resultado.contains("✅")
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
