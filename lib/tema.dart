import 'package:flutter/material.dart';

/// Colores y estilos de Gastito.
///
/// Todo el diseño se define AQUÍ una sola vez. Las pantallas no repiten
/// colores ni bordes: los toman del tema automáticamente.
class TemaApp {
  // --- Paleta minimalista: un solo color de acento (verde) ---
  static const Color verde = Color(0xFF1F7A55); // Acento e ingresos.
  static const Color fondo = Color(0xFFFAFAFA); // Gris casi blanco.
  static const Color textoPrincipal = Color(0xFF1C1C1E); // Casi negro.
  static const Color textoSecundario = Color(0xFF8E8E93); // Gris para datos secundarios.
  static const Color borde = Color(0xFFE5E5EA); // Bordes finos.
  static const Color rojoSuave = Color(0xFFC0392B); // Solo errores y balance negativo.

  static ThemeData get tema {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: verde,
        primary: verde,
        surface: fondo,
      ),
      scaffoldBackgroundColor: fondo,

      // AppBar plano, del mismo color que el fondo y sin sombra.
      appBarTheme: const AppBarThemeData(
        backgroundColor: fondo,
        foregroundColor: textoPrincipal,
        elevation: 0,
        scrolledUnderElevation: 0, // Que no cambie de color al hacer scroll.
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textoPrincipal,
        ),
      ),

      // Tarjetas blancas sin sombra, con borde fino y esquinas redondeadas.
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borde),
        ),
      ),

      // Campos de texto: borde suave que cambia según el estado (S10).
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: verde, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: rojoSuave),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: rojoSuave, width: 2),
        ),
      ),

      // Botón principal (ej. "Guardar"): verde, plano y a todo lo ancho (S12).
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: verde,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52), // Alto de 52, ancho completo.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: verde,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      dividerTheme: const DividerThemeData(color: borde, thickness: 1),
    );
  }
}