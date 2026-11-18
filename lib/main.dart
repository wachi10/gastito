import 'package:flutter/material.dart';

import 'rutas.dart';
import 'screens/detalle_movimiento_screen.dart';
import 'screens/lista_movimientos_screen.dart';
import 'screens/nuevo_movimiento_screen.dart';
import 'screens/resumen_screen.dart';
import 'tema.dart';

/// Punto de entrada de Gastito.
void main() {
  runApp(const GastitoApp());
}

class GastitoApp extends StatelessWidget {
  const GastitoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gastito',
      debugShowCheckedModeBanner: false, // Quita la etiqueta "DEBUG".
      theme: TemaApp.tema,

      // Mapa de rutas con nombre (S17): cada nombre construye su pantalla.
      initialRoute: Rutas.inicio,
      routes: {
        Rutas.inicio: (context) => const ListaMovimientosScreen(),
        Rutas.nuevo: (context) => const NuevoMovimientoScreen(),
        Rutas.detalle: (context) => const DetalleMovimientoScreen(),
        Rutas.resumen: (context) => const ResumenScreen(),
      },
    );
  }
}