import 'package:flutter/material.dart';

import '../rutas.dart';
import '../tema.dart';

/// Menú lateral de Gastito.
///
/// Vive en su propio archivo (S14): si estuviera dentro de la pantalla,
/// esa clase tendría dos responsabilidades y rompería el principio
/// de responsabilidad única (SRP) de SOLID.
class AppDrawer extends StatelessWidget {
  /// Ruta de la pantalla que abrió el Drawer, para resaltar la opción actual.
  final String rutaActual;

  const AppDrawer({super.key, required this.rutaActual});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: TemaApp.fondo,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Encabezado ---
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 4),
              child: Text(
                'Gastito',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: TemaApp.verde,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'Tus finanzas, sin complicaciones',
                style: TextStyle(color: TemaApp.textoSecundario),
              ),
            ),
            const Divider(),

            // --- Opciones ---
            _opcion(
              context,
              icono: Icons.list_alt_outlined,
              texto: 'Movimientos',
              ruta: Rutas.inicio,
            ),
            _opcion(
              context,
              icono: Icons.pie_chart_outline,
              texto: 'Resumen por categoría',
              ruta: Rutas.resumen,
            ),

            const Spacer(), // Empuja lo siguiente hasta abajo.
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Versión 1.0',
                style: TextStyle(color: TemaApp.textoSecundario, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye una opción del menú.
  Widget _opcion(
      BuildContext context, {
        required IconData icono,
        required String texto,
        required String ruta,
      }) {
    final seleccionada = ruta == rutaActual;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(icono),
        title: Text(texto),
        selected: seleccionada,
        selectedColor: TemaApp.verde,
        selectedTileColor: TemaApp.verde.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          // 1. El Drawer es una ruta (S14): primero lo cerramos con pop.
          Navigator.pop(context);

          // 2. Si ya estamos en esa pantalla, no hacemos nada más.
          //    Así no se apilan pantallas repetidas en el Navigator.
          if (seleccionada) return;

          // 3. Abrimos la pantalla elegida encima de la actual.
          Navigator.pushNamed(context, ruta);
        },
      ),
    );
  }
}