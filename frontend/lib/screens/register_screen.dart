import 'package:flutter/material.dart';
import 'Voz/voice_register.dart';
import 'Oído/ear_register.dart';
import 'Iris/iris_register.dart';
import 'Rostro/face_register.dart';
import 'Palma/palm_register.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'biometric_db_helper.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final List<bool> completado = [false, false, false, false, false];

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController paisController = TextEditingController();

  bool camposCompletos = false;

  @override
  void initState() {
    super.initState();
    nombreController.addListener(_validarCampos);
    apellidoController.addListener(_validarCampos);
    emailController.addListener(_validarCampos);
    paisController.addListener(_validarCampos);
  }

  void _validarCampos() {
    setState(() {
      camposCompletos = nombreController.text.isNotEmpty &&
          apellidoController.text.isNotEmpty &&
          emailController.text.isNotEmpty &&
          paisController.text.isNotEmpty;
    });
  }

  void updateState(int index) {
    setState(() {
      completado[index] = true;
    });
  }

  Future<void> guardarRegistroBiometrico() async {
    await BiometricDBHelper().insertarUsuarioCompleto(
      email: emailController.text,
      nombres: nombreController.text,
      apellidos: apellidoController.text,
      pais: paisController.text,
      templates: {}, // Aquí luego puedes pasar los vectores biométricos reales
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    emailController.dispose();
    paisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modalities = ['Oído', 'Rostro', 'Palma', 'Iris', 'Voz'];
    final icons = [
      Icons.hearing,
      Icons.face,
      Icons.front_hand,
      Icons.remove_red_eye,
      Icons.record_voice_over,
    ];
    final screens = [
      () => EarRegister(
          onComplete: () => updateState(0), email: emailController.text),
      () => FaceRegister(
          onComplete: () => updateState(1), email: emailController.text),
      () => PalmRegister(
          onComplete: () => updateState(2), email: emailController.text),
      () => IrisRegister(
          onComplete: () => updateState(3), email: emailController.text),
      () => VoiceRegister(
          onComplete: () => updateState(4), email: emailController.text),
    ];

    double progress = completado.where((e) => e).length / 5;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_rounded,
                  size: 80, color: Colors.teal[300]),
              const SizedBox(height: 12),
              Text(
                'Biometría Multimodal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 50),
              Text('Registro Biométrico',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[800],
                      )),
              const SizedBox(height: 30),
              _buildInputField(
                  nombreController, 'Nombres', 'Ingresa tus nombres'),
              const SizedBox(height: 16),
              _buildInputField(
                  apellidoController, 'Apellidos', 'Ingresa tus apellidos'),
              const SizedBox(height: 16),
              _buildInputField(
                  emailController, 'Correo Electrónico', 'ejemplo@correo.com'),
              const SizedBox(height: 16),
              _buildInputField(paisController, 'País', 'Ej. Ecuador'),
              const SizedBox(height: 30),
              Text("Modalidades biométricas",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(5, (i) {
                  bool isCompleted = completado[i];
                  return SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 28,
                    child: ElevatedButton.icon(
                      icon: Icon(icons[i], color: Colors.white),
                      label: Text(' ${modalities[i]}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompleted
                            ? Colors.grey
                            : camposCompletos
                                ? Colors.teal
                                : Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: camposCompletos
                          ? () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => screens[i]()))
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    Text('${(progress * 100).toInt()}% completado',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: (completado.every((e) => e) && camposCompletos)
                    ? () async {
                        await guardarRegistroBiometrico();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HomeScreen(nombreUsuario: emailController.text),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Completar Registro',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  ),
                  child: Text(
                    '¿Ya tienes una cuenta? Inicia Sesión',
                    style: TextStyle(
                      color: Colors.teal[700],
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
      TextEditingController controller, String label, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: Colors.teal[700]),
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.teal.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
      ),
    );
  }
}
