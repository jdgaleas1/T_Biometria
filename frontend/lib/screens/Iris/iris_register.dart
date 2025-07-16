import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class IrisRegister extends StatefulWidget {
  final VoidCallback onComplete;
  final String email;

  IrisRegister({required this.onComplete, required this.email});

  @override
  _IrisRegisterState createState() => _IrisRegisterState();
}

class _IrisRegisterState extends State<IrisRegister> {
  final ImagePicker _picker = ImagePicker();
  int _capturas = 0;
  final int _total = 3;

  Future<void> _tomarFotoIris() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final filename = 'iris_${widget.email}_${_capturas + 1}.jpg';
        final path = '${dir.path}/$filename';
        await File(pickedFile.path).copy(path);

        setState(() => _capturas++);

        if (_capturas == _total) {
          print('✅ Registro de iris completado con $_total fotos');
          widget.onComplete();
          Navigator.pop(context);
        }
      } catch (e) {
        print("❌ Error al guardar iris: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al guardar la imagen')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar Iris')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_red_eye, size: 64, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "Captura ${_capturas + 1} de $_total\nAcércate y enfoca bien tus ojos",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text('Tomar Foto de Iris'),
              onPressed: _capturas < _total ? _tomarFotoIris : null,
            ),
            const SizedBox(height: 20),
            Text("Fotos capturadas: $_capturas / $_total"),
          ],
        ),
      ),
    );
  }
}
