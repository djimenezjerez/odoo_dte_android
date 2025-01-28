import 'dart:async';
import 'dart:convert'; // Para base64Decode
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
                  onWebViewCreated: (controller) {
                    webViewController = controller;

                    // Agregar el handler para recibir el archivo desde JavaScript
                    webViewController.addJavaScriptHandler(
                      handlerName: "downloadBlob",
                      callback: (args) async {
                        String base64Data = args[0].toString().split(',')[1];

                        Directory? directory = await getExternalStorageDirectory();
                        String filePath = '${directory?.path}/archivo_blob1.pdf';

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
                    debugPrint('URL del archivo: $fileUrl');
                    if (fileUrl.startsWith('blob:')) {
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
                    }

                    // Para descargas normales (NO BLOB)
                    if (Platform.isAndroid || Platform.isIOS) {
                      FileDownloader.downloadFile(
                          url: fileUrl,
                          name: 'archivo_odoo1.pdf',
                          onDownloadCompleted: (String path) {
                            Fluttertoast.showToast(
                              msg: 'Descarga completa: $path',
                              backgroundColor: Colors.blue,
                              textColor: Colors.white,
                              fontSize: 16.0,
                            );
                          },
                          onDownloadError: (String error) {
                            Fluttertoast.showToast(
                              msg: 'Error en la descarga: $error',
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 16.0,
                            );
                          }
                      );
                    }
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
