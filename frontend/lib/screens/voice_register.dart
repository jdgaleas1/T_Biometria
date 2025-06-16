import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'biometric_db_helper.dart'; // Ajusta tu package
import 'voice_mfcc_ffi.dart';

class VoiceRegister extends StatefulWidget {
  final VoidCallback? onComplete;
  final void Function(List<double>)? onCompleteWithFeatures;
  final bool isVerification;
  final String? email;

  VoiceRegister({
    this.onComplete,
    this.onCompleteWithFeatures,
    this.isVerification = false,
    this.email,
  });

  @override
  _VoiceRegisterState createState() => _VoiceRegisterState();
}

class _VoiceRegisterState extends State<VoiceRegister> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool isRecording = false;
  String? filePath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
  }

  Future<void> _startRecording() async {
    final dir = await getTemporaryDirectory();
    filePath = '${dir.path}/voice_recording.wav'; // <-- graba en WAV
    await _recorder.startRecorder(
      toFile: filePath,
      codec: Codec.pcm16WAV, // <-- clave para grabar en PCM WAV
    );
    setState(() => isRecording = true);
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() => isRecording = false);
    if (filePath != null) {
      await uploadVoiceFile(File(filePath!));
    }
  }

  Future<void> uploadVoiceFile(File file) async {
    await Future.delayed(Duration(seconds: 1)); // Simulación de envío
    print("✅ Archivo de voz procesado: ${file.path}");
  }

  Future<List<double>> procesarVoz(File file) async {
    print("📤 Extrayendo MFCCs reales...");
    final mfccFeatures = VoiceMfccFFI.extractMfcc(file.path);
    print("✅ MFCCs extraídos: ${mfccFeatures.length} coeficientes.");
    return mfccFeatures;
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isVerification ? 'Verificar Voz' : 'Registrar Voz'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(isRecording ? Icons.stop : Icons.mic),
              label: Text(isRecording ? 'Detener' : 'Grabar Voz'),
              onPressed: isRecording ? _stopRecording : _startRecording,
            ),
            SizedBox(height: 20),
            if (filePath != null)
              ElevatedButton(
                child: Text(widget.isVerification
                    ? "Confirmar Verificación de Voz"
                    : "Confirmar Registro de Voz"),
                onPressed: () async {
                  List<double> features = await procesarVoz(File(filePath!));

                  if (widget.isVerification &&
                      widget.onCompleteWithFeatures != null) {
                    widget.onCompleteWithFeatures!(features);
                  } else if (widget.onComplete != null &&
                      widget.email != null) {
                    await BiometricDBHelper()
                        .insertTemplate(widget.email!, 'voice', features);
                    print(
                        '✅ Features de voz guardadas en SQLite para ${widget.email!}');
                    widget.onComplete!();
                  } else {
                    print(
                        "⚠️ No se pudo guardar o devolver features de voz, parámetros faltantes.");
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
