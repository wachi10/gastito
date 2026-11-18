import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/movimiento.dart';
import 'database_helper.dart';

/// Error "amigable" de la capa de datos.
///
/// Las pantallas no necesitan saber qué falló dentro de SQLite;
/// solo reciben un mensaje claro para mostrarle al usuario (S18:
/// aislar la capa de datos de la capa de presentación).
class DatosException implements Exception {
  final String mensaje;

  DatosException(this.mensaje);

  @override
  String toString() => mensaje;
}

/// Único punto de acceso a los movimientos guardados.
///
/// Las pantallas NUNCA usan SQLite directamente: le piden todo a esta clase.
/// Si mañana cambiamos SQLite por otra forma de guardar, solo cambia este archivo.
class MovimientoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instancia;

  /// Guarda un movimiento nuevo y devuelve el id que le asignó SQLite.
  Future<int> insertar(Movimiento movimiento) async {
    try {
      final db = await _dbHelper.database;
      return await db.insert(
        DatabaseHelper.tablaMovimientos,
        movimiento.toMap(),
      );
    } on DatabaseException catch (e, stackTrace) {
      _registrarError('insertar', e, stackTrace);
      throw DatosException('No se pudo guardar el movimiento.');
    } catch (e, stackTrace) {
      _registrarError('insertar', e, stackTrace);
      throw DatosException('Ocurrió un error inesperado al guardar.');
    }
  }

  /// Devuelve los movimientos de un mes, del más reciente al más antiguo.
  Future<List<Movimiento>> obtenerPorMes(DateTime mes) async {
    try {
      final db = await _dbHelper.database;
      final (inicio, fin) = _rangoDelMes(mes);

      final filas = await db.query(
        DatabaseHelper.tablaMovimientos,
        // Los "?" se reemplazan por los valores de whereArgs. Así SQLite
        // nunca mezcla datos con instrucciones (evita inyección SQL).
        where: 'fecha >= ? AND fecha < ?',
        whereArgs: [inicio, fin],
        orderBy: 'fecha DESC',
      );

      // Cada fila (Map) se convierte en un objeto Movimiento.
      return filas.map((fila) => Movimiento.fromMap(fila)).toList();
    } on DatabaseException catch (e, stackTrace) {
      _registrarError('obtenerPorMes', e, stackTrace);
      throw DatosException('No se pudieron cargar los movimientos.');
    } catch (e, stackTrace) {
      _registrarError('obtenerPorMes', e, stackTrace);
      throw DatosException('Ocurrió un error inesperado al cargar los datos.');
    }
  }

  /// Elimina un movimiento por su id.
  Future<void> eliminar(int id) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        DatabaseHelper.tablaMovimientos,
        where: 'id = ?',
        whereArgs: [id],
      );
    } on DatabaseException catch (e, stackTrace) {
      _registrarError('eliminar', e, stackTrace);
      throw DatosException('No se pudo eliminar el movimiento.');
    } catch (e, stackTrace) {
      _registrarError('eliminar', e, stackTrace);
      throw DatosException('Ocurrió un error inesperado al eliminar.');
    }
  }

  /// Suma los montos de un mes agrupados por categoría.
  /// Ejemplo de resultado: {'Comida': 450.0, 'Transporte': 120.0}
  /// La usará la pantalla de Resumen.
  Future<Map<String, double>> totalesPorCategoria(
      DateTime mes, String tipo) async {
    try {
      final db = await _dbHelper.database;
      final (inicio, fin) = _rangoDelMes(mes);

      final filas = await db.rawQuery(
        'SELECT categoria, SUM(monto) AS total '
            'FROM ${DatabaseHelper.tablaMovimientos} '
            'WHERE tipo = ? AND fecha >= ? AND fecha < ? '
            'GROUP BY categoria '
            'ORDER BY total DESC',
        [tipo, inicio, fin],
      );

      final totales = <String, double>{};
      for (final fila in filas) {
        totales[fila['categoria'] as String] =
            (fila['total'] as num).toDouble();
      }
      return totales;
    } on DatabaseException catch (e, stackTrace) {
      _registrarError('totalesPorCategoria', e, stackTrace);
      throw DatosException('No se pudo calcular el resumen.');
    } catch (e, stackTrace) {
      _registrarError('totalesPorCategoria', e, stackTrace);
      throw DatosException('Ocurrió un error inesperado en el resumen.');
    }
  }

  // --- Métodos privados de apoyo ---

  /// Calcula el inicio del mes y el inicio del mes siguiente, como texto ISO.
  /// Ejemplo para noviembre 2026: "2026-11-01T00:00..." y "2026-12-01T00:00...".
  /// Dart ajusta solo el año: el mes 13 de 2026 se convierte en enero de 2027.
  (String, String) _rangoDelMes(DateTime mes) {
    final inicio = DateTime(mes.year, mes.month, 1);
    final fin = DateTime(mes.year, mes.month + 1, 1);
    return (inicio.toIso8601String(), fin.toIso8601String());
  }

  /// Escribe el error y su traza en la consola de depuración (S18: StackTrace).
  void _registrarError(String operacion, Object error, StackTrace stackTrace) {
    debugPrint('[MovimientoRepository] Error en $operacion: $error');
    debugPrint(stackTrace.toString());
  }
}