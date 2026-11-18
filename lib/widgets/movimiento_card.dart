import 'dart:io';

import 'package:flutter/material.dart';

import '../models/categorias.dart';
import '../models/movimiento.dart';
import '../tema.dart';
import '../utils/formato.dart';

/// Tarjeta de un movimiento en la lista principal.
class MovimientoCard extends StatelessWidget {
  final Movimiento movimiento;
  final VoidCallback onTap;

  const MovimientoCard({
    super.key,
    required this.movimiento,
    required this.onTap,
  });

  /// Etiqueta única para la animación Hero. La pantalla de detalle usará
  /// exactamente la misma, y así Flutter sabe qué imagen "volar" entre pantallas.
  static String tagHero(int? id) => 'movimiento-$id';

  @override
  Widget build(BuildContext context) {
    // Si no hay descripción, mostramos la categoría como título.
    final titulo = movimiento.descripcion.isEmpty
        ? movimiento.categoria
        : movimiento.descripcion;

    return Card(
      // InkWell da el efecto de "onda" al tocar (S12: gestos).
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Hero(
                tag: tagHero(movimiento.id),
                child: _miniatura(),
              ),
              const SizedBox(width: 12),

              // Título y "Categoría · fecha"
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // "Texto muy lar…"
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: TemaApp.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${movimiento.categoria} · ${Formato.fechaCorta(movimiento.fecha)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: TemaApp.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Monto: verde con "+" si es ingreso, oscuro con "−" si es egreso.
              Text(
                Formato.montoConSigno(movimiento.monto, movimiento.esIngreso),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: movimiento.esIngreso
                      ? TemaApp.verde
                      : TemaApp.textoPrincipal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Foto del ticket si existe; si no, el ícono de la categoría.
  Widget _miniatura() {
    if (movimiento.tieneImagen) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(movimiento.rutaImagen!),
          width: 48,
          height: 48,
          fit: BoxFit.cover, // Recorta la foto para llenar el cuadro.
          // Si el archivo ya no existe, mostramos el ícono en vez de fallar.
          errorBuilder: (context, error, stackTrace) => _iconoCategoria(),
        ),
      );
    }
    return _iconoCategoria();
  }

  Widget _iconoCategoria() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: TemaApp.borde.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Categorias.iconoDe(movimiento.tipo, movimiento.categoria),
        color: TemaApp.textoPrincipal,
        size: 22,
      ),
    );
  }
}