import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PalmRegister extends StatelessWidget {
  final VoidCallback onComplete;
  PalmRegister({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar Palma')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pan_tool, size: 64, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "Coloca la palma abierta y centrada frente a la cámara",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.camera),
              label: Text('Tomar Foto de Palma'),
              onPressed: () async {
                final picker = ImagePicker();
                final pickedFile =
                    await picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  try {
                    final dir = await getApplicationDocumentsDirectory();
                    final filename =
                        "palma_${DateTime.now().millisecondsSinceEpoch}.jpg";
                    final newPath = "${dir.path}/$filename";
                    final savedFile = await File(pickedFile.path).copy(newPath);
                    print('📷 Guardado: $newPath');
                    onComplete();
                    Navigator.pop(context);
                  } catch (e) {
                    print("❌ Error al guardar imagen: $e");
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
