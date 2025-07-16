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
import 'Voz/voice_comparator_ffi.dart';
import 'biometric_db_helper.dart';
import 'Rostro/face_verify.dart';
import 'Palma/palm_verify.dart';
import 'Iris/iris_verify.dart';

class BiometricVerification extends StatefulWidget {
  final String email;
  final List<String> selected;

  const BiometricVerification({
    super.key,
    required this.email,
    required this.selected,
  });

  @override
  _BiometricVerificationState createState() => _BiometricVerificationState();

  // Mover las funciones aquí
  Future<bool> verificarOido(
      List<double> storedFeatures, List<double> currentFeatures) async {
    final length = storedFeatures.length;

    double sumaCuadrados = 0.0;

    for (int i = 0; i < length; i++) {
      sumaCuadrados += (storedFeatures[i] - currentFeatures[i]) *
          (storedFeatures[i] - currentFeatures[i]);
    }

    final distance = sqrt(sumaCuadrados);

    print('Distancia Euclidiana (similaridad oído): $distance');

    const threshold = 0.8;
    return distance <= threshold;
  }

  Future<bool> verificarVoz(
      List<double> storedFeatures, List<double> currentFeatures) async {
    final length = storedFeatures.length;

    final storedPtr = calloc<ffi.Double>(length);
    final currentPtr = calloc<ffi.Double>(length);

    for (int i = 0; i < length; i++) {
      storedPtr[i] = storedFeatures[i];
      currentPtr[i] = currentFeatures[i];
    }

    final similarity =
        VoiceComparatorFFI.compareVoiceFeatures(storedPtr, currentPtr, length);

    calloc.free(storedPtr);
    calloc.free(currentPtr);

    print('Similarity voz: $similarity');

    const threshold = 0.8;
    return similarity >= threshold;
  }
}

class _BiometricVerificationState extends State<BiometricVerification> {
  int completed = 0;

  void markCompleted() {
    setState(() {
      completed++;
      print("✅ Modalidad verificada. Total completadas: $completed");
    });

    if (completed == 2) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(nombreUsuario: widget.email),
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
          onCompleteWithFeatures: (List<double> currentFeatures) async {
            try {
              List<double> storedFeatures =
                  await BiometricDBHelper().getTemplate(widget.email, 'voice');

              bool match =
                  await widget.verificarVoz(storedFeatures, currentFeatures);

              if (match) {
                print("✅ Voz verificada con éxito.");
                markCompleted();
              } else {
                print("❌ Voz no coincide.");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Verificación de Voz fallida")),
                );
              }
            } catch (e) {
              print("❌ Error cargando features de Voz: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Error cargando features de Voz")),
              );
            }
          },
        );
        break;

      case "Oído":
        screen = EarRegister(
          isVerification: true,
          onCompleteWithFeatures: (List<double> currentFeatures) async {
            try {
              List<double> storedFeatures =
                  await BiometricDBHelper().getTemplate(widget.email, 'ear');

              bool match =
                  await widget.verificarOido(storedFeatures, currentFeatures);

              if (match) {
                print("✅ Oído verificado con éxito.");
                markCompleted();
              } else {
                print("❌ Oído no coincide.");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Verificación de Oído fallida")),
                );
              }
            } catch (e) {
              print("❌ Error cargando features de Oído: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Error cargando features de Oído")),
              );
            }
          },
        );
        break;

      case "Iris":
        screen = IrisVerify(
          email: widget.email,
          onSuccess: () {
            print("✅ Iris verificado con éxito.");
            markCompleted();
          },
        );
        break;
      case "Rostro":
        screen = FaceVerify(
          email: widget.email,
          onSuccess: () {
            print("✅ Rostro verificado con éxito.");
            markCompleted();
          },
        );
        break;

      case "Palma":
        screen = PalmVerify(
          email: widget.email,
          onSuccess: () {
            print("✅ Palma verificada con éxito.");
            markCompleted();
          },
        );
        break;

      default:
        throw Exception("Modalidad no soportada: $option");
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificación Biométrica')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Correo: ${widget.email}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              'Verifica tu identidad usando:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            for (String option in widget.selected)
              ElevatedButton(
                child: Text("Verificar con $option"),
                onPressed: () => navigateTo(option),
              ),
            const SizedBox(height: 20),
            Text("Progreso: $completed / 2"),
          ],
        ),
      ),
    );
  }
}
