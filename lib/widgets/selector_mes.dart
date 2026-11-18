import 'package:flutter/material.dart';

import '../tema.dart';
import '../utils/formato.dart';

/// Selector "‹ Noviembre 2026 ›" para cambiar de mes.
///
/// Lo usan la pantalla principal y el Resumen. Al estar en su propio archivo
/// no repetimos código: si mañana cambia el diseño, se cambia aquí una vez.
class SelectorMes extends StatelessWidget {
  final DateTime mes;

  /// Se llama con -1 (mes anterior) o +1 (mes siguiente).
  final ValueChanged<int> onCambiar;

  const SelectorMes({super.key, required this.mes, required this.onCambiar});

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final esMesActual = mes.year == hoy.year && mes.month == hoy.month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Mes anterior',
            onPressed: () => onCambiar(-1),
          ),
          SizedBox(
            width: 170,
            child: Text(
              Formato.mesAnio(mes),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: TemaApp.textoPrincipal,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Mes siguiente',
            // No hay movimientos en el futuro: en el mes actual se desactiva.
            onPressed: esMesActual ? null : () => onCambiar(1),
          ),
        ],
      ),
    );
  }
}