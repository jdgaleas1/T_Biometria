import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class IrisRegister extends StatefulWidget {
  final VoidCallback onComplete;
  final String identificador;

  IrisRegister({required this.onComplete, required this.identificador});

  @override
  _IrisRegisterState createState() => _IrisRegisterState();
}

class _IrisRegisterState extends State<IrisRegister>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  int _capturas = 0;
  final int _total = 3;
  List<File> _irisPhotos = [];

  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _tomarFotoIris() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final filename = 'iris_${widget.identificador}_${_capturas + 1}.jpg';
        final path = '${dir.path}/$filename';
        final savedFile = await File(pickedFile.path).copy(path);

        setState(() {
          _capturas++;
          _irisPhotos.add(savedFile);
        });

        if (_capturas == _total) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Registro de iris completado")),
          );

          widget.onComplete();
          Navigator.pop(context);
        }
      } catch (e) {
        print("❌ Error al guardar iris: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Error al guardar la imagen')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final faltan = _total - _capturas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('👁️ Registro de Iris'),
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

            // Ícono con animación suave
            AnimatedBuilder(
              animation: _opacity,
              builder: (context, child) => Opacity(
                opacity: _opacity.value,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.teal,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: const Icon(Icons.remove_red_eye,
                      size: 48, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "Captura ${_capturas + 1} de $_total",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Mantén tus ojos abiertos, enfocados y cerca de la cámara.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(faltan > 0
                  ? 'Tomar Foto ($faltan restantes)'
                  : 'Registro completo'),
              onPressed: _capturas < _total ? _tomarFotoIris : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Vista previa de las fotos
            if (_irisPhotos.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _irisPhotos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _irisPhotos[i],
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

            // Barra de progreso elegante
            LinearProgressIndicator(
              value: _capturas / _total,
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
