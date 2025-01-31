import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Nuevo import

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
  bool isConnected = false;
  bool isLoading = false;
  String url = 'http://190.186.18.34:8055'; // Valor por defecto

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
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

    if (mounted) {
      setState(() {
        url = newUrl;
        isConnected = false;
        isLoading = true;
      });
    }

    checkConnection();

    if (webViewController != null) {
      await webViewController.loadUrl(
          urlRequest: URLRequest(url: WebUri(newUrl))
      );
    }
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

  void checkConnection() async {
    setState(() => isLoading = true);
    isConnected = await checkUrlConnectionHttpClient(url);
    setState(() => isLoading = false);
  }

  void onPopInvokedWithResult(bool onPop, Object? _) async {
    if (!onPop && await webViewController.canGoBack()) {
      webViewController.goBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(toolbarHeight: 0),
          body: isLoading
              ? Center(child: CircularProgressIndicator())
              : isConnected
              ? Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: InAppWebView(
                      initialUrlRequest: URLRequest(url: WebUri(url)),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        domStorageEnabled: true,
                        supportMultipleWindows: true,
                        useOnDownloadStart: true,
                      ),
                      onPermissionRequest: (controller, request) async {
                        return Future.value(PermissionResponse(
                          resources: request.resources,
                          action: PermissionResponseAction.GRANT,
                        ));
                      },
                      onWebViewCreated: (controller) {
                        webViewController = controller;
                        controller.addJavaScriptHandler(
                            handlerName: "downloadBlob",
                            callback: (args) async {
                              try {
                                setState(() => isDownloading = true);
                                String base64Data =
                                args[0].toString().split(',')[1];
                                Directory? downloadsDirectory =
                                await getDownloadsDirectory();
                                String filePath =
                                    '${downloadsDirectory?.path}/${DateTime.now().toUtc().millisecondsSinceEpoch}.pdf';
                                await File(filePath).writeAsBytes(
                                    base64Decode(base64Data));
                                Fluttertoast.showToast(
                                    msg: 'Archivo guardado: $filePath',
                                    backgroundColor: Colors.green);
                              } catch (e) {
                                Fluttertoast.showToast(
                                    msg: 'Error: $e',
                                    backgroundColor: Colors.red);
                              } finally {
                                setState(() => isDownloading = false);
                              }
                            });
                      },
                      onCreateWindow: (controller, request) async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(
                                      title: Text('Nueva pestaña')),
                                  body: InAppWebView(
                                    initialUrlRequest:
                                    request.request,
                                    initialSettings:
                                    InAppWebViewSettings(
                                        javaScriptEnabled:
                                        true),
                                  ),
                                )));
                        return true;
                      },
                      onDownloadStartRequest:
                          (controller, request) async {
                        setState(() => isDownloading = true);
                        if (request.url.toString().startsWith('blob:')) {
                          String jsCode = """
                                      (async function() {
                                        const response = await fetch("${request.url}");
                                        const blob = await response.blob();
                                        const reader = new FileReader();
                                        reader.readAsDataURL(blob);
                                        reader.onloadend = function() {
                                          window.flutter_inappwebview.callHandler('downloadBlob', reader.result);
                                        }
                                      })();
                                    """;
                          controller.evaluateJavascript(
                              source: jsCode);
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (isDownloading)
                Container(
                  color: Colors.black54,
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConfiguracionScreen(
                          initialUrl: url,
                          onUrlSaved: (newUrl) {
                            _saveUrl(newUrl);
                            Navigator.pop(context); // Cerrar pantalla de configuración
                          },
                        ),
                      ),
                    );
                  },
                  child: Text("Configuración"),
                ),
              ],
            ),
          ),
        ),
        onPopInvokedWithResult: onPopInvokedWithResult,
      ),
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
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurar Servidor'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'URL del servidor',
                  hintText: 'Ej: http://192.168.1.100:8080',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una URL';
                  }
                  if (!value.startsWith('http://') &&
                      !value.startsWith('https://')) {
                    return 'La URL debe comenzar con http:// o https://';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onUrlSaved(_urlController.text.trim());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: Text('Guardar Configuración'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}