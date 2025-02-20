import 'package:flutter/material.dart';

class BotonImpresoraMovil extends StatefulWidget {
  final Function(String) onPrinterSelected;

  const BotonImpresoraMovil({super.key, required this.onPrinterSelected});

  @override
  _BotonImpresoraMovilState createState() => _BotonImpresoraMovilState();
}

class _BotonImpresoraMovilState extends State<BotonImpresoraMovil> {
  Offset position = const Offset(20, 20); // Posición inicial

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
            ],
          ),
        );
      },
    );
  }
}
