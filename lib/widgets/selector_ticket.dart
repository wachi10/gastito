import 'dart:io';

import 'package:flutter/material.dart';

import '../tema.dart';

/// Recuadro del formulario para agregar la foto del ticket.
///
/// Tiene tres estados: cargando, sin foto (botones) y con foto (vista previa).
/// Solo dibuja: la lógica (abrir cámara, guardar) la decide la pantalla.
class SelectorTicket extends StatelessWidget {
  final String? rutaImagen;
  final bool cargando;
  final VoidCallback onCamara;
  final VoidCallback onGaleria;
  final VoidCallback onQuitar;

  const SelectorTicket({
    super.key,
    required this.rutaImagen,
    required this.cargando,
    required this.onCamara,
    required this.onGaleria,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return Container(
        height: 180,
        decoration: _decoracion(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (rutaImagen != null) {
      return _vistaPrevia();
    }

    return _vistaSinFoto();
  }

  BoxDecoration _decoracion() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: TemaApp.borde),
    );
  }

  Widget _vistaSinFoto() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: _decoracion(),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: TemaApp.textoSecundario,
          ),
          const SizedBox(height: 8),
          const Text(
            'Agregar ticket (opcional)',
            style: TextStyle(color: TemaApp.textoSecundario),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onCamara,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Cámara'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onGaleria,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galería'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vistaPrevia() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      // Stack pone la "X" encima de la foto.
      child: Stack(
        children: [
          Image.file(
            File(rutaImagen!),
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 220,
              color: TemaApp.borde,
              child: const Center(child: Icon(Icons.broken_image_outlined)),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: onQuitar,
              tooltip: 'Quitar foto',
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}