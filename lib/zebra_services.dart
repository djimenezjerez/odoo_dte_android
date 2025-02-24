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

  final StreamController<List<ZebraDevice>> _printersController = StreamController<List<ZebraDevice>>.broadcast();
  Stream<List<ZebraDevice>> get onPrintersUpdated => _printersController.stream;

  ZebraService._internal();
  
  // Inicializar la impresora
  Future<void> initPrinter() async {
    zebraPrinter = await ZebraUtil.getPrinterInstance();
    controller = zebraPrinter.controller;  
  }

  Future<void> startScanning() async{
 // Aquí asumimos que zebraPrinter.controller tiene un método o un flujo para recibir los dispositivos.
    // zebraPrinter.startScanning();
    List<BluetoothDevice> bondedDevices = await FlutterBluePlus.bondedDevices;
    debugPrint("Resultados dispositivos vinculado: ${bondedDevices.map((r) => r.platformName).toList()}");
     debugPrint("Dispositivos detectados: ${zebraPrinter.controller.printers.length}");
    try {
    // Obtener dispositivos Bluetooth conectados
   
    
    if (bondedDevices.isEmpty) {
      debugPrint("No hay dispositivos vinculados");
    } else {
      List<ZebraDevice> zebraDevices = [];

      for (var device in bondedDevices) {
        debugPrint("Dispositivo encontrado: ${device.platformName} - ${device.remoteId}");

        // Convertir BluetoothDevice a ZebraDevice
        ZebraDevice zebraDevice = ZebraDevice(
          name: device.platformName,
          address: device.remoteId.toString(),
          isConnected: false, // Lo estableces a false porque aún no está conectado
          status: "Desconectado",
          isWifi: false
        );

        zebraDevices.add(zebraDevice);
      }

      // Asignar dispositivos encontrados al controlador de Zebra
      for (var device in zebraDevices) {
         zebraPrinter.controller.addPrinter(device);
      }
      

      debugPrint("Se han asignado ${zebraPrinter.controller.printers.length} impresoras Zebra");
    }
  } catch (e) {
    debugPrint("Error al obtener dispositivos vinculados: $e");
  }
  }

  void stopScanning() {
    zebraPrinter.stopScanning();
  }

  Future<void> connectToPrinter(String address) async {
    try {
      debugPrint("zebra printer; ${zebraPrinter}");
      if (zebraPrinter != null) {
        await zebraPrinter.connectToPrinter(address);
        // connectedPrinter = controller.printers.firstWhere((p) => p.address == address);
        // isConnected = true;
        //debugPrint("Conectado a ${connectedPrinter!.name}");
      }else{
        throw Exception("Error al conectar");
      }
    } catch (e) {
      debugPrint("Error al conectar: $e");
      throw Exception(e);
    }
  }
  
  Future<void> getPrinters() async {
    if (zebraPrinter != null) {
      printers = controller.printers;
    }
  }

  Future<void> printData(String zplCode) async {
    if (zebraPrinter != null) {
      zebraPrinter.print(data: zplCode);
    } else {
      throw Exception("No se ha conectado a ninguna impresora");
    }
  }

  void setPrinter(ZebraDevice printer){
    connectedPrinter = printer;
    _connectionStream.add(printer.isConnected);
     debugPrint("Conectado a prueba ${printer.name}-${printer.status}");
  }

  ZebraDevice getPrinter(){
     debugPrint("Conectado a prueba get ${connectedPrinter!.name}-${connectedPrinter!.status}");
    return connectedPrinter!;
  }
  void disconnectPrinter() {
    isConnected = false;
    connectedPrinter = null;
    _connectionStream.add(isConnected);
    debugPrint("Impresora desconectada");
  }
}
