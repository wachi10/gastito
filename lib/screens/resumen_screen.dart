import 'package:flutter/material.dart';

/// Totales por categoría del mes. (Versión temporal del paso 5)
class ResumenScreen extends StatelessWidget {
  const ResumenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen por categoría')),
      body: const Center(child: Text('Aquí irá el resumen')),
    );
  }
}