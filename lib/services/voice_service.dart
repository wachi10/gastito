import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Error "amigable" del dictado, para mostrarlo al usuario.
class VozException implements Exception {
  final String mensaje;

  VozException(this.mensaje);

  @override
  String toString() => mensaje;
}

/// Captura audio del micrófono y lo convierte en texto.
///
/// El paquete speech_to_text abre el micrófono (captura de audio) y usa
/// el reconocedor de voz del teléfono para transcribirlo.
class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _inicializado = false;

  // Funciones que la pantalla nos pasa para avisarle qué ocurre.
  // Son "nullable" (?) porque antes de la primera escucha no existen.
  VoidCallback? _onTerminado;
  void Function(String mensaje)? _onError;

  bool get escuchando => _speech.isListening;

  /// Empieza a escuchar.
  /// - [onResultado]: se llama varias veces mientras el usuario habla
  ///   (texto parcial) y una última vez con [esFinal] = true.
  /// - [onTerminado]: el micrófono se apagó.
  /// - [onError]: algo falló durante la escucha (no se entendió, sin internet…).
  ///
  /// Lanza [VozException] si no hay permiso o el teléfono no tiene reconocimiento de voz.
  Future<void> escuchar({
    required void Function(String texto, bool esFinal) onResultado,
    required VoidCallback onTerminado,
    required void Function(String mensaje) onError,
  }) async {
    _onTerminado = onTerminado;
    _onError = onError;

    // 1. La primera vez: preparar el reconocedor. Aquí Android pide el permiso.
    if (!_inicializado) {
      try {
        _inicializado = await _speech.initialize(
          onStatus: _alCambiarEstado,
          onError: (error) {
            debugPrint('[VoiceService] Error de reconocimiento: ${error.errorMsg}');
            _onError?.call(_traducirError(error.errorMsg));
          },
        );
      } on PlatformException catch (e, stackTrace) {
        _registrarError(e, stackTrace);
        throw VozException(
            'El dictado no está disponible en este teléfono.');
      }

      // initialize devuelve false si se negó el permiso o no hay reconocedor.
      if (!_inicializado) {
        final tienePermiso = await _speech.hasPermission;
        throw VozException(tienePermiso
            ? 'El dictado no está disponible en este teléfono.'
            : 'Gastito necesita permiso del micrófono para dictar. '
            'Actívalo en Ajustes.');
      }
    }

    // Si quedó una escucha anterior "colgada", la cancelamos antes de empezar.
    if (_speech.isListening) {
      await _speech.cancel();
    }

    // 2. Empezar a escuchar.
    try {
      await _speech.listen(
        onResult: (resultado) {
          onResultado(resultado.recognizedWords, resultado.finalResult);
        },
        localeId: 'es_MX', // Español de México.
        listenFor: const Duration(seconds: 15), // Máximo 15 segundos.
        pauseFor: const Duration(seconds: 3), // Si callas 3 s, termina solo.
        listenOptions: SpeechListenOptions(
          partialResults: true, // Mostrar el texto mientras hablas.
          cancelOnError: true,
        ),
      );
    } catch (e, stackTrace) {
      _registrarError(e, stackTrace);
      throw VozException('No se pudo iniciar el micrófono.');
    }
  }

  /// Detiene la escucha y procesa lo que se dijo hasta ese momento.
  Future<void> detener() async {
    await _speech.stop();
  }

  /// Cancela la escucha sin procesar nada (al salir de la pantalla).
  Future<void> cancelar() async {
    await _speech.cancel();
  }

  void _alCambiarEstado(String estado) {
    debugPrint('[VoiceService] Estado: $estado');
    if (estado == SpeechToText.doneStatus ||
        estado == SpeechToText.notListeningStatus) {
      _onTerminado?.call();
    }
  }

  /// Convierte los códigos técnicos del reconocedor en mensajes entendibles.
  String _traducirError(String codigo) {
    switch (codigo) {
      case 'error_no_match':
        return 'No te entendí. Toca el micrófono e intenta de nuevo.';
      case 'error_speech_timeout':
        return 'No escuché nada. Toca el micrófono y habla.';
      case 'error_network':
      case 'error_network_timeout':
        return 'El dictado necesita internet. Revisa tu conexión.';
      case 'error_permission':
      case 'error_insufficient_permissions':
        return 'Gastito necesita permiso del micrófono. Actívalo en Ajustes.';
      case 'error_busy':
        return 'El micrófono está ocupado. Intenta en un momento.';
      default:
        return 'Ocurrió un error con el dictado.';
    }
  }

  void _registrarError(Object error, StackTrace stackTrace) {
    debugPrint('[VoiceService] Error: $error');
    debugPrint(stackTrace.toString());
  }
}