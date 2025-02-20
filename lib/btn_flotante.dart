import 'package:boton_navegador/modal_impresoras.dart';
import 'package:flutter/material.dart';

class BotonImpresoraMovil extends StatelessWidget {
  final Function(String) onPrinterSelected;

  const BotonImpresoraMovil({super.key, required this.onPrinterSelected});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
        onPressed: () => _mostrarModal(context),
        child: const Icon(Icons.print),
      ),
    );
  }

  void _mostrarModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => PrinterModal(
        onPrinterSelected: onPrinterSelected,
      ),
    );
  }
}
