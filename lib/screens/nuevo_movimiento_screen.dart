import 'package:flutter/material.dart';

/// Formulario para registrar un ingreso o egreso. (Versión temporal del paso 5)
class NuevoMovimientoScreen extends StatelessWidget {
  const NuevoMovimientoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo movimiento')),
      body: const Center(child: Text('Aquí irá el formulario')),
    );
  }
}