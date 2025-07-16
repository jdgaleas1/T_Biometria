import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import '../biometric_db_helper.dart';
import 'voice_mfcc_ffi.dart';

class VoiceVerify extends StatefulWidget {
  final String email;
  final VoidCallback onSuccess;

  const VoiceVerify({
    super.key,
    required this.email,
    required this.onSuccess,
  });

  @override
  State<VoiceVerify> createState() => _VoiceVerifyState();
}

class _VoiceVerifyState extends State<VoiceVerify> {
  final recorder = FlutterSoundRecorder();
  final List<int> _pcmData = [];
  bool _isRecording = false;
  String? _audioPath;
  String _result = '';
  final int sampleRate = 16000;

  @override
  void initState() {
    super.initState();
    recorder.openRecorder();
  }

  Future<void> _startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    _audioPath = '${dir.path}/verificacion.wav';
    _pcmData.clear();

    final stream = StreamController<Uint8List>();
    stream.stream.listen((data) {
      _pcmData.addAll(data);
    });

    await recorder.startRecorder(
      codec: Codec.pcm16,
      sampleRate: sampleRate,
      toStream: stream.sink,
    );

    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    await recorder.stopRecorder();
    setState(() => _isRecording = false);

    final file = File(_audioPath!);
    final wavBytes = _buildWavFile(_pcmData);
    await file.writeAsBytes(wavBytes);

    _verificarMFCC(file);
  }

  Future<void> _verificarMFCC(File file) async {
    try {
      final currentMFCC = await VoiceMfccFFI.extractMfcc(file.path);
      final storedMFCC =
          await BiometricDBHelper().getTemplate(widget.email, 'voice');
      final sim = _cosineSimilarity(currentMFCC, storedMFCC);

      if (sim >= 0.8) {
        setState(() => _result = '✅ Voz verificada offline ($sim)');
        widget.onSuccess();
      } else {
        setState(() => _result = '❌ Voz no coincide ($sim)');
      }
    } catch (e) {
      print('❌ Error en verificación offline: $e');
      setState(() => _result = '❌ Error verificando voz offline');
    }
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    return dot / (sqrt(normA) * sqrt(normB));
  }

  Uint8List _buildWavFile(List<int> pcmData) {
    const numChannels = 1;
    const bitsPerSample = 16;
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

  @override
  void dispose() {
    recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificar Voz Offline')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? 'Detener' : 'Grabar y verificar'),
              onPressed: _isRecording ? _stopRecording : _startRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            Text(_result, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
