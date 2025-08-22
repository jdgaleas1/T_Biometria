import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import '../api_service_voice.dart';
import '../biometric_db_helper.dart';
import 'dart:ffi' as ffi;
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

typedef ComputeVoiceMfccNative = ffi.Pointer<ffi.Double> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<ffi.Int32>);
typedef ComputeVoiceMfccDart = Pointer<Double> Function(
    Pointer<Utf8>, Pointer<ffi.Int32>);
typedef FreeMfccNative = ffi.Void Function(ffi.Pointer<ffi.Double>);
typedef FreeMfccDart = void Function(ffi.Pointer<ffi.Double>);

class VoiceNative {
  static final _lib = Platform.isAndroid
      ? ffi.DynamicLibrary.open("libvoice_mfcc.so")
      : ffi.DynamicLibrary.process();

  static final ComputeVoiceMfccDart computeVoiceMfcc = _lib
      .lookup<ffi.NativeFunction<ComputeVoiceMfccNative>>('compute_voice_mfcc')
      .asFunction();

  static final FreeMfccDart freeMfcc =
      _lib.lookup<ffi.NativeFunction<FreeMfccNative>>('free_mfcc').asFunction();

  static List<double> extractMfcc(String filePath) {
    final pathPtr = filePath.toNativeUtf8();
    final numCoefficientsPtr = calloc<ffi.Int32>();

    final mfccPtr = computeVoiceMfcc(pathPtr, numCoefficientsPtr);
    final numCoefficients = numCoefficientsPtr.value;
    final mfccList = List<double>.generate(
        numCoefficients, (i) => mfccPtr.elementAt(i).value);

    freeMfcc(mfccPtr);
    calloc.free(pathPtr);
    calloc.free(numCoefficientsPtr);

    return mfccList;
  }
}

class VoiceRegister extends StatefulWidget {
  final bool isVerification;
  final Function(List<double>)? onCompleteWithFeatures;
  final VoidCallback? onComplete;
  final String? identificador;

  const VoiceRegister({
    super.key,
    this.isVerification = false,
    this.onCompleteWithFeatures,
    this.onComplete,
    this.identificador,
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
  List<File> audiosGrabados = []; // ✅ <--- aquí

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
      setState(() {
        audiosGrabados.add(file); // ✅ Esto actualiza la interfaz correctamente
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('🎧 Grabación ${audiosGrabados.length} guardada')),
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

  String get email => widget.identificador ?? _emailController.text.trim();

  Future<void> _guardarMultiplesAudios() async {
    if (audiosGrabados.length < 1 || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faltan grabaciones o identificador')),
      );
      return;
    }

    try {
      final mfccs = <List<double>>[];

      for (var file in audiosGrabados) {
        mfccs.add(VoiceNative.extractMfcc(file.path));
      }

      final vectorPromedio = List<double>.filled(mfccs.first.length, 0.0);
      for (var i = 0; i < vectorPromedio.length; i++) {
        for (var vec in mfccs) {
          vectorPromedio[i] += vec[i];
        }
        vectorPromedio[i] /= mfccs.length;
      }

      final idUsuario = await BiometricDBHelper().obtenerIdUsuario(email);
      if (idUsuario == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Usuario no encontrado")),
        );
        return;
      }

      await BiometricDBHelper().insertarCredencialBiometrica(
        idUsuario: idUsuario,
        tipoBiometria: 'voz',
        features: vectorPromedio,
        versionAlgoritmo: '1.0',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Audios guardados correctamente')),
      );
      widget.onComplete?.call();
    } catch (e) {
      print('❌ Error procesando MFCCs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Error procesando MFCCs')),
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
      appBar: AppBar(
        title: const Text('🎤 Registro de Voz'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxWidth: 400), // opcional para que no se vea tan extendido
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.identificador == null)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Card(
                  color: Colors.grey.shade100,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          _isRecording
                              ? '🎙️ Grabando...'
                              : 'Presiona para grabar tu voz',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: Icon(
                              _isRecording ? Icons.stop_circle : Icons.mic),
                          label: Text(_isRecording
                              ? 'Detener grabación'
                              : 'Iniciar grabación'),
                          onPressed:
                              _isRecording ? _stopRecording : _startRecording,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isRecording ? Colors.redAccent : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (i) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                i < audiosGrabados.length
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: i < audiosGrabados.length
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '📤 Guardar',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        if (_tieneInternet && !widget.isVerification)
                          (audiosGrabados.length == 1
                              ? ElevatedButton.icon(
                                  icon: const Icon(Icons.cloud_upload),
                                  label:
                                      const Text('Guardar las 1 grabaciones'),
                                  onPressed: _guardarMultiplesAudios,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                )
                              : Text(
                                  "Grabaciones completadas: ${audiosGrabados.length}/1",
                                  style: const TextStyle(color: Colors.grey),
                                ))
                        else if (!widget.isVerification)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save_alt),
                            label: const Text('Guardar grabación'),
                            onPressed: () async {
                              if (_audioPath == null || email.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Falta grabación o correo')),
                                );
                                return;
                              }

                              try {
                                final List<double> mfcc =
                                    VoiceNative.extractMfcc(_audioPath!);
                                final idUsuario = await BiometricDBHelper()
                                    .obtenerIdUsuario(email);
                                if (idUsuario == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text("❌ Usuario no encontrado")),
                                  );
                                  return;
                                }
                                await BiometricDBHelper()
                                    .insertarCredencialBiometrica(
                                  idUsuario: idUsuario,
                                  tipoBiometria: 'voz',
                                  features: mfcc,
                                  versionAlgoritmo: '1.0',
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          '✅ Audio guardado correctamente')),
                                );
                                widget.onComplete?.call();
                              } catch (e) {
                                print('❌ Error MFCC: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('❌ Error extrayendo audio')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Reproducir Grabación'),
                  onPressed: _reproducirGrabacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 171, 89, 238),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
