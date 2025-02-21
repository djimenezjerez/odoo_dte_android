import 'package:boton_navegador/zebra_services.dart';
import 'package:flutter/material.dart';

class PrinterModal extends StatefulWidget {
  final Function(String) onPrinterSelected;

  const PrinterModal({super.key, required this.onPrinterSelected});

  @override
  State<PrinterModal> createState() => _PrinterModalState();
}

class _PrinterModalState extends State<PrinterModal> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePrinter();
  }

  Future<void> _initializePrinter() async {
    await ZebraService().initPrinter(); // Usamos el servicio singleton
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    ZebraService().stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              "Seleccione una impresora",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: ListenableBuilder(
                    listenable:  ZebraService().controller,
                    builder: (context, child) {
                      ZebraService().getPrinters();
                      final printers = ZebraService().printers;
                      if (printers.isEmpty) {
                        return const Center(child: Text("No se encontraron impresoras"));
                      }
                      return ListView.builder(
                        itemCount: printers.length,
                        itemBuilder: (context, index) {
                          final printer = printers[index];
                          return ListTile(
                            title: Text(printer.name),
                            subtitle: Text(printer.status, style: TextStyle(color: printer.color)),
                            trailing: Container(
                              decoration: BoxDecoration(
                                  color:  const Color.fromARGB(230, 231, 221, 234), // Color de fondo
                                  shape: BoxShape.circle, // Forma redonda
                                ),
                              child:  IconButton(
                              icon: Icon(Icons.bluetooth_connected_rounded, color: printer.color),
                              onPressed: () {
                                ZebraService().connectToPrinter(printer.address);
                                widget.onPrinterSelected(printer.name);
                                setState(() {});
                                //Navigator.pop(context); // Cerrar modal
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
