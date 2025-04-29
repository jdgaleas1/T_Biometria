import 'package:flutter/material.dart';

class VozPage extends StatefulWidget {
  @override
  _VozPageState createState() => _VozPageState();
}

class _VozPageState extends State<VozPage> {
  bool _isRecording = false;

  void _startStopRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
    // Aquí iría el código para iniciar/parar la grabación de voz
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Captura de Voz'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Toque el botón para comenzar a grabar la voz.',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _startStopRecording,
              child: Text(
                  _isRecording ? 'Detener Grabación' : 'Iniciar Grabación'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(200, 60),
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
