import 'package:flutter/material.dart';

import '../tema.dart';

/// Botón redondo del micrófono con el texto reconocido en vivo.
class BotonDictado extends StatelessWidget {
  final bool escuchando;
  final String textoReconocido;
  final VoidCallback onPressed;

  const BotonDictado({
    super.key,
    required this.escuchando,
    required this.textoReconocido,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.borde),
      ),
      child: Column(
        children: [
          // GestureDetector detecta el toque (S12).
          GestureDetector(
            onTap: onPressed,
            // AnimatedContainer anima solo el cambio de color (verde ↔ rojo).
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: escuchando ? TemaApp.rojoSuave : TemaApp.verde,
              ),
              child: Icon(
                escuchando ? Icons.stop_rounded : Icons.mic_none_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            escuchando
                ? 'Escuchando… toca para terminar'
                : 'Toca y dicta tu movimiento',
            style: const TextStyle(color: TemaApp.textoSecundario),
          ),

          // Texto en vivo, o un ejemplo si todavía no se ha dicho nada.
          const SizedBox(height: 8),
          Text(
            textoReconocido.isNotEmpty
                ? '"$textoReconocido"'
                : 'Ej. "Me gasté 35 pesos en el Uber"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: textoReconocido.isNotEmpty
                  ? TemaApp.textoPrincipal
                  : TemaApp.textoSecundario.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}