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
          body: Container(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri('http://190.186.18.34:805'),
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
                          String base64Data = args[0].toString().split(',')[1];

                          // Obtener la fecha y hora actual
                          DateTime fecha_actual = DateTime.now();
                          String nombre_archivo = "${fecha_actual.day.toString().padLeft(2, '0')}${fecha_actual.month.toString().padLeft(2, '0')}${fecha_actual.year}${fecha_actual.hour.toString().padLeft(2, '0')}${fecha_actual.minute.toString().padLeft(2, '0')}";

                          // Obtener la carpeta de Descargas
                          Directory? downloadsDirectory = await getDownloadsDirectory();
                          if (downloadsDirectory == null) {
                            Fluttertoast.showToast(
                              msg: 'No se pudo acceder a la carpeta de Descargas',
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 16.0,
                            );
                            return;
                          }
                          String filePath = '${directory?.path}/$nombre_archivo.pdf';

                          File file = File(filePath);
                          await file.writeAsBytes(base64Decode(base64Data));

                          Fluttertoast.showToast(
                            msg: 'Archivo guardado en: $filePath',
                            backgroundColor: Colors.green,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        },
                      );
                    },
                    onDownloadStartRequest: (controller, url) async {
                      String fileUrl = url.url.uriValue.toString();
                      debugPrint('**** ----- !!!! URL del archivo: $fileUrl , MimeType: ${url.mimeType}');
                      if (fileUrl.toLowerCase().startsWith('blob:')) {
                        Fluttertoast.showToast(
                          msg: 'Detectado archivo BLOB, intentando descargar...',
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
                        Fluttertoast.showToast(
                          msg: 'Detectado archivo ATTACHMENT, intentando descargar... \n $fileUrl',
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );

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
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ),
        onPopInvokedWithResult: onPopInvokedWithResult,
      )
    );
  }
}
