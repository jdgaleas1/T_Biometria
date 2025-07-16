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
        // Simulamos que extraemos características (más adelante podrás aplicar procesamiento real)
        await BiometricDBHelper().insertTemplate(
          widget.email,
          'palm',
          List.filled(128, 0.0), // Simulación de vector de características
        );

        print('✅ Registro de palma completado con $_photoCount fotos');
        widget.onComplete();
        Navigator.pop(context);
      }
    } else {
      print("❌ No se tomó ninguna foto.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar Palma')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pan_tool, size: 64, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "Captura ${_photoCount + 1} de $_maxPhotos\nAbre bien la palma y manténla centrada",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text('Tomar Foto de Palma'),
              onPressed: _photoCount < _maxPhotos ? _takePalmPhoto : null,
            ),
            const SizedBox(height: 20),
            Text("Fotos capturadas: $_photoCount / $_maxPhotos"),
          ],
        ),
      ),
    );
  }
}
