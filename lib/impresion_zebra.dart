import 'dart:async';
import 'package:flutter/material.dart';
//import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
//import 'dart:convert';
import 'package:zebrautil/zebra_device.dart';
import 'package:zebrautil/zebra_printer.dart';
import 'package:zebrautil/zebra_util.dart';

class ImpresionArchivosZpl{
  late String filePath;
  final BuildContext context; 
  late ZebraPrinter zebraPrinter;
  late ZebraController controller;

  ImpresionArchivosZpl({required this.filePath, required this.context});

  void imprimirArchivo() async {
     File file = File(filePath);
      if (file.existsSync()) { //verificar existencia de archivo
        await buscarImpresora();
      } else {
        _showDialog("Archivo No Encontrado", "No se encontró el archivo $filePath");
      }
  }
  Future<void> buscarImpresora() async {
    var status = await Permission.location.request();
    var status2 = await Permission.bluetoothConnect.request();
    try{
        
      if (status.isGranted && status2.isGranted ){
        zebraPrinter = await ZebraUtil.getPrinterInstance();
        controller = zebraPrinter.controller;
        zebraPrinter.startScanning();
        await Future.delayed(Duration(seconds: 8));
        List<ZebraDevice> dispositivos = controller.printers;
        debugPrint("Impresoras encontradas: ${dispositivos.length}");
        if (dispositivos.isEmpty) {
          _showDialog("No se encontraron impresoras", "Asegúrate de que la impresora esté encendida y en modo Bluetooth.");
          return;
        }
        ZebraDevice printerDevice = dispositivos.first;
        debugPrint("ip: ${printerDevice.address} - nombre: ${printerDevice.name}- estado ${printerDevice.isConnected}");
        if (!printerDevice.isConnected) {
          await zebraPrinter.connectToPrinter(printerDevice.address);
          debugPrint("✅ Conectado a ${printerDevice.name}. estado: ${printerDevice.status}");
        }
        await enviarArchivo();
 
      } else {
        _showDialog("Permiso Denegado", "Se necesitan permisos de ubicación para escanear dispositivos Bluetooth.");
      }
    }catch (e) {
      debugPrint("error: $e");
      _showDialog("ERROR","$e");
    }
  }
  Future<void> enviarArchivo() async {
    File file = File(filePath);
    String zplCode = await file.readAsString();
    debugPrint("archivo ${zplCode}");
    try {
      zebraPrinter.print(data: zplCode);
    } catch (e) {
      _showDialog("ERROR", "Error al enviar el archivo: $e");
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
}