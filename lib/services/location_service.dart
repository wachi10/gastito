import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Coordenadas simples (latitud y longitud).
///
/// Las pantallas usan esta clase y no la "Position" de geolocator.
/// Así, si un día cambiamos de paquete de GPS, las pantallas no se enteran.
class Coordenadas {
  final double latitud;
  final double longitud;

  const Coordenadas({required this.latitud, required this.longitud});
}

/// Error "amigable" de ubicación.
/// Indica también si el problema se puede resolver en Ajustes.
class UbicacionException implements Exception {
  final String mensaje;
  final bool gpsApagado; // Se resuelve encendiendo la ubicación del teléfono.
  final bool permisoBloqueado; // Se resuelve en los ajustes de la app.

  UbicacionException(
      this.mensaje, {
        this.gpsApagado = false,
        this.permisoBloqueado = false,
      });

  @override
  String toString() => mensaje;
}

/// Acceso al GPS con manejo defensivo de permisos (S21).
class LocationService {
  /// Revisa que el GPS esté encendido y que tengamos permiso.
  /// Si falta el permiso, lo pide. Lanza [UbicacionException] si algo falla.
  Future<void> verificarPermiso() async {
    // 1. ¿Está encendido el GPS del teléfono?
    final gpsEncendido = await Geolocator.isLocationServiceEnabled();
    if (!gpsEncendido) {
      throw UbicacionException('El GPS está apagado.', gpsApagado: true);
    }

    // 2. ¿Qué permiso tenemos actualmente?
    var permiso = await Geolocator.checkPermission();

    // 3. Si no lo tenemos, lo pedimos (aparece la ventana del sistema).
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        throw UbicacionException('No diste permiso de ubicación.');
      }
    }

    // Si el usuario lo negó varias veces, Android ya no deja volver a preguntar:
    // la única forma es que lo active manualmente en Ajustes.
    if (permiso == LocationPermission.deniedForever) {
      throw UbicacionException(
        'El permiso de ubicación está bloqueado. Actívalo en Ajustes.',
        permisoBloqueado: true,
      );
    }
  }

  /// Obtiene la ubicación actual.
  /// Si tarda más de 10 segundos, usa la última ubicación conocida.
  Future<Coordenadas> obtenerUbicacion() async {
    // 4. Primero los permisos; si fallan, la excepción sube tal cual.
    await verificarPermiso();

    try {
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10), // No esperar para siempre.
        ),
      );
      return Coordenadas(
        latitud: posicion.latitude,
        longitud: posicion.longitude,
      );
    } on TimeoutException catch (e, stackTrace) {
      // En interiores el GPS puede tardar mucho. Plan B: la última conocida.
      _registrarError(e, stackTrace);
      final ultima = await _ultimaUbicacionConocida();
      if (ultima != null) return ultima;
      throw UbicacionException('No se pudo obtener la ubicación a tiempo.');
    } on LocationServiceDisabledException catch (e, stackTrace) {
      // El usuario apagó el GPS justo mientras buscábamos.
      _registrarError(e, stackTrace);
      throw UbicacionException('El GPS está apagado.', gpsApagado: true);
    } on PermissionDeniedException catch (e, stackTrace) {
      _registrarError(e, stackTrace);
      throw UbicacionException('No diste permiso de ubicación.');
    } catch (e, stackTrace) {
      _registrarError(e, stackTrace);
      throw UbicacionException('No se pudo obtener la ubicación.');
    }
  }

  /// Abre los ajustes de Gastito (para desbloquear el permiso).
  Future<void> abrirAjustesApp() async {
    await Geolocator.openAppSettings();
  }

  /// Abre los ajustes de ubicación del teléfono (para encender el GPS).
  Future<void> abrirAjustesUbicacion() async {
    await Geolocator.openLocationSettings();
  }

  Future<Coordenadas?> _ultimaUbicacionConocida() async {
    try {
      final posicion = await Geolocator.getLastKnownPosition();
      if (posicion == null) return null;
      return Coordenadas(
        latitud: posicion.latitude,
        longitud: posicion.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  void _registrarError(Object error, StackTrace stackTrace) {
    debugPrint('[LocationService] Error: $error');
    debugPrint(stackTrace.toString());
  }
}