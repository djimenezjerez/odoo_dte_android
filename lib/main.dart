import 'dart:async';
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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          child: Column(children: <Widget>[
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri('http://190.186.18.34:805'),
                ),
                onDownloadStartRequest: (controller, url) async {
                  //Fluttertoast.showToast(msg: 'Start download: ${url.url.host}:${url.url.port}${url.url.path}');
                  if (Platform.isAndroid) {
                    Directory? directory = await getExternalStorageDirectory();
                    if (directory != null) {
                      FileDownloader.downloadFile(
                        url: url.url.uriValue.toString(),
                        onDownloadCompleted: (String path) {
                          Fluttertoast.showToast(
                            msg: 'DESCARGA COMPLETA: $path',
                            backgroundColor: Colors.blue,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        },
                        onDownloadError: (String error) {
                          Fluttertoast.showToast(
                            msg: 'ERROR: $error',
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize: 16.0,
                          );
                        }
                      );
                    }
                  }
                },
              )
            )
          ])
        ),
      ),
    );
  }
}