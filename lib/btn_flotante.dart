import 'package:boton_navegador/modal_impresoras.dart';
import 'package:flutter/material.dart';


class BotonImpresoraMovil extends StatefulWidget {
  final Function(String) onPrinterSelected;

  const BotonImpresoraMovil({super.key, required this.onPrinterSelected});
  
  @override
  _BotonImpresoraMovilState createState() => _BotonImpresoraMovilState();
}
class _BotonImpresoraMovilState extends State<BotonImpresoraMovil> {
  late double posX;
  late double posY;
  late double screenWidth;
  late double screenHeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    
    // posicion inicial
    posX = screenWidth - 80;
    posY = screenHeight - 150;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: posX,
      top: posY,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            posX = (posX + details.delta.dx).clamp(0, screenWidth - 60);
            posY = (posY + details.delta.dy).clamp(0, screenHeight - 120);
          });
        },
        child: FloatingActionButton(
          onPressed: () => _mostrarModal(context),
          child: const Icon(Icons.print),
        ),
      ),
    );
  }

  void _mostrarModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => PrinterModal(
        onPrinterSelected: widget.onPrinterSelected,
      ),
    );
  }
}
