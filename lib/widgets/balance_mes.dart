import 'package:flutter/material.dart';

import '../models/resumen_mes.dart';
import '../tema.dart';
import '../utils/formato.dart';

/// Encabezado de la pantalla principal: balance grande, ingresos y egresos.
class BalanceMes extends StatelessWidget {
  final ResumenMes resumen;

  const BalanceMes({super.key, required this.resumen});

  @override
  Widget build(BuildContext context) {
    final esNegativo = resumen.balance < 0;

    return Column(
      children: [
        // El balance es lo que más resalta en toda la pantalla.
        Text(
          Formato.dinero(resumen.balance),
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            // Rojo suave solo si el balance es negativo (alerta).
            color: esNegativo ? TemaApp.rojoSuave : TemaApp.textoPrincipal,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'balance del mes',
          style: TextStyle(color: TemaApp.textoSecundario),
        ),
        const SizedBox(height: 20),

        // Ingresos | Egresos
        Row(
          children: [
            Expanded(
              child: _dato(
                titulo: 'Ingresos',
                valor: Formato.montoConSigno(resumen.ingresos, true),
                color: TemaApp.verde,
              ),
            ),
            Container(width: 1, height: 36, color: TemaApp.borde),
            Expanded(
              child: _dato(
                titulo: 'Egresos',
                valor: Formato.montoConSigno(resumen.egresos, false),
                color: TemaApp.textoPrincipal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dato({
    required String titulo,
    required String valor,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          titulo,
          style: const TextStyle(color: TemaApp.textoSecundario, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}