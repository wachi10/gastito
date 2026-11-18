import 'movimiento.dart';

/// Totales de un mes: ingresos, egresos y balance.
///
/// Se calcula a partir de la lista de movimientos que la pantalla ya cargó,
/// así no hace falta otra consulta a la base de datos.
class ResumenMes {
  final double ingresos;
  final double egresos;

  const ResumenMes({required this.ingresos, required this.egresos});

  /// Lo que queda: positivo si ganaste más de lo que gastaste.
  double get balance => ingresos - egresos;

  /// Recorre los movimientos y suma cada uno donde corresponde.
  factory ResumenMes.desde(List<Movimiento> movimientos) {
    double ingresos = 0;
    double egresos = 0;

    for (final movimiento in movimientos) {
      if (movimiento.esIngreso) {
        ingresos += movimiento.monto;
      } else {
        egresos += movimiento.monto;
      }
    }

    return ResumenMes(ingresos: ingresos, egresos: egresos);
  }
}