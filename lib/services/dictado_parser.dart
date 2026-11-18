import '../models/categorias.dart';
import '../models/movimiento.dart';

/// Lo que el parser logró entender de una frase dictada.
class ResultadoDictado {
  final String tipo;
  final double? monto; // null si no se dijo ningún número.
  final String categoria;
  final String descripcion;

  const ResultadoDictado({
    required this.tipo,
    required this.monto,
    required this.categoria,
    required this.descripcion,
  });
}

/// "Traduce" una frase dictada a los campos del formulario.
///
/// Ejemplo: "Me gasté 35 pesos en el Uber"
///   → tipo: egreso, monto: 35, categoría: Transporte.
///
/// No usa inteligencia artificial: busca palabras clave y números.
/// Es sencillo y predecible, y el usuario siempre puede corregir el resultado.
class DictadoParser {
  /// Frases o palabras que indican que entró dinero.
  static const List<String> _palabrasIngreso = [
    'me pagaron', 'me depositaron', 'me dieron', 'recibi', 'gane', 'cobre',
    'ingreso', 'beca', 'sueldo', 'quincena', 'mesada', 'vendi',
  ];

  static ResultadoDictado analizar(String frase) {
    final normalizada = _normalizar(frase);
    final palabras = _separarPalabras(normalizada);
    final tipo = _detectarTipo(normalizada, palabras);

    return ResultadoDictado(
      tipo: tipo,
      monto: _extraerMonto(normalizada),
      categoria: _detectarCategoria(normalizada, palabras, tipo),
      descripcion: _primeraMayuscula(frase.trim()),
    );
  }

  // ---------------- Pasos del análisis ----------------

  /// Pasa a minúsculas y quita acentos: "Gasté" → "gaste".
  static String _normalizar(String texto) {
    var resultado = texto.toLowerCase();
    const sinAcento = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u'};
    sinAcento.forEach((conAcento, letra) {
      resultado = resultado.replaceAll(conAcento, letra);
    });
    return resultado;
  }

  /// "me gaste $35 en el uber" → ["me", "gaste", "35", "en", "el", "uber"]
  static List<String> _separarPalabras(String texto) {
    // El patrón [^a-z0-9ñ]+ significa "uno o más caracteres que NO sean
    // letras ni números". Cortamos el texto en esos puntos.
    return texto
        .split(RegExp(r'[^a-z0-9ñ]+'))
        .where((palabra) => palabra.isNotEmpty)
        .toList();
  }

  /// ¿La frase contiene esta palabra clave?
  /// - Frases de varias palabras ("me pagaron"): se buscan tal cual.
  /// - Palabras sueltas: deben coincidir con una palabra completa, o ser el
  ///   inicio de una palabra si la clave es larga ("camion" → "camiones").
  ///   Así evitamos que "gas" (Servicios) coincida con "gaste".
  static bool _contiene(String texto, List<String> palabras, String clave) {
    if (clave.contains(' ')) {
      return texto.contains(clave);
    }
    for (final palabra in palabras) {
      if (palabra == clave) return true;
      if (clave.length >= 4 && palabra.startsWith(clave)) return true;
    }
    return false;
  }

  static String _detectarTipo(String texto, List<String> palabras) {
    for (final clave in _palabrasIngreso) {
      if (_contiene(texto, palabras, clave)) {
        return Movimiento.tipoIngreso;
      }
    }
    return Movimiento.tipoEgreso; // Si no hay pistas, lo más común es un gasto.
  }

  /// Busca el primer número de la frase. Entiende "35", "35.50", "1,250" y "2 mil".
  static double? _extraerMonto(String texto) {
    // Patrón: un dígito, seguido de más dígitos o comas,
    // y opcionalmente un punto con decimales.
    final coincidencia = RegExp(r'\d[\d,]*(\.\d+)?').firstMatch(texto);
    if (coincidencia == null) return null;

    var monto = double.tryParse(coincidencia.group(0)!.replaceAll(',', ''));
    if (monto == null) return null;

    // "me pagaron 2 mil" → 2000
    final resto = texto.substring(coincidencia.end).trim();
    if (resto.startsWith('mil')) {
      monto *= 1000;
    }
    return monto;
  }

  static String _detectarCategoria(
      String texto, List<String> palabras, String tipo) {
    for (final categoria in Categorias.porTipo(tipo)) {
      for (final clave in categoria.palabrasClave) {
        if (_contiene(texto, palabras, clave)) {
          return categoria.nombre;
        }
      }
    }
    return 'Otros';
  }

  static String _primeraMayuscula(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }
}