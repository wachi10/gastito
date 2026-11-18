import 'package:flutter/material.dart';

import '../rutas.dart';
import '../widgets/app_drawer.dart';

/// Pantalla principal: movimientos del mes. (Versión temporal del paso 5)
class ListaMovimientosScreen extends StatelessWidget {
  const ListaMovimientosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastito')),
      drawer: const AppDrawer(rutaActual: Rutas.inicio),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Aquí irá la lista de movimientos'),
            const SizedBox(height: 16),
            // Botón temporal para probar la navegación al detalle.
            TextButton(
              onPressed: () => Navigator.pushNamed(context, Rutas.detalle),
              child: const Text('Ver detalle (prueba)'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, Rutas.nuevo),
        tooltip: 'Agregar movimiento',
        child: const Icon(Icons.add),
      ),
    );
  }
}