import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:convert';

class ImpresionArchivosZpl{
  late String filePath;
  final BuildContext context; 
  BluetoothDevice? zebraPrinter;
  BluetoothCharacteristic? writeCharacteristic;

  ImpresionArchivosZpl({required this.filePath, required this.context});

  void imprimirArchivo() async {
     File file = File(filePath);
      if (file.existsSync()) { //verificar existencia de archivo
        buscarImpresora();
      } else {
        _showDialog("Archivo No Encontrado", "No se encontró el archivo $filePath");
      }
  }
  void buscarImpresora() async {
    var status = await Permission.location.request();
    try{
      if (status.isGranted){
        List<BluetoothDevice> bondedDevices = await FlutterBluePlus.bondedDevices; // solo dispositivo vinculado
        debugPrint("Resultados dispositivos vinculado: ${bondedDevices.map((r) => r.platformName).toList()}");
        if (bondedDevices.isNotEmpty) {
          zebraPrinter = bondedDevices.first;
          // zebraPrinter = bondedDevices.last;
          await zebraPrinter!.connect();
          await Future.delayed(Duration(seconds: 2));
          enviarAImpresora();
        }

        // FlutterBluePlus.startScan(timeout: Duration(seconds: 50));
        // FlutterBluePlus.scanResults.listen((List<ScanResult> results) async {
        //   var dispositivosConNombre = results.where((r) => r.device.platformName.isNotEmpty).toList();
        //   debugPrint("Resultados del escaneo: ${results.map((r) => r.device.platformName).toList()}");
        //   debugPrint("Resultados del escane22o: ${results.map((r) => r.device.remoteId).toList()}");
        //   if (dispositivosConNombre.isNotEmpty) {
        //     zebraPrinter = dispositivosConNombre.first.device;
        //     FlutterBluePlus.stopScan();
        //     await zebraPrinter!.connect();
        //     enviarAImpresora();
        //   }
        // });
      } else {
        _showDialog("Permiso Denegado", "Se necesitan permisos de ubicación para escanear dispositivos Bluetooth.");
      }
    }catch (e) {
      debugPrint("error: $e");
      _showDialog("ERROR","$e");
    }
  }
  void enviarAImpresora() async {
    if (zebraPrinter!=null){
      //_showDialog("Conectado", "Conectado a la impresora ${zebraPrinter!.platformName}"); 
      try{
        List<BluetoothService> services = await zebraPrinter!.discoverServices();
        for (BluetoothService service in services) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.properties.write) {
              writeCharacteristic = characteristic;
              await enviarArchivo(characteristic);
              break;
            }
          }
        }
      }catch (e) {
        _showDialog("ERROR","Error al enviar el archivo: $e");
      }
    }else{
      _showDialog("⚠️","No se encontro Impresora");
    }
  }
  Future<void> enviarArchivo(BluetoothCharacteristic characteristic) async {
  try {
    File file = File(filePath);
    String zplCode = await file.readAsString();
    List<int> zplBytes = utf8.encode(zplCode);
    int fragmentSize = 135;
    int totalBytes = zplBytes.length;
    for (int i = 0; i < totalBytes; i += fragmentSize) {
      List<int> fragment = zplBytes.sublist(i, (i + fragmentSize) < totalBytes ? (i + fragmentSize) : totalBytes);
      await writeCharacteristic!.write(fragment, withoutResponse: false);
      await Future.delayed(Duration(milliseconds: 50));
     }
    // await writeCharacteristic!.write(zplBytes, withoutResponse: false);
  } catch (e) {
    debugPrint("Error al enviar el archivo: $e");
    //_showDialog("ERROR","❌ Error al enviar el archivo: $e");
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