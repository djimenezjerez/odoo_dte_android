import 'package:flutter/material.dart';

class PantallaError extends StatelessWidget {
  final String url;                      // URL que no se pudo conectar
  final VoidCallback onRetryConnection;  // Acción para "Reintentar conexión"
  final VoidCallback onOpenConfig;       // Acción para "Configuración"

  const PantallaError({
    super.key,
    required this.url,
    required this.onRetryConnection,
    required this.onOpenConfig,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "No se pudo conectar a la URL ❌",
            style: TextStyle(fontSize: 18),
          ),
          Text(
            url,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetryConnection,
            child: const Text("Reintentar conexión"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onOpenConfig,
            child: const Text("Configuración"),
          ),
        ],
      ),
    );
  }
}
