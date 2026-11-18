/// Representa un movimiento de dinero (ingreso o egreso) registrado en Gastito.
///
/// Es la "entrada del diario": guarda el monto, la categoría, la descripción,
/// la fecha y, de forma opcional, la foto del ticket y la ubicación GPS.
class Movimiento {
  // Valores posibles del campo "tipo". Usamos constantes para no escribir
  // el texto a mano en cada lugar y evitar errores de dedo ("ingreso" vs "Ingreso").
  static const String tipoIngreso = 'ingreso';
  static const String tipoEgreso = 'egreso';

  final int? id; // Lo asigna SQLite al guardar; es null antes de guardarse.
  final String tipo; // tipoIngreso o tipoEgreso.
  final double monto; // Siempre positivo; el tipo indica si suma o resta.
  final String categoria; // Ej. "Comida", "Beca".
  final String descripcion; // Texto escrito o dictado por el usuario.
  final DateTime fecha; // Fecha en que se registró el movimiento.
  final String? rutaImagen; // Ruta de la foto del ticket (opcional).
  final double? latitud; // Coordenadas GPS (opcionales).
  final double? longitud;

  const Movimiento({
    this.id,
    required this.tipo,
    required this.monto,
    required this.categoria,
    required this.descripcion,
    required this.fecha,
    this.rutaImagen,
    this.latitud,
    this.longitud,
  });

  // --- Atajos de lectura (getters) que usarán las pantallas ---

  bool get esIngreso => tipo == tipoIngreso;

  bool get tieneImagen => rutaImagen != null;

  bool get tieneUbicacion => latitud != null && longitud != null;

  // --- Serialización: convertir entre objeto Dart y fila de SQLite ---

  /// Convierte el objeto en un Map para guardarlo en SQLite.
  /// Las llaves son los nombres de las columnas de la tabla.
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Si es null, SQLite genera el id automáticamente.
      'tipo': tipo,
      'monto': monto,
      'categoria': categoria,
      'descripcion': descripcion,
      // SQLite no tiene tipo fecha: la guardamos como texto en formato ISO
      // (ej. "2026-11-17T19:51:00.000"). Este formato se ordena correctamente
      // como texto, lo que nos permitirá filtrar por mes.
      'fecha': fecha.toIso8601String(),
      'ruta_imagen': rutaImagen,
      'latitud': latitud,
      'longitud': longitud,
    };
  }

  /// Crea un Movimiento a partir de una fila leída de SQLite.
  factory Movimiento.fromMap(Map<String, dynamic> map) {
    return Movimiento(
      id: map['id'] as int?,
      tipo: map['tipo'] as String,
      // SQLite puede devolver un número entero (35) aunque se haya guardado
      // como decimal (35.0). Por eso lo leemos como "num" y lo pasamos a double.
      monto: (map['monto'] as num).toDouble(),
      categoria: map['categoria'] as String,
      descripcion: map['descripcion'] as String,
      fecha: DateTime.parse(map['fecha'] as String),
      rutaImagen: map['ruta_imagen'] as String?,
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
    );
  }
}