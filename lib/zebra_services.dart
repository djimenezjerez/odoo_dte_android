import 'package:zebrautil/zebra_device.dart';
import 'package:zebrautil/zebra_printer.dart';
import 'package:zebrautil/zebra_util.dart';
import 'package:flutter/material.dart';
class ZebraService {
  static final ZebraService _instance = ZebraService._internal();
  factory ZebraService() => _instance;

  late ZebraPrinter zebraPrinter;
  late ZebraController controller;
  bool isConnected = false;
  List<ZebraDevice> printers = [];
  ZebraDevice? connectedPrinter;

  ZebraService._internal();
  
  // Inicializar la impresora
  Future<void> initPrinter() async {
    zebraPrinter = await ZebraUtil.getPrinterInstance();
    controller = zebraPrinter.controller;
    zebraPrinter.startScanning();
    // if (controller.selectedAddress==null){
    //    zebraPrinter.startScanning();
    // }
   
  }

  void stopScanning() {
    zebraPrinter.stopScanning();
  }

  Future<void> connectToPrinter(String address) async {
    try {
      if (zebraPrinter != null) {
        await zebraPrinter.connectToPrinter(address);
        connectedPrinter = controller.printers.firstWhere((p) => p.address == address);
        isConnected = true;
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
}
