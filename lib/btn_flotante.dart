import 'package:boton_navegador/modal_impresoras.dart';
import 'package:flutter/material.dart';


class BotonImpresoraMovil extends StatefulWidget {
  final bool isPrinterConnected;
  final Function(String) onPrinterSelected;
   final VoidCallback? onLongPress;

  const BotonImpresoraMovil({
    super.key,
    required this.isPrinterConnected,
    required this.onPrinterSelected,
    this.onLongPress,
    });
  
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
        onLongPress: widget.onLongPress, // widget para recargar pagina
        child: SizedBox(
          width: 40,
          height: 40,
          child: FloatingActionButton(
            onPressed: () => _mostrarModal(context),
            shape: CircleBorder(),
            child: Stack(
                alignment: Alignment.center,
                children: [
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, // grosor
                        value: 1.0,
                        color: Colors.blueAccent,
                      ),
                    ),
                    Icon(Icons.print, color: widget.isPrinterConnected ? Colors.green :Colors.red),
                  ],
              ),
            //child: Icon(Icons.print, color: widget.isPrinterConnected ? Colors.green :Colors.red),
          ),        
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
