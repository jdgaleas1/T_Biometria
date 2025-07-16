import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../api_service.dart';
import '../biometric_db_helper.dart';
import 'voice_mfcc_ffi.dart';

class VoiceRegister extends StatefulWidget {
  final bool isVerification;
  final Function(List<double>)? onCompleteWithFeatures;
  final VoidCallback? onComplete;
  final String? email;

  const VoiceRegister({
    super.key,
    this.isVerification = false,
    this.onCompleteWithFeatures,
    this.onComplete,
    this.email,
  });

  @override
  State<VoiceRegister> createState() => _VoiceRegisterState();
}

class _VoiceRegisterState extends State<VoiceRegister> {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  StreamController<Uint8List>? _streamController;
  final List<int> _pcmData = [];
  bool _isRecording = false;
  String? _audioPath;
  final TextEditingController _emailController = TextEditingController();

  final int sampleRate = 16000;
  final int numChannels = 1;
  final int bitsPerSample = 16;

  bool _tieneInternet = false;
  StreamSubscription<dynamic>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _initAudio();
    _verificarConexion();
  }

  Future<bool> _tieneConexionReal() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _verificarConexion() async {
    final conectado = await _tieneConexionReal();
    if (mounted) {
      setState(() => _tieneInternet = conectado);
    }

    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((_) async {
      final real = await _tieneConexionReal();
      if (mounted) {
        setState(() => _tieneInternet = real);
      }
    });
  }

  Future<void> _initAudio() async {
    await Permission.microphone.request();
    await Permission.storage.request();
    await _recorder!.openRecorder();
    await _player!.openPlayer();
  }

  Future<void> _startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/grabacion.wav';
    _audioPath = path;
    _pcmData.clear();

    _streamController = StreamController<Uint8List>();
    _streamController!.stream.listen((data) {
      _pcmData.addAll(data);
    });

    await _recorder!.startRecorder(
      codec: Codec.pcm16,
      sampleRate: sampleRate,
      numChannels: numChannels,
      toStream: _streamController!.sink,
    );

    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    await _streamController?.close();
    setState(() => _isRecording = false);

    final file = File(_audioPath!);
    final wavBytes = _buildWavFile(_pcmData);
    await file.writeAsBytes(wavBytes);

    final size = await file.length();
    print('📦 WAV guardado: $size bytes');
    if (size < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grabación demasiado corta o vacía')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grabación guardada correctamente')),
      );
    }
  }

  Uint8List _buildWavFile(List<int> pcmData) {
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = pcmData.length;
    final totalSize = 44 + dataSize;

    final header = BytesBuilder();
    header.add(ascii.encode('RIFF'));
    header.add(_intToBytes(totalSize - 8, 4));
    header.add(ascii.encode('WAVE'));
    header.add(ascii.encode('fmt '));
    header.add(_intToBytes(16, 4));
    header.add(_intToBytes(1, 2));
    header.add(_intToBytes(numChannels, 2));
    header.add(_intToBytes(sampleRate, 4));
    header.add(_intToBytes(byteRate, 4));
    header.add(_intToBytes(blockAlign, 2));
    header.add(_intToBytes(bitsPerSample, 2));
    header.add(ascii.encode('data'));
    header.add(_intToBytes(dataSize, 4));
    header.add(pcmData);

    return header.toBytes();
  }

  List<int> _intToBytes(int value, int byteCount) {
    final bytes = <int>[];
    for (int i = 0; i < byteCount; i++) {
      bytes.add(value & 0xFF);
      value >>= 8;
    }
    return bytes;
  }

  Future<void> _reproducirGrabacion() async {
    if (_isRecording || _audioPath == null) return;

    final file = File(_audioPath!);
    if (!file.existsSync()) return;

    await _player!.startPlayer(
      fromURI: file.path,
      codec: Codec.pcm16WAV,
      whenFinished: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reproducción finalizada')),
        );
      },
    );
  }

  String get email => widget.email ?? _emailController.text.trim();

  Future<void> _enviarGrabacion() async {
    if (_audioPath == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falta grabación o correo')),
      );
      return;
    }

    final archivo = File(_audioPath!);

    if (widget.isVerification) {
      await enviarVoz(
        archivo,
        email,
        onResultado: (bool match, double similitud) {
          if (match) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✅ Verificación exitosa ($similitud)')),
            );
            widget.onCompleteWithFeatures
                ?.call(List.generate(13, (i) => i * 1.1)); // simulación
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ Voz no coincide ($similitud)')),
            );
          }
        },
      );
    } else {
      await enviarVoz(
        archivo,
        email,
        onResultado: (bool match, double similitud) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Registro exitoso ($similitud)')),
          );
          widget.onComplete?.call();
        },
      );
    }
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _player?.closePlayer();
    _recorder = null;
    _player = null;
    _streamController?.close();
    _connectivitySubscription?.cancel(); // importante
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Voz')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.email == null)
              TextField(
                controller: _emailController,
                decoration:
                    const InputDecoration(labelText: 'Correo electrónico'),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? 'Detener' : 'Grabar Voz'),
              onPressed: _isRecording ? _stopRecording : _startRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            if (_tieneInternet)
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload),
                label: Text(widget.isVerification
                    ? 'Verificar Voz (Online)'
                    : 'Registrar y enviar (Online)'),
                onPressed: _enviarGrabacion,
              )
            else if (!widget.isVerification)
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt),
                label: const Text('Guardar MFCC (Offline)'),
                onPressed: () async {
                  if (_audioPath == null || email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Falta grabación o correo')),
                    );
                    return;
                  }

                  try {
                    final List<double> mfcc =
                        await VoiceMfccFFI.extractMfcc(_audioPath!);
                    await BiometricDBHelper()
                        .insertTemplate(email, 'voice', mfcc);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('✅ MFCC guardado localmente')),
                    );
                    widget.onComplete?.call();
                  } catch (e) {
                    print('❌ Error MFCC: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Error extrayendo MFCC')),
                    );
                  }
                },
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Reproducir grabación'),
              onPressed: _reproducirGrabacion,
            ),
          ],
        ),
      ),
    );
  }
}
