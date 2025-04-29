import 'package:flutter/material.dart';
import 'voz_page.dart';
import 'oido_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biometría Multimodal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Seleccione método de autenticación:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VozPage()),
                );
              },
              icon: Icon(Icons.mic),
              label: Text('Reconocimiento de Voz'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 60),
                backgroundColor: const Color.fromARGB(255, 71, 116, 230),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OidoPage()),
                );
              },
              icon: Icon(Icons.earbuds),
              label: Text('Reconocimiento de Oído'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 60),
                backgroundColor: const Color.fromARGB(255, 71, 116, 230),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
