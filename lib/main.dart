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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.storage.request();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late InAppWebViewController webViewController;
  bool isDownloading = false;
  bool isConnected = false; // variable para verificar conexion de servidor
  bool isLoading = false; // se pone en True mientras se realiza la verficacion de conexion, al  finalizar la verificacion de conex se pone en false
  String url = '';
  @override
  void initState() {
    super.initState();
    checkConnection();
  }

  Future<void> _loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      url = prefs.getString('server_url') ?? 'http://190.186.18.34:8055';
    });
    checkConnection();
  }

  Future<void> _saveUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', newUrl);
    setState(() {
      url = newUrl;
      isConnected = false;
      isLoading = true;
    });
    if (webViewController != null) {
      await webViewController.loadUrl(
          urlRequest: URLRequest(url: WebUri(newUrl)));
    }
    checkConnection();
  }

  /// Verificar conexion con 'HttpClient'
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
    try
    {
      Directory directorioBase = await getApplicationDocumentsDirectory();
      File archivoConfig = await File(p.join(directorioBase.path, 'Config.ini'));
      if (!archivoConfig.existsSync()) {
        archivoConfig.writeAsStringSync('HOST=');
      }
      final contenido = await archivoConfig.readAsString();
      final List<String> filas = contenido.split('\n');
      filas.forEach((fila) {
        List<String> datos = fila.split('=');
        if (datos[0].toUpperCase() == 'HOST') {
          String valor = datos[1].trim();
          if (valor.length > 0) {
            this.url = valor;
            resultado = true;
          }
        }
      });
      if (!resultado) {
        archivoConfig.writeAsStringSync('HOST=');
      }
    }
    catch (e) {}
    finally {
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

  void abrirConfiguracion() {
    // TODO: Abrir la ventana de configuración
    debugPrint("\n\n ******** NAVEGAR A LA PÁGINA DE CONFIGURACIÓN ******** \n\n");
  }

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
    return MaterialApp(
      home: PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 0,
          ),
          body: isLoading
            ? Center(child: CircularProgressIndicator()) // Muestra el loader mientras se verifica la conexión
            : isConnected
          ? Stack(
            children: [
              Column(
                children: <Widget>[
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
                      /*
                      gestureRecognizers: Set()
                        ..add(Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()
                            ..onDown = (DragDownDetails dragDownDetails) {
                              webViewController.getScrollY().then((value) {
                                if (value == 0 && dragDownDetails.globalPosition.direction < 1) {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  webViewController.reload();
                                  this.checkConnection();
                                }
                              });
                            }
                          )
                        ),
                      */
                      onPermissionRequest: (controller, request) async {
                        return PermissionResponse(
                            resources: request.resources,
                            action: PermissionResponseAction.GRANT);
                      },
                      onWebViewCreated: (controller) {
                        this.webViewController = controller;

                        // Agregar el handler para recibir el archivo desde JavaScript
                        webViewController.addJavaScriptHandler(
                          handlerName: "downloadBlob",
                          callback: (args) async {
                            try {
                              setState(() {
                                isDownloading = true;
                              });

                              String base64Data = args[0].toString().split(',')[1];

                              // Obtener la fecha y hora actual
                              DateTime fecha_actual = DateTime.now();
                              String nombre_archivo = fecha_actual.toUtc().millisecondsSinceEpoch.toString();

                              // Obtener la carpeta de Descargas
                              Directory? downloadsDirectory = await getDownloadsDirectory();
                              if (downloadsDirectory == null) {
                                downloadsDirectory = await getApplicationDocumentsDirectory();
                              }

                              String filePath = p.join(downloadsDirectory.path, '$nombre_archivo.pdf');

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
                              setState(() {
                                isDownloading = false;
                              });
                            }
                          },
                        );
                      },
                      // ESTE ES EL MANEJO DE VENTANA NUEVA
                      onCreateWindow: (controller, createWindowRequest) async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) {
                            return Scaffold(
                              appBar: AppBar(
                                title: Text('Nueva pestaña'),
                              ),
                              body: InAppWebView(
                                initialUrlRequest: createWindowRequest.request,
                                initialSettings: InAppWebViewSettings(
                                  javaScriptEnabled: true,
                                  domStorageEnabled: true,
                                  supportMultipleWindows: true,
                                ),
                                onDownloadStartRequest: (controller, url) async {
                                },
                              ),
                            );
                          }),
                        );
                        return true;
                      },
                      onDownloadStartRequest: (controller, url) async {
                        setState(() {
                          isDownloading = true; //Activa el indicador de carga
                        });

                        String fileUrl = url.url.uriValue.toString();
                        debugPrint('**** ----- !!!! URL del archivo: $fileUrl , MimeType: ${url.mimeType}');
                        if (fileUrl.toLowerCase().startsWith('blob:') || url.mimeType == 'application/pdf' || fileUrl.toLowerCase().startsWith("data:application/octet-stream;base64,")){
                          // Ejecuta JavaScript para convertir el Blob en un archivo descargable
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
                          debugPrint('**** ----- else');
                          Fluttertoast.showToast(
                            msg: 'Url no reconocido \n $fileUrl',
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
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ]
          )
          : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("No hay conexión con el servidor ❌",
                    style: TextStyle(fontSize: 18)),
                Text(url,
                    style: TextStyle(color: Colors.blueGrey),
                    textAlign: TextAlign.center),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: checkConnection,
                  child: Text("Reintentar conexión"),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConfiguracionScreen(
                        initialUrl: url,
                        onUrlSaved: _saveUrl,
                      ),
                    ),
                  ),
                  child: Text("Configuración"),
                ),
              ],
            ),
          ),
        ),
        onPopInvokedWithResult: onPopInvokedWithResult,
      )
    );
  }
}

// Nueva pantalla de configuración
class ConfiguracionScreen extends StatefulWidget {
  final String initialUrl;
  final Function(String) onUrlSaved;

  const ConfiguracionScreen(
      {required this.initialUrl, required this.onUrlSaved});

  @override
  _ConfiguracionScreenState createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Configurar Servidor')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL del servidor',
                hintText: 'Ej: http://192.168.1.100:8080',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (_urlController.text.trim().isNotEmpty) {
                      widget.onUrlSaved(_urlController.text.trim());
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}