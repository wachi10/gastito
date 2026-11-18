import 'dart:io';

import 'package:flutter/material.dart';

import '../data/movimiento_repository.dart';
import '../models/categorias.dart';
import '../models/movimiento.dart';
import '../services/image_service.dart';
import '../tema.dart';
import '../utils/formato.dart';
import '../widgets/mapa_movimiento.dart';
import '../widgets/movimiento_card.dart';

/// Detalle de un movimiento: ticket, datos, mapa y opción de eliminar.
class DetalleMovimientoScreen extends StatefulWidget {
  const DetalleMovimientoScreen({super.key});

  @override
  State<DetalleMovimientoScreen> createState() =>
      _DetalleMovimientoScreenState();
}

class _DetalleMovimientoScreenState extends State<DetalleMovimientoScreen> {
  final MovimientoRepository _repositorio = MovimientoRepository();
  final ImageService _imageService = ImageService();
  bool _eliminando = false;

  // ---------------- Lógica ----------------

  Future<void> _confirmarEliminar(Movimiento movimiento) async {
    // Un diálogo de confirmación: borrar no se puede deshacer.
    // showDialog devuelve lo que se pase en Navigator.pop (true o false).
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('¿Eliminar movimiento?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, true),
            style: TextButton.styleFrom(foregroundColor: TemaApp.rojoSuave),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    // Si tocó Cancelar o fuera del diálogo, no hacemos nada.
    if (confirmado != true || !mounted) return;

    setState(() => _eliminando = true);

    try {
      // 1. Borrar el registro de SQLite.
      await _repositorio.eliminar(movimiento.id!);
      // 2. Borrar la foto del teléfono para no dejar archivos huérfanos.
      await _imageService.eliminarImagen(movimiento.rutaImagen);

      if (!mounted) return;
      // 3. Regresar a la lista avisando que se eliminó (true) para que recargue.
      Navigator.pop(context, true);
    } on DatosException catch (e) {
      if (!mounted) return;
      setState(() => _eliminando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje)),
      );
    }
  }

  // ---------------- Interfaz ----------------

  @override
  Widget build(BuildContext context) {
    // Recibimos el movimiento que envió la lista con "arguments" (S17).
    final movimiento =
    ModalRoute.of(context)?.settings.arguments as Movimiento?;

    // Defensa: si por algún motivo no llegó, mostramos un mensaje en vez de fallar.
    if (movimiento == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: const Center(child: Text('No se encontró el movimiento.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(movimiento.esIngreso ? 'Ingreso' : 'Egreso'),
        actions: [
          IconButton(
            tooltip: 'Eliminar',
            onPressed: _eliminando ? null : () => _confirmarEliminar(movimiento),
            icon: _eliminando
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // --- Ticket o ícono, con animación Hero desde la lista ---
          _encabezadoVisual(movimiento),
          const SizedBox(height: 24),

          // --- Monto ---
          Center(
            child: Text(
              Formato.montoConSigno(movimiento.monto, movimiento.esIngreso),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: movimiento.esIngreso
                    ? TemaApp.verde
                    : TemaApp.textoPrincipal,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // --- Categoría ---
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Categorias.iconoDe(movimiento.tipo, movimiento.categoria),
                  size: 18,
                  color: TemaApp.textoSecundario,
                ),
                const SizedBox(width: 6),
                Text(
                  movimiento.categoria,
                  style: const TextStyle(color: TemaApp.textoSecundario),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Descripción y fecha ---
          _tarjetaDatos(movimiento),
          const SizedBox(height: 24),

          // --- Ubicación ---
          _etiqueta('Ubicación'),
          // "if / else" dentro de una lista de widgets: Dart permite elegir
          // cuál widget agregar según una condición.
          if (movimiento.tieneUbicacion)
            MapaMovimiento(
              latitud: movimiento.latitud!,
              longitud: movimiento.longitud!,
            )
          else
            _sinUbicacion(),
        ],
      ),
    );
  }

  /// Foto grande del ticket o, si no hay, el ícono de la categoría.
  /// Usa el MISMO tag Hero que la tarjeta de la lista: así Flutter anima
  /// la miniatura hasta este tamaño al abrir el detalle.
  Widget _encabezadoVisual(Movimiento movimiento) {
    final tag = MovimientoCard.tagHero(movimiento.id);

    if (movimiento.tieneImagen) {
      return Hero(
        tag: tag,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(movimiento.rutaImagen!),
            height: 280,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _iconoGrande(movimiento),
          ),
        ),
      );
    }

    return Center(
      child: Hero(tag: tag, child: _iconoGrande(movimiento)),
    );
  }

  Widget _iconoGrande(Movimiento movimiento) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: TemaApp.borde.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(
        Categorias.iconoDe(movimiento.tipo, movimiento.categoria),
        size: 44,
        color: TemaApp.textoPrincipal,
      ),
    );
  }

  Widget _tarjetaDatos(Movimiento movimiento) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.borde),
      ),
      child: Column(
        children: [
          _filaDato(
            icono: Icons.notes_outlined,
            titulo: 'Descripción',
            valor: movimiento.descripcion.isEmpty
                ? 'Sin descripción'
                : movimiento.descripcion,
          ),
          const Divider(height: 1),
          _filaDato(
            icono: Icons.calendar_today_outlined,
            titulo: 'Fecha',
            valor: Formato.fechaHora(movimiento.fecha),
          ),
        ],
      ),
    );
  }

  Widget _filaDato({
    required IconData icono,
    required String titulo,
    required String valor,
  }) {
    return ListTile(
      leading: Icon(icono, color: TemaApp.textoSecundario),
      title: Text(
        titulo,
        style: const TextStyle(fontSize: 13, color: TemaApp.textoSecundario),
      ),
      subtitle: Text(
        valor,
        style: const TextStyle(fontSize: 15, color: TemaApp.textoPrincipal),
      ),
    );
  }

  Widget _sinUbicacion() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.borde),
      ),
      child: const Row(
        children: [
          Icon(Icons.location_off_outlined, color: TemaApp.textoSecundario),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Este movimiento no tiene ubicación guardada.',
              style: TextStyle(color: TemaApp.textoSecundario),
            ),
          ),
        ],
      ),
    );
  }

  Widget _etiqueta(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: TemaApp.textoSecundario,
        ),
      ),
    );
  }
}