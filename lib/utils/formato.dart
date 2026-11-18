/// Funciones para mostrar dinero y fechas en español.
///
/// Las hacemos a mano para no agregar paquetes extra que no vimos en clase.
class Formato {
  static const List<String> _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  static const List<String> _mesesCortos = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  /// Ejemplo: "Noviembre 2026".
  static String mesAnio(DateTime fecha) {
    // Los meses en DateTime van del 1 al 12, y la lista empieza en 0.
    return '${_meses[fecha.month - 1]} ${fecha.year}';
  }

  /// Ejemplo: "17 nov".
  static String fechaCorta(DateTime fecha) {
    return '${fecha.day} ${_mesesCortos[fecha.month - 1]}';
  }

  /// Ejemplo: "17 de noviembre de 2026 · 21:39".
  static String fechaHora(DateTime fecha) {
    final mes = _meses[fecha.month - 1].toLowerCase();
    // padLeft agrega un 0 a la izquierda: 9 → "09".
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minutos = fecha.minute.toString().padLeft(2, '0');
    return '${fecha.day} de $mes de ${fecha.year} · $hora:$minutos';
  }

  /// Ejemplo: 1245.5 → "$1,245.50"   |   -120 → "−$120.00"
  static String dinero(double cantidad) {
    final esNegativo = cantidad < 0;

    // "1245.50" → ["1245", "50"]
    final partes = cantidad.abs().toStringAsFixed(2).split('.');
    final entero = partes[0];
    final decimales = partes[1];

    // Agrega una coma cada 3 dígitos, contando desde la derecha.
    final conComas = StringBuffer();
    for (int i = 0; i < entero.length; i++) {
      final digitosRestantes = entero.length - i;
      if (i > 0 && digitosRestantes % 3 == 0) {
        conComas.write(',');
      }
      conComas.write(entero[i]);
    }

    final signo = esNegativo ? '−' : '';
    return '$signo\$${conComas.toString()}.$decimales';
  }

  /// Ejemplo: "+$4,000.00" para ingresos y "−$35.00" para egresos.
  static String montoConSigno(double monto, bool esIngreso) {
    final signo = esIngreso ? '+' : '−';
    return '$signo${dinero(monto)}';
  }
}