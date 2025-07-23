import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class OrejaClassifier extends StatefulWidget {
  @override
  _OrejaClassifierState createState() => _OrejaClassifierState();
}

class _OrejaClassifierState extends State<OrejaClassifier> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  late Interpreter interpreter;
  final labels = ['oreja_clara', 'oreja_borrosa', 'no_oreja'];
  String resultado = "";

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    interpreter =
        await Interpreter.fromAsset('assets/models/modelo_oreja.tflite');
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final image = File(pickedFile.path);
    setState(() => _image = image);

    final input = await _preprocess(image);
    final output = List.filled(3, 0.0).reshape([1, 3]);
    interpreter.run(input, output);

    final pred = output[0];
    final maxIndex =
        pred.indexWhere((e) => e == pred.reduce((a, b) => a > b ? a : b));
    setState(() {
      resultado = labels[maxIndex];
    });
  }

  Future<List<List<List<List<double>>>>> _preprocess(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    final resized = img.copyResize(decoded!, width: 224, height: 224);

    return [
      List.generate(
          224,
          (y) => List.generate(224, (x) {
                final pixel = resized.getPixel(x, y);
                return [
                  pixel.r / 255.0,
                  pixel.g / 255.0,
                  pixel.b / 255.0,
                ];
              }))
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Clasificador de Oreja')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_image != null) Image.file(_image!, height: 200),
          Text('Resultado: $resultado', style: TextStyle(fontSize: 20)),
          ElevatedButton(
              onPressed: pickImage, child: Text('Seleccionar Imagen')),
        ],
      ),
    );
  }
}
