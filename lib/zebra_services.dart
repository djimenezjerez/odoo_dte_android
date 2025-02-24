import 'package:zebrautil/zebra_device.dart';
import 'package:zebrautil/zebra_printer.dart';
import 'package:zebrautil/zebra_util.dart';
import 'package:flutter/material.dart';
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

  // Stream<List<ZebraDevice>> get onPrintersUpdated {
  //   return _printersController.stream;
  // }

  // Future<void> startScanning() async {
  //   zebraPrinter.startScanning();
  //   // Aquí deberías agregar la lógica para escuchar las impresoras detectadas
  //   zebraPrinter.controller.onDevicesChanged.listen((devices) {
  //     printers = devices;
  //     _printersController.add(printers); // Notificar que la lista ha cambiado
  //   });

  Future<void> startScanning() async{
 // Aquí asumimos que zebraPrinter.controller tiene un método o un flujo para recibir los dispositivos.
    zebraPrinter.startScanning();
    getPrinters();
    debugPrint("esta escaneando: ${zebraPrinter.isScanning}");
     debugPrint("Dispositivos detectados: ${printers.length}");
    // controller.onDevicesChanged.listen((devices) {
    //   printers = devices;
    //   _printersController.add(devices);  // Emitir lista actualizada
    //   debugPrint("Dispositivos detectados: ${printers.length}");
    // });
  }

  void stopScanning() {
    zebraPrinter.stopScanning();
  }

  Future<void> connectToPrinter(String address) async {
    try {
      if (zebraPrinter != null) {
        await zebraPrinter.connectToPrinter(address);
        // connectedPrinter = controller.printers.firstWhere((p) => p.address == address);
        // isConnected = true;
        debugPrint("Conectado a ${connectedPrinter!.name}");
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
    if (zebraPrinter != null && isConnected) {
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
