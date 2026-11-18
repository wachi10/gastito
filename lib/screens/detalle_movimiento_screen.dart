import 'package:flutter/material.dart';

/// Detalle de un movimiento: ticket, datos y mapa. (Versión temporal del paso 5)
class DetalleMovimientoScreen extends StatelessWidget {
  const DetalleMovimientoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: const Center(child: Text('Aquí irá el detalle del movimiento')),
    );
  }
}