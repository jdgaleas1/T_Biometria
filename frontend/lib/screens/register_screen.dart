import 'package:flutter/material.dart';
import 'voice_register.dart';
import 'ear_register.dart';
import 'iris_register.dart';
import 'face_register.dart';
import 'palm_register.dart';
import 'home_screen.dart';
import 'login_screen.dart'; // Importa también el LoginScreen

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final List<bool> completado = [false, false, false, false, false];
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  void updateState(int index) {
    setState(() {
      completado[index] = true;
    });
  }

  void guardarRegistroBiometrico() {
    print("✅ Registro completado para: ${emailController.text}");
  }

  @override
  Widget build(BuildContext context) {
    final modalities = ['Oído', 'Rostro', 'Palma', 'Iris', 'Voz'];
    final icons = [
      Icons.hearing,
      Icons.face,
      Icons.front_hand, // o pan_tool_alt si prefieres
      Icons.remove_red_eye,
      Icons.record_voice_over,
    ];
    final screens = [
      () => EarRegister(
            onComplete: () => updateState(0),
            email: emailController.text, // Pasamos el email aquí ✅
          ),
      () => FaceRegister(onComplete: () => updateState(1)),
      () => PalmRegister(onComplete: () => updateState(2)),
      () => IrisRegister(onComplete: () => updateState(3)),
      () => VoiceRegister(
            onComplete: () => updateState(4),
            email: emailController.text, // Pasamos el email aquí ✅
          ),
    ];

    double progress = completado.where((e) => e).length / 5;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                'Registrarse',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              SizedBox(height: 20),
              TextField(
                controller: nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombres',
                  labelStyle: TextStyle(color: Colors.redAccent),
                  hintText: 'Ingresa tus nombres completos',
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: apellidoController,
                decoration: InputDecoration(
                  labelText: 'Apellidos',
                  labelStyle: TextStyle(color: Colors.redAccent),
                  hintText: 'Ingresa tus apellidos completos',
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  labelStyle: TextStyle(color: Colors.redAccent),
                  hintText: 'Ingresa tu correo electrónico',
                ),
              ),
              SizedBox(height: 20),

              // Botones de registro biométrico
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(5, (i) {
                  bool isCompleted = completado[i];
                  return SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 30,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isCompleted ? Colors.grey[400] : Colors.teal[600],
                        elevation: isCompleted ? 1 : 5,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icons[i],
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Registrar ${modalities[i]}',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => screens[i]()),
                        );
                      },
                    ),
                  );
                }),
              ),

              SizedBox(height: 20),
              // Barra de progreso
              Center(
                child: Column(
                  children: [
                    Text('${(progress * 100).toInt()}%',
                        style: TextStyle(fontSize: 16)),
                    SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: Colors.grey[300],
                      color: Colors.lightGreen,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),
              // Botón completar registro
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Completar Registro',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  onPressed: (completado.every((e) => e) &&
                          nombreController.text.isNotEmpty &&
                          apellidoController.text.isNotEmpty &&
                          emailController.text.isNotEmpty)
                      ? () {
                          guardarRegistroBiometrico();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(
                                  nombreUsuario: emailController.text),
                            ),
                          );
                        }
                      : null,
                ),
              ),

              SizedBox(height: 15),
              // Link Iniciar sesión
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                    );
                  },
                  child: Text(
                    '¿Ya tienes una cuenta? Inicia Sesión',
                    style: TextStyle(
                        color: Colors.redAccent,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
