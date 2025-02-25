import 'package:zebrautil/zebra_device.dart';
import 'package:zebrautil/zebra_printer.dart';
import 'package:zebrautil/zebra_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
class ZebraService {
  static final ZebraService _instance = ZebraService._internal();
  factory ZebraService() => _instance;

  late ZebraPrinter zebraPrinter;
  late ZebraController controller;
  late bool isConnected = false;
  List<ZebraDevice> printers = [];
  ZebraDevice? connectedPrinter;

  final StreamController<bool> _connectionStream = StreamController<bool>.broadcast();
  Stream<bool> get onConnectionChanged => _connectionStream.stream;


  ZebraService._internal();
  
  // Inicializar la impresora
  Future<void> initPrinter() async {
    zebraPrinter = await ZebraUtil.getPrinterInstance();
    controller = zebraPrinter.controller;  
  }

  Future<void> startScanning() async{
    // zebraPrinter.startScanning();
    List<BluetoothDevice> bondedDevices = await FlutterBluePlus.bondedDevices;
    try {
      if (bondedDevices.isEmpty) {
         throw Exception("No hay dispositivos vinculados");
      } else {
        List<ZebraDevice> printersDevice = [];
        for (var device in bondedDevices) {
          // Convertir BluetoothDevice a ZebraDevice
          ZebraDevice zebraDevice = ZebraDevice(
            name: device.platformName,
            address: device.remoteId.toString(),
            isConnected: false, 
            status: "Desconectado",
            isWifi: false
          );

          printersDevice.add(zebraDevice);
        }
        // Asignacion de dispositivos encontrados al controlador de ZebraUtil
        for (var device in printersDevice) {
          zebraPrinter.controller.addPrinter(device);
        }
      }
    } catch (e) {
      throw Exception("Error al obtener dispositivos vinculados: $e");
   }
  }

  void stopScanning() {
    zebraPrinter.stopScanning();
  }

  Future<void> connectToPrinter(String address) async {
    try {
      if (zebraPrinter != null) {
        await zebraPrinter.connectToPrinter(address);
        await Future.delayed(Duration(milliseconds: 1000));
        connectedPrinter = controller.printers.firstWhere((p) => p.address == address);
        if (connectedPrinter!.status == "Conectado"){
          isConnected = true;
        }else{
          isConnected = false;
        }
        _connectionStream.add(isConnected);
        debugPrint("Conectado a ${connectedPrinter!.name}- estado: ${connectedPrinter!.status} - ${connectedPrinter!.isConnected}");
      }else{
        throw Exception("Error al conectar");
      }
    } catch (e) {
      throw Exception(e);
    }
  }
  
  Future<void> getPrinters() async {
    if (zebraPrinter != null) {
      printers = controller.printers;
    }
  }

  Future<void> printData(String zplCode) async {
    if (zebraPrinter != null && controller.printers.isNotEmpty) {
      bool conectado = controller.printers.any((p) => p.status == 'Conectado');
      if (conectado){
        zebraPrinter.print(data: zplCode);
      }else{
        throw Exception("No existe ninguna impresora conectado, Conecte alguno y vuelva a intentar la impresión");
      }
    } else {
      throw Exception("No se ha conectado a ninguna impresora");
    }
  }

  void disconnectPrinter() {
    isConnected = false;
    connectedPrinter = null;
    _connectionStream.add(isConnected);
  }
}
