import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'pantalla_configuracion.dart';
import 'pantalla_error.dart';
import 'pantalla_principal.dart';

/// PRINCIPAL
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.storage.request();
  runApp(const MyApp());
}

/// SECUANDARIO
class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const HomeScreen({super.key});

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
      final contenido = archivoConfig.readAsStringSync();
      final List<String> filas = contenido.split('\n');
      for (var fila in filas) {
        List<String> datos = fila.split('=');
        if (datos[0].toUpperCase() == 'HOST') {
          String valor = datos[1].trim();
          if (valor.isNotEmpty) {
            url = valor;
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
    if (!await verificarConfiguracion()) {
      abrirConfiguracion();
    } else {
      isConnected = await checkUrlConnectionHttpClient(url);
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Abre la pantalla de configuración
  void abrirConfiguracion() async {
    final nuevaUrl = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfigPage(urlActual: url),
      ),
    );

    if (nuevaUrl != null && nuevaUrl is String && nuevaUrl.isNotEmpty) {
      setState(() {
        url = nuevaUrl;
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
            ? PantallaPrincipal(
                  url: url,
              isDownloading: isDownloading,
              onDownloadingChange: (bool newValue) {
                setState(() {
                  isDownloading = newValue;
                });
              },
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
            )
            : buildErrorScreen(),
      ),
    );
  }

  /// Pantalla si no está conectado
  Widget buildErrorScreen() {
    // En lugar de construir manualmente, llamas a tu widget PantallaError
    return PantallaError(
      url: url,
      onRetryConnection: checkConnection,     // Tu método para reintentar
      onOpenConfig: abrirConfiguracion,       // Tu método para abrir configuración
    );
  }
}