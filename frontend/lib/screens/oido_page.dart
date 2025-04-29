import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // Importa la librería para trabajar con archivos

class OidoPage extends StatefulWidget {
  @override
  _OidoPageState createState() => _OidoPageState();
}

class _OidoPageState extends State<OidoPage> {
  XFile? _image;

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    setState(() {
      _image = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Captura de Oído'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Toque para capturar una imagen del oído.',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Tomar Foto del Oído'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(200, 60),
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
            SizedBox(height: 20),
            _image == null
                ? Text('No se ha tomado una foto aún')
                : Image.file(
                    File(_image!.path),
                    height: 200,
                    width: 200,
                  ),
          ],
        ),
      ),
    );
  }
}
