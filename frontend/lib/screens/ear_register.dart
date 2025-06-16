import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'biometric_db_helper.dart'; // <--- Asegúrate de importar esto

class EarRegister extends StatefulWidget {
  final VoidCallback? onComplete; // Para registro
  final void Function(List<double>)?
      onCompleteWithFeatures; // Para verificación
  final bool isVerification; // Saber si estamos en verificación
  final String?
      email; // Para saber a qué email asociar las features (en registro)

  EarRegister({
    this.onComplete,
    this.onCompleteWithFeatures,
    this.isVerification = false,
    this.email,
  });

  @override
  _EarRegisterState createState() => _EarRegisterState();
}

class _EarRegisterState extends State<EarRegister> {
  File? imageFile;

  Future<void> _pickImage() async {
    await Permission.camera.request();
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() => imageFile = File(image.path));
      print("📸 Imagen del oído capturada: ${imageFile!.path}");
    }
  }

  Future<List<double>> procesarOido(File file) async {
    // Aquí debes integrar tu código C real (por ahora simulo con randoms)
    await Future.delayed(Duration(seconds: 1));
    return List.generate(128, (index) => Random().nextDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.isVerification ? 'Verificar Oído' : 'Registrar Oído'),
      ),
      body: Center(
        child: imageFile == null
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                      color: Colors.black, width: double.infinity, height: 300),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white, size: 64),
                      SizedBox(height: 10),
                      Text(
                        widget.isVerification
                            ? "Enfoca bien tu oído para la verificación"
                            : "Enfoca bien tu oído para el registro",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: Icon(Icons.camera_alt),
                        label: Text("Tomar Foto del Oído"),
                        onPressed: _pickImage,
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.file(imageFile!, height: 200),
                  SizedBox(height: 10),
                  ElevatedButton(
                    child: Text(widget.isVerification
                        ? "Confirmar Verificación de Oído"
                        : "Confirmar Registro de Oído"),
                    onPressed: () async {
                      List<double> features = await procesarOido(imageFile!);

                      if (widget.isVerification &&
                          widget.onCompleteWithFeatures != null) {
                        // Solo verificación → no guardamos, solo devolvemos features
                        widget.onCompleteWithFeatures!(features);
                      } else if (widget.onComplete != null &&
                          widget.email != null) {
                        // Registro normal → guardamos las features en SQLite
                        await BiometricDBHelper().insertTemplate(
                          widget.email!,
                          'ear',
                          features,
                        );
                        print(
                            '✅ Features de oído guardadas en SQLite para ${widget.email!}');
                        widget.onComplete!();
                      } else {
                        print(
                            "⚠️ No se pudo guardar o devolver features, parámetros faltantes.");
                      }

                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
