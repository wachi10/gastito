import 'package:flutter/material.dart';

import 'movimiento.dart';

/// Una categoría de movimiento (ej. "Comida") con su ícono
/// y las palabras clave que el dictado usa para reconocerla.
class Categoria {
  final String nombre;
  final IconData icono;

  /// Palabras en minúsculas y SIN acentos. El dictado quitará los acentos
  /// de la frase antes de comparar, así "camión" y "camion" coinciden.
  final List<String> palabrasClave;

  const Categoria({
    required this.nombre,
    required this.icono,
    required this.palabrasClave,
  });
}

/// Catálogo fijo de categorías de Gastito.
/// Todo es "static": se usa directamente, ej. Categorias.egresos.
class Categorias {
  static const List<Categoria> egresos = [
    Categoria(
      nombre: 'Comida',
      icono: Icons.restaurant_outlined,
      palabrasClave: ['comida', 'tacos', 'cafe', 'desayuno', 'comer', 'cena',
        'torta', 'restaurante', 'antojo', 'refresco', 'pizza'],
    ),
    Categoria(
      nombre: 'Transporte',
      icono: Icons.directions_car_outlined,
      palabrasClave: ['uber', 'didi', 'taxi', 'camion', 'metro', 'gasolina',
        'pasaje', 'estacionamiento', 'transporte'],
    ),
    Categoria(
      nombre: 'Escuela',
      icono: Icons.school_outlined,
      palabrasClave: ['escuela', 'copias', 'libro', 'libreta', 'colegiatura',
        'universidad', 'inscripcion', 'impresiones', 'material'],
    ),
    Categoria(
      nombre: 'Entretenimiento',
      icono: Icons.movie_outlined,
      palabrasClave: ['cine', 'netflix', 'spotify', 'fiesta', 'concierto',
        'videojuego', 'juego', 'salida'],
    ),
    Categoria(
      nombre: 'Servicios',
      icono: Icons.receipt_long_outlined,
      palabrasClave: ['luz', 'agua', 'internet', 'telefono', 'recarga',
        'renta', 'gas', 'servicio'],
    ),
    Categoria(
      nombre: 'Otros',
      icono: Icons.more_horiz,
      palabrasClave: [], // Es la opción por defecto si no se reconoce nada.
    ),
  ];

  static const List<Categoria> ingresos = [
    Categoria(
      nombre: 'Beca',
      icono: Icons.emoji_events_outlined,
      palabrasClave: ['beca'],
    ),
    Categoria(
      nombre: 'Sueldo',
      icono: Icons.work_outline,
      palabrasClave: ['sueldo', 'salario', 'quincena', 'nomina', 'trabajo'],
    ),
    Categoria(
      nombre: 'Mesada',
      icono: Icons.volunteer_activism_outlined,
      palabrasClave: ['mesada', 'domingo', 'papas', 'mama'],
    ),
    Categoria(
      nombre: 'Ventas',
      icono: Icons.storefront_outlined,
      palabrasClave: ['venta', 'vendi', 'cliente'],
    ),
    Categoria(
      nombre: 'Otros',
      icono: Icons.more_horiz,
      palabrasClave: [],
    ),
  ];

  /// Devuelve la lista de categorías que corresponde al tipo de movimiento.
  /// La usará el DropdownButton del formulario.
  static List<Categoria> porTipo(String tipo) {
    return tipo == Movimiento.tipoIngreso ? ingresos : egresos;
  }

  /// Busca el ícono de una categoría por su nombre.
  /// Si no la encuentra, devuelve el ícono de "Otros" para no fallar.
  static IconData iconoDe(String tipo, String nombre) {
    for (final categoria in porTipo(tipo)) {
      if (categoria.nombre == nombre) {
        return categoria.icono;
      }
    }
    return Icons.more_horiz;
  }
}