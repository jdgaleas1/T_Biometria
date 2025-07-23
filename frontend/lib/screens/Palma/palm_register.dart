import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../biometric_db_helper.dart';

class PalmRegister extends StatefulWidget {
  final VoidCallback onComplete;
  final String email;

  PalmRegister({required this.onComplete, required this.email});

  @override
  _PalmRegisterState createState() => _PalmRegisterState();
}

class _PalmRegisterState extends State<PalmRegister> {
  final ImagePicker _picker = ImagePicker();
  int _photoCount = 0;
  final int _maxPhotos = 5;
  List<File> _capturedPhotos = [];

  Future<void> _takePalmPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final dir = await getApplicationDocumentsDirectory();
      final filename = 'palm_${widget.email}_${_photoCount + 1}.jpg';
      final newPath = '${dir.path}/$filename';
      final savedFile = await File(pickedFile.path).copy(newPath);

      setState(() {
        _capturedPhotos.add(savedFile);
        _photoCount++;
      });

      if (_photoCount == _maxPhotos) {
        await BiometricDBHelper().insertTemplate(
          widget.email,
          'palm',
          List.filled(128, 0.0), // Simulación de vector
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Registro de palma completado")),
        );

        widget.onComplete();
        Navigator.pop(context);
      }
    } else {
      print("❌ No se tomó ninguna foto.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final faltan = _maxPhotos - _photoCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('✋ Registro de Palma'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),

            // Ícono ilustrativo
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal,
              ),
              padding: const EdgeInsets.all(18),
              child: const Icon(Icons.pan_tool_alt_rounded,
                  size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),

            // Instrucción
            Text(
              "Captura ${_photoCount + 1} de $_maxPhotos",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Abre bien la palma, que esté centrada y enfocada en la cámara",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // Botón de captura
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(faltan > 0
                  ? 'Tomar Foto ($faltan restantes)'
                  : 'Registro completo'),
              onPressed: _photoCount < _maxPhotos ? _takePalmPhoto : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
            const SizedBox(height: 24),

            // Miniaturas de fotos
            if (_capturedPhotos.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _capturedPhotos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _capturedPhotos[i],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
            else
              const Text(
                "Sin fotos aún",
                style: TextStyle(color: Colors.grey),
              ),

            const Spacer(),

            // Indicador de progreso
            LinearProgressIndicator(
              value: _photoCount / _maxPhotos,
              backgroundColor: Colors.grey[300],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.tealAccent),
              minHeight: 8,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
