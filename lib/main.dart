import 'dart:async';
import 'dart:convert'; // Para base64Decode
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as p;

/// PRINCIPAL
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.storage.request();
  runApp(const MyApp());
}

/// SECUANDARIO
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Quita el debug banner si quieres
      debugShowCheckedModeBanner: false,
      home: HomeScreen(), // Aquí está nuestra pantalla principal
    );
  }
}

/// HomeScreen
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late InAppWebViewController webViewController;
  bool isDownloading = false;
  bool isConnected = false; // variable para verificar conexión de servidor
  bool isLoading = false;   // true mientras se realiza la verificación de conexión
  String url = '';

  @override
  void initState() {
    super.initState();
    checkConnection();
  }

  Future<bool> checkUrlConnectionHttpClient(String url) async {
    try {
      debugPrint("URL: $url");
      final uri = Uri.parse(url);
      final request = await HttpClient().headUrl(uri);
      final response = await request.close();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> verificarConfiguracion() async {
    bool resultado = false;
    try {
      Directory directorioBase = await getApplicationDocumentsDirectory();
      File archivoConfig = File(p.join(directorioBase.path, 'Config.ini'));
      if (!archivoConfig.existsSync()) {
        archivoConfig.writeAsStringSync('HOST=');
      }
      final contenido = await archivoConfig.readAsString();
      final List<String> filas = contenido.split('\n');
      for (var fila in filas) {
        List<String> datos = fila.split('=');
        if (datos[0].toUpperCase() == 'HOST') {
          String valor = datos[1].trim();
          if (valor.isNotEmpty) {
            this.url = valor;
            resultado = true;
          }
        }
      }
      if (!resultado) {
        archivoConfig.writeAsStringSync('HOST=');
      }
    } catch (e) {
      debugPrint("Error leyendo configuración: $e");
    } finally {
      return resultado;
    }
  }

  /// llamar a la funcion de verificacion de conexion
  void checkConnection() async {
    setState(() {
      isLoading = true;
    });
    if (!await this.verificarConfiguracion()) {
      this.abrirConfiguracion();
    } else {
      debugPrint("verificando conexion: $isLoading");
      isConnected = await checkUrlConnectionHttpClient(url);
      // isConnected = await checkUrlConnectionHttp(url)
      debugPrint("existe conexion: $isConnected");
      setState(() {
        isLoading = false;
      });
      debugPrint("finalizo verificando conexion: $isLoading");
    }
  }

  /// Abre la pantalla de configuración
  void abrirConfiguracion() async {
    final nuevaUrl = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfigPage(urlActual: this.url),
      ),
    );

    if (nuevaUrl != null && nuevaUrl is String && nuevaUrl.isNotEmpty) {
      setState(() {
        this.url = nuevaUrl;
      });
      checkConnection();
    }
  }

  /// Manejo para el botón de retroceso (PopScope)
  void onPopInvokedWithResult(bool onPop, Object? _) async {
    if (onPop) {
      return;
    }
    bool canBack = await webViewController.canGoBack();
    if (canBack) {
      webViewController.goBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: onPopInvokedWithResult,
      child: Scaffold(
        appBar: AppBar(toolbarHeight: 0),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : isConnected
            ? buildWebViewContent()
            : buildErrorScreen(),
      ),
    );
  }

  /// Pantalla principal cuando [isConnected] es true
  Widget buildWebViewContent() {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(url),
                  timeoutInterval: 20,
                ),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  supportMultipleWindows: true,
                  useOnDownloadStart: true,
                ),
                onPermissionRequest: (controller, request) async {
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
                onWebViewCreated: (controller) {
                  this.webViewController = controller;

                  // Handler para recibir archivo (base64) desde JS
                  webViewController.addJavaScriptHandler(
                    handlerName: "downloadBlob",
                    callback: (args) async {
                      try {
                        setState(() => isDownloading = true);

                        String base64Data =
                        args[0].toString().split(',')[1];

                        // Crear nombre de archivo con marca de tiempo
                        DateTime fecha_actual = DateTime.now();
                        String nombre_archivo = fecha_actual
                            .toUtc()
                            .millisecondsSinceEpoch
                            .toString();

                        // Obtener carpeta de Descargas
                        Directory? downloadsDirectory =
                        await getDownloadsDirectory();
                        downloadsDirectory ??=
                        await getApplicationDocumentsDirectory();

                        String filePath = p.join(
                          downloadsDirectory.path,
                          '$nombre_archivo.pdf',
                        );

                        File file = File(filePath);
                        await file.writeAsBytes(base64Decode(base64Data));

                        Fluttertoast.showToast(
                          msg: 'Archivo guardado en: $filePath',
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      } catch (e) {
                        Fluttertoast.showToast(
                          msg: 'Error al descargar: $e',
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      } finally {
                        setState(() => isDownloading = false);
                      }
                    },
                  );
                },
                onCreateWindow: (controller, createWindowRequest) async {
                  // Manejar nueva pestaña
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return Scaffold(
                          appBar: AppBar(
                            title: const Text('Nueva pestaña'),
                          ),
                          body: InAppWebView(
                            initialUrlRequest: createWindowRequest.request,
                            initialSettings: InAppWebViewSettings(
                              javaScriptEnabled: true,
                              domStorageEnabled: true,
                              supportMultipleWindows: true,
                            ),
                            onDownloadStartRequest: (controller, url) async {
                              // Maneja descargas en nueva pestaña si quieres
                            },
                          ),
                        );
                      },
                    ),
                  );
                  return true;
                },
                onDownloadStartRequest: (controller, urlRequest) async {
                  setState(() => isDownloading = true);
                  String fileUrl = urlRequest.url.uriValue.toString();
                  debugPrint('URL archivo: $fileUrl, MimeType: ${urlRequest.mimeType}');

                  if (fileUrl.toLowerCase().startsWith('blob:') ||
                      urlRequest.mimeType == 'application/pdf' ||
                      fileUrl.toLowerCase().startsWith("data:application/octet-stream;base64,")) {
                    // Ejecuta JS para convertir Blob en base64
                    String jsCode = """
                      (async function() {
                        const blobUrl = "$fileUrl";
                        const response = await fetch(blobUrl);
                        const blob = await response.blob();
                        const reader = new FileReader();
                        reader.readAsDataURL(blob);
                        reader.onloadend = function() {
                          window.flutter_inappwebview.callHandler('downloadBlob', reader.result);
                        }
                      })();
                    """;
                    webViewController.evaluateJavascript(source: jsCode);
                    return;
                  } else {
                    debugPrint('URL no reconocida');
                    Fluttertoast.showToast(
                      msg: 'Url no reconocido:\n$fileUrl',
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      fontSize: 16.0,
                    );
                  }
                },
              ),
            ),
          ],
        ),
        if (isDownloading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  /// Pantalla si no está conectado
  Widget buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "No se pudo conectar a la URL ❌",
            style: TextStyle(fontSize: 18),
          ),
          Text(
            url,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: checkConnection,
            child: const Text("Reintentar conexión"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: abrirConfiguracion,
            child: const Text("Configuración"),
          ),
        ],
      ),
    );
  }
}

/// Configuracion de pagina
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
    _urlController = TextEditingController(text: widget.urlActual);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// Método para guardar la nueva URL en el archivo Config.ini
  Future<void> _guardarNuevaUrl() async {
    String nuevaUrl = _urlController.text.trim();
    if (nuevaUrl.isEmpty) {
      // Muestra un mensaje o no hagas nada
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

      // Buscamos si existe "HOST=" y lo reemplazamos
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

      // Si no la encontramos, añadimos la línea al final
      if (!encontradoHost) {
        lineas.add('HOST=$nuevaUrl');
      }

      // Escribimos de nuevo todo el contenido
      String nuevoContenido = lineas.join('\n');
      await archivoConfig.writeAsString(nuevoContenido);

      // Retornamos la nueva URL a la pantalla anterior
      Navigator.pop(context, nuevaUrl);
    } catch (e) {
      debugPrint('Error guardando la URL en Config.ini: $e');
      // Podrías mostrar un toast de error
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
                if (!snapshot.hasData) {
                  return const SizedBox();
                }
                final path = snapshot.data!.path;
                return Text(
                  'La URL se guardará en el archivo Config.ini dentro de:\n$path',
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
