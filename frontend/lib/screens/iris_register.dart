import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class IrisRegister extends StatelessWidget {
  final VoidCallback onComplete;
  IrisRegister({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar Iris')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_red_eye, size: 64, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "Acércate y enfoca bien tus ojos en la cámara",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text('Tomar Foto de Iris'),
              onPressed: () async {
                final picker = ImagePicker();
                final pickedFile =
                    await picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  try {
                    final dir = await getApplicationDocumentsDirectory();
                    final filename =
                        "iris_${DateTime.now().millisecondsSinceEpoch}.jpg";
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
