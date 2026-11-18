/// Nombres de las rutas de la app (Named Routes, S17).
///
/// Se guardan en constantes para no escribir '/detalle' a mano en cada
/// pantalla: si hay un error de dedo, Dart lo marca antes de correr la app.
class Rutas {
  static const String inicio = '/';
  static const String nuevo = '/nuevo';
  static const String detalle = '/detalle';
  static const String resumen = '/resumen';
}