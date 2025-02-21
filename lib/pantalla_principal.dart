import 'package:boton_navegador/zebra_services.dart';
import 'package:boton_navegador/btn_flotante.dart';
import 'package:boton_navegador/helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class PantallaPrincipal extends StatelessWidget {
  final String url;                    // URL a cargar en el WebView
  final bool isDownloading;            // Indica si hay una descarga en progreso
  final ValueChanged<bool> onDownloadingChange;
  // Callback para cambiar el estado de isDownloading (true/false)

  final Function(InAppWebViewController) onWebViewCreated;

  const PantallaPrincipal({
    super.key,
    required this.url,
    required this.isDownloading,
    required this.onDownloadingChange,
    required this.onWebViewCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  Stack(
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
                  clearCache: true,
                ),
                onWebViewCreated: (controller) {
                  onWebViewCreated(controller);
                  controller.addJavaScriptHandler(
                    handlerName: "downloadBlob",
                    callback: (args) async {
                      try {
                        onDownloadingChange(true); // Activar estado "descargando"
                        var data = args[0];
                        // var mimeType = args[1];
                        // var contentDisposition = args[2];
                        String base64Data = data.toString().split(',')[1];
                        DateTime fechaActual = DateTime.now();
                        String nombreArchivo = fechaActual.toUtc().millisecondsSinceEpoch.toString();
                        Directory? downloadsDirectory =
                        await getDownloadsDirectory();
                        downloadsDirectory ??= await getApplicationDocumentsDirectory();
                        // ----------------  identificar tipo de archivo-------------------
                        List<int> fileBytes = base64Decode(base64Data);
                        String fileText = utf8.decode(fileBytes, allowMalformed: true);
                        String fileExtension = 'pdf';
                        if (fileText.startsWith('%PDF')) {
                          fileExtension = 'pdf';
                        } else if (fileText.startsWith('^XA') && fileText.endsWith('^XZ')) { 
                          fileExtension = 'zpl';
                        }
                        // --------------------------------------------------------------
                        String filePath = p.join(
                          downloadsDirectory.path,
                          '$nombreArchivo.$fileExtension',
                        );

                        File file = File(filePath);
                        await file.writeAsBytes(base64Decode(base64Data));
                        Fluttertoast.showToast(
                          msg: 'Archivo guardado en: $filePath',
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                        // --------si es zpl mandar a impresora zebra--------------------                    
                        if (fileExtension.contains('zpl')){
                          try{
                            File file = File(filePath);
                            String zplCode = await file.readAsString();                          
                            await ZebraService().printData(zplCode);                            
                          }catch(e){
                            showAlertDialog(context, "Error", "$e");
                          }
                           
                        }
                        //---------------------------------------------------------------
                      } catch (e) {
                        Fluttertoast.showToast(
                          msg: 'Error al descargar: $e',
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0,
                        );
                      } finally {
                        onDownloadingChange(false);
                      }
                    },
                  );
                },
                onCreateWindow: (controller, createWindowRequest) async {
                  // Manejar ventanas nuevas si el sitio hace window.open(...)
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
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
                          onDownloadStartRequest: (controller, urlReq) async {
                            // Manejar descargas en la nueva ventana si quieres
                          },
                        ),
                      ),
                    ),
                  );
                  return true;
                },
                onDownloadStartRequest: (controller, urlRequest) async {
                  onDownloadingChange(true); // activar "descargando"
                  String fileUrl = urlRequest.url.uriValue.toString();
                  if (
                    fileUrl.toLowerCase().startsWith('blob:') ||
                    fileUrl.toLowerCase().startsWith("data:application/octet-stream;base64,") ||
                    ((urlRequest.mimeType?.toLowerCase().startsWith('text/plain') ?? false) && (urlRequest.suggestedFilename?.toLowerCase().endsWith('.zpl')?? false))
                  ) {
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
                    controller.evaluateJavascript(source: jsCode);
                    return;
                  } else {
                    Fluttertoast.showToast(
                      msg: 'Url no reconocido \n $fileUrl',
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      fontSize: 16.0,
                    );
                     onDownloadingChange(false);
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
        // llamada a boton flotante
        BotonImpresoraMovil(
        onPrinterSelected: (impresora) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Conectando a $impresora...")),
            );
          },
        ),
      ],
      ),
      
      // floatingActionButton: BotonImpresoraMovil(
      //   onPrinterSelected: (impresora) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text("Conectando a $impresora...")),
      //     );
      //   },
      // ),
    );
  }
}
