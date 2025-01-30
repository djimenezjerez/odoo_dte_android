import 'dart:async';
import 'dart:convert'; // Para base64Decode
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  String url = 'http://190.186.18.34:8055';
  @override
  void initState() {
    super.initState();
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
  /// llamar a la funcion de verificacion de conexion
  void checkConnection() async {
    setState(() {
      isLoading = true;
    });
    debugPrint("verificando conexion: $isLoading");
    isConnected = await checkUrlConnectionHttpClient(url);
    // isConnected = await checkUrlConnectionHttp(url)
    debugPrint("existe conexion: $isConnected");
    setState(() {
      isLoading = false;
    });
    debugPrint("finalizo verificando conexion: $isLoading");
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

                              String filePath = '${downloadsDirectory?.path}/$nombre_archivo.pdf';

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
                          isDownloading = true; // 🔹 Activa el indicador de carga
                        });

                        String fileUrl = url.url.uriValue.toString();
                        debugPrint('**** ----- !!!! URL del archivo: $fileUrl , MimeType: ${url.mimeType}');
                        if (fileUrl.toLowerCase().startsWith('blob:') || url.mimeType == 'application/pdf' || fileUrl.toLowerCase().startsWith("data:application/octet-stream;base64,")){
                          Fluttertoast.showToast(
                            msg: 'BLOB, intentando descargar... \n ${url.mimeType} \n $fileUrl',
                            backgroundColor: Colors.orange,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );

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
                        Text(
                          "No se pudo conectar a la URL ❌",
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          url, // 🔹 Muestra la URL en una segunda línea
                          style: TextStyle(color: Colors.blueGrey,fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: checkConnection,
                          child: Text("Reintentar conexión"),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: checkConnection,
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