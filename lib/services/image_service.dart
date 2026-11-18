import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Error "amigable" al trabajar con fotos, para mostrarlo al usuario.
class ImagenException implements Exception {
  final String mensaje;

  ImagenException(this.mensaje);

  @override
  String toString() => mensaje;
}

/// Todo lo relacionado con las fotos de los tickets:
/// tomarlas, elegirlas de la galería, guardarlas y borrarlas.
class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Abre la cámara. Devuelve la ruta permanente de la foto,
  /// o null si el usuario canceló.
  Future<String?> tomarFoto() => _seleccionar(ImageSource.camera);

  /// Abre la galería. Devuelve la ruta permanente de la foto,
  /// o null si el usuario canceló.
  Future<String?> elegirDeGaleria() => _seleccionar(ImageSource.gallery);

  Future<String?> _seleccionar(ImageSource origen) async {
    try {
      final XFile? archivo = await _picker.pickImage(
        source: origen,
        // Reducimos el tamaño: un ticket no necesita 12 megapíxeles,
        // y así la app ocupa menos espacio y carga más rápido.
        maxWidth: 1600,
        imageQuality: 80,
      );

      // El usuario cerró la cámara o la galería sin elegir nada.
      if (archivo == null) return null;

      return await _guardarEnCarpetaPermanente(archivo);
    } on PlatformException catch (e, stackTrace) {
      // Errores que vienen del sistema operativo (permisos, cámara ocupada…).
      _registrarError(e, stackTrace);
      if (e.code == 'camera_access_denied') {
        throw ImagenException(
            'Gastito no tiene permiso para usar la cámara. Actívalo en Ajustes.');
      }
      if (e.code == 'photo_access_denied') {
        throw ImagenException(
            'Gastito no tiene permiso para ver tus fotos. Actívalo en Ajustes.');
      }
      throw ImagenException('No se pudo abrir la cámara o la galería.');
    } on FileSystemException catch (e, stackTrace) {
      // Error al copiar el archivo (por ejemplo, sin espacio en el teléfono).
      _registrarError(e, stackTrace);
      throw ImagenException('No se pudo guardar la foto en el teléfono.');
    } catch (e, stackTrace) {
      _registrarError(e, stackTrace);
      throw ImagenException('Ocurrió un error inesperado con la foto.');
    }
  }

  /// Copia la foto de la carpeta temporal a "documentos/tickets/" (S24).
  Future<String> _guardarEnCarpetaPermanente(XFile archivo) async {
    // Carpeta privada de la app que Android NO borra por su cuenta.
    final carpetaApp = await getApplicationDocumentsDirectory();
    final carpetaTickets = Directory(p.join(carpetaApp.path, 'tickets'));

    if (!await carpetaTickets.exists()) {
      await carpetaTickets.create(recursive: true);
    }

    // Nombre único usando la hora exacta, ej. "ticket_1763438400000.jpg".
    final extension = p.extension(archivo.path);
    final nombre = 'ticket_${DateTime.now().millisecondsSinceEpoch}$extension';
    final rutaFinal = p.join(carpetaTickets.path, nombre);

    await archivo.saveTo(rutaFinal);

    // Borramos la copia temporal para no dejar archivos "huérfanos" (S24).
    // Si no se puede borrar no pasa nada: Android limpiará la caché después.
    try {
      await File(archivo.path).delete();
    } catch (_) {}

    return rutaFinal;
  }

  /// Borra una foto guardada. Se usa al quitar la foto del formulario,
  /// al salir sin guardar y al eliminar un movimiento.
  Future<void> eliminarImagen(String? ruta) async {
    if (ruta == null) return;
    try {
      final archivo = File(ruta);
      if (await archivo.exists()) {
        await archivo.delete();
      }
    } catch (e, stackTrace) {
      // No es grave si falla: solo lo registramos.
      _registrarError(e, stackTrace);
    }
  }

  void _registrarError(Object error, StackTrace stackTrace) {
    debugPrint('[ImageService] Error: $error');
    debugPrint(stackTrace.toString());
  }
}