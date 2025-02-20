import 'package:flutter/material.dart';
import 'package:zebrautil/zebra_device.dart';
import 'package:zebrautil/zebra_printer.dart';
import 'package:zebrautil/zebra_util.dart';

class BotonImpresoraMovil extends StatefulWidget {
  final Function(String) onPrinterSelected;

  const BotonImpresoraMovil({super.key, required this.onPrinterSelected});

  @override
  _BotonImpresoraMovilState createState() => _BotonImpresoraMovilState();
}

class _BotonImpresoraMovilState extends State<BotonImpresoraMovil> {
  Offset position = const Offset(20, 20); // Posición inicial
  List<ZebraDevice> impresoras = []; // Lista para almacenar impresoras detectadas
  bool escaneando = false;

  late ZebraPrinter zebraPrinter;
  late ZebraController controller;


  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            position = Offset(position.dx + details.delta.dx, position.dy + details.delta.dy);
          });
        },
        child: FloatingActionButton(
          onPressed: () => _mostrarModal(context),
          child: const Icon(Icons.print),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }

  void _mostrarModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Selecciona una impresora",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: _buscarImpresoras,
                child: escaneando
                    ? const CircularProgressIndicator()
                    : const Text("🔍 Escanear dispositivos"),
              ),
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text("Impresora Zebra 1"),
                onTap: () {
                  Navigator.pop(context);
                  widget.onPrinterSelected("Impresora Zebra 1");
                },
              ),
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text("Impresora Zebra 2"),
                onTap: () {
                  Navigator.pop(context);
                  widget.onPrinterSelected("Impresora Zebra 2");
                },
              ),
              //  Expanded(
              //   child: impresoras.isEmpty
              //       ? const Center(child: Text("No se encontraron impresoras"))
              //       : ListView.builder(
              //           itemCount: impresoras.length,
              //           itemBuilder: (context, index) {
              //             ZebraDevice impresora = impresoras[index];
              //             return ListTile(
              //               title: Text(impresora.name),
              //               subtitle: Text(impresora.status,
              //                   style: TextStyle(color: impresora.color)),
              //               leading: IconButton(
              //                 icon: Icon(Icons.print, color: impresora.color),
              //                 onPressed: () {
              //                   zebraPrinter.print(data: "^XA\n^FO50,50^B3N,N,100,Y,N\n^FD>:123456^FS\n^XZ");
              //                 },
              //               ),
              //               trailing: IconButton(
              //                 icon: Icon(Icons.bluetooth_connected_rounded,
              //                     color: impresora.color),
              //                 onPressed: () {
              //                   // Solo conectar a la impresora seleccionada
              //                   zebraPrinter.connectToPrinter(impresora.address);
              //                   widget.onPrinterSelected(impresora.address);
              //                   Navigator.pop(context); // Cerrar modal
              //                 },
              //               ),
              //             );
              //           },
              //       ),
              //  ),
            ],
          ),
        );
      },
    );
  }

 Future<void> _buscarImpresoras() async {
    
    
  }
}
