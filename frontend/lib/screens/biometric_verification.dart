import 'dart:math';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'Oído/ear_register.dart';
import 'Voz/voice_register.dart';
import 'Iris/iris_register.dart';
import 'Rostro/face_register.dart';
import 'Palma/palm_register.dart';
import 'home_screen.dart';
import 'biometric_db_helper.dart';
import 'Rostro/face_verify.dart';
import 'Palma/palm_verify.dart';
import 'Iris/iris_verify.dart';
import 'Oído/ear_verify.dart';
import 'dart:typed_data';
import 'dart:io';

class VoiceNative {
  static final _lib = Platform.isAndroid
      ? ffi.DynamicLibrary.open("libvoice_mfcc.so")
      : ffi.DynamicLibrary.process();

  static final _compare = _lib
      .lookup<
          ffi.NativeFunction<
              ffi.Double Function(
                  ffi.Pointer<ffi.Double>,
                  ffi.Pointer<ffi.Double>,
                  ffi.Int32)>>('compare_voice_features')
      .asFunction<
          double Function(
              ffi.Pointer<ffi.Double>, ffi.Pointer<ffi.Double>, int)>();

  static double comparar(List<double> a, List<double> b) {
    final n = a.length;
    final ptrA = calloc<ffi.Double>(n);
    final ptrB = calloc<ffi.Double>(n);

    for (int i = 0; i < n; i++) {
      ptrA[i] = a[i];
      ptrB[i] = b[i];
    }

    final score = _compare(ptrA, ptrB, n);

    calloc.free(ptrA);
    calloc.free(ptrB);

    return score;
  }
}

class BiometricVerification extends StatefulWidget {
  final String identificador;
  final List<String> selected;

  const BiometricVerification({
    required this.identificador,
    required this.selected,
  });

  @override
  _BiometricVerificationState createState() => _BiometricVerificationState();

  Future<bool> verificarOido(
      List<double> storedFeatures, List<double> currentFeatures) async {
    double sumaCuadrados = 0.0;
    for (int i = 0; i < storedFeatures.length; i++) {
      sumaCuadrados += pow(storedFeatures[i] - currentFeatures[i], 2);
    }
    return sqrt(sumaCuadrados) <= 0.8;
  }

  Future<bool> verificarVoz(
      List<double> storedFeatures, List<double> currentFeatures) async {
    final similarity = VoiceNative.comparar(storedFeatures, currentFeatures);
    return similarity >= 0.8;
  }
}

class _BiometricVerificationState extends State<BiometricVerification> {
  int completed = 0;
  String nombreCompleto = "";
  int? idUsuario;

  @override
  void initState() {
    super.initState();
    cargarPerfil();
  }

  Future<void> cargarPerfil() async {
    try {
      idUsuario =
          await BiometricDBHelper().obtenerIdUsuario(widget.identificador);

      if (idUsuario == null) {
        mostrarMensaje("Usuario no encontrado");
        return;
      }

      final perfil =
          await BiometricDBHelper().obtenerPerfil(widget.identificador);

      setState(() {
        nombreCompleto = "${perfil['nombres']} ${perfil['apellidos']}".trim();
      });
    } catch (_) {
      nombreCompleto = widget.identificador;
    }
  }

  void markCompleted() {
    setState(() => completed++);
    if (completed == 2) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomeScreen(nombreUsuario: widget.identificador),
          ),
        );
      });
    }
  }

  void navigateTo(String option) {
    Widget screen;

    switch (option) {
      case "Voz":
        screen = VoiceRegister(
          isVerification: true,
          onCompleteWithFeatures: (currentFeatures) async {
            try {
              final creds =
                  await BiometricDBHelper().obtenerCredenciales(idUsuario!);
              final match = await widget.verificarVoz(
                _extractFeatures(creds, 'voz'),
                currentFeatures,
              );
              match
                  ? markCompleted()
                  : mostrarMensaje("Verificación de Voz fallida");
            } catch (_) {
              mostrarMensaje("Error cargando features de Voz");
            }
          },
        );
        break;

      case "Oído":
        screen = EarVerify(
          identificador: widget.identificador,
          onSuccess: markCompleted,
          onCompleteWithFeatures: (currentFeatures) async {
            try {
              final creds =
                  await BiometricDBHelper().obtenerCredenciales(idUsuario!);
              final match = await widget.verificarOido(
                _extractFeatures(creds, 'oido'),
                currentFeatures,
              );
              match
                  ? markCompleted()
                  : mostrarMensaje("Verificación de Oído fallida");
            } catch (_) {
              mostrarMensaje("Error cargando features de Oído");
            }
          },
        );
        break;

      case "Iris":
        screen = IrisVerify(
          identificador: widget.identificador,
          onSuccess: markCompleted,
        );
        break;

      case "Rostro":
        screen = FaceVerify(
          identificador: widget.identificador,
          onSuccess: markCompleted,
        );
        break;

      case "Palma":
        screen = PalmVerify(
          identificador: widget.identificador,
          onSuccess: markCompleted,
        );
        break;

      default:
        throw Exception("Modalidad no soportada: $option");
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  List<double> _extractFeatures(
      List<Map<String, dynamic>> lista, String modalidad) {
    final item = lista.firstWhere(
      (c) =>
          c['tipo_biometria'].toString().toLowerCase() ==
          modalidad.toLowerCase(),
      orElse: () => throw Exception('No hay datos para $modalidad'),
    );

    final blob = item['template'] as Uint8List;
    final buffer = Float64List.view(blob.buffer);
    return buffer.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔐 Verificación Biométrica'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '👤 $nombreCompleto',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Selecciona una modalidad para verificar:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.selected.map((mod) {
                return ElevatedButton.icon(
                  onPressed: () => navigateTo(mod),
                  icon: const Icon(Icons.verified_user),
                  label: Text(mod),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            Text("✅ Verificaciones completadas: $completed / 2",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: completed / 2,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            )
          ],
        ),
      ),
    );
  }
}
