import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:async';

class ConfigPage extends StatefulWidget {
  final String urlActual;

  const ConfigPage({Key? key, required this.urlActual}) : super(key: key);

  @override
  _ConfigPageState createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    // Inicializamos el controlador del TextField con la URL actual
    _urlController = TextEditingController(text: widget.urlActual);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// Método para guardar la nueva URL en Config.ini
  Future<void> _guardarNuevaUrl() async {
    String nuevaUrl = _urlController.text.trim();
    if (nuevaUrl.isEmpty) {
      // Podrías mostrar un error, Toast, etc.
      return;
    }

    try {
      Directory directorioBase = await getApplicationDocumentsDirectory();
      File archivoConfig = File(p.join(directorioBase.path, 'Config.ini'));

      // Leemos el contenido actual (si existe)
      String contenido = '';
      if (archivoConfig.existsSync()) {
        contenido = await archivoConfig.readAsString();
      } else {
        archivoConfig.writeAsStringSync('HOST=');
      }

      // Buscamos si existe la línea "HOST=" y la reemplazamos
      List<String> lineas = contenido.split('\n');
      bool encontradoHost = false;

      for (int i = 0; i < lineas.length; i++) {
        List<String> partes = lineas[i].split('=');
        if (partes[0].toUpperCase() == 'HOST') {
          lineas[i] = 'HOST=$nuevaUrl';
          encontradoHost = true;
          break;
        }
      }

      // Si no se encontró, añadimos la línea al final
      if (!encontradoHost) {
        lineas.add('HOST=$nuevaUrl');
      }

      // Guardamos de nuevo el contenido
      String nuevoContenido = lineas.join('\n');
      await archivoConfig.writeAsString(nuevoContenido);

      Navigator.pop(context, nuevaUrl);
    } catch (e) {
      debugPrint('Error guardando la URL: $e');
      // Podrías mostrar un Toast de error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Ingresa la URL de tu servidor:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'Ej. https://mi-servidor.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _guardarNuevaUrl,
              child: const Text('Guardar'),
            ),
            const SizedBox(height: 12),
            FutureBuilder<Directory>(
              future: getApplicationDocumentsDirectory(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                return Text(
                  'La URL se guardará en: ${snapshot.data!.path}/Config.ini',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
