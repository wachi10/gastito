import 'package:flutter/material.dart';

import '../data/movimiento_repository.dart';
import '../models/categorias.dart';
import '../models/movimiento.dart';
import '../services/dictado_parser.dart';
import '../services/image_service.dart';
import '../services/location_service.dart'; // NUEVO (paso 10)
import '../services/voice_service.dart';
import '../tema.dart'; // NUEVO (paso 10)
import '../widgets/boton_dictado.dart';
import '../widgets/selector_ticket.dart';

/// Formulario para registrar un ingreso o un egreso.
class NuevoMovimientoScreen extends StatefulWidget {
  const NuevoMovimientoScreen({super.key});

  @override
  State<NuevoMovimientoScreen> createState() => _NuevoMovimientoScreenState();
}

class _NuevoMovimientoScreenState extends State<NuevoMovimientoScreen> {
  /// Llave para validar todos los campos del Form a la vez (S10).
  final _formKey = GlobalKey<FormState>();

  final MovimientoRepository _repositorio = MovimientoRepository();
  final ImageService _imageService = ImageService();
  final VoiceService _voiceService = VoiceService();
  final LocationService _locationService = LocationService(); // NUEVO (paso 10)

  // Controladores y FocusNode: se crean en initState y se liberan en dispose
  // para evitar fugas de memoria (la "Regla de Oro" de S10).
  late final TextEditingController _montoController;
  late final TextEditingController _descripcionController;
  late final FocusNode _descripcionFocus;

  String _tipo = Movimiento.tipoEgreso; // Por defecto, la mayoría son gastos.
  late String _categoria;
  bool _guardando = false; // Evita guardar dos veces si tocan rápido el botón.

  // Foto del ticket (paso 8)
  String? _rutaImagen; // Ruta permanente de la foto, o null si no hay.
  bool _procesandoImagen = false; // Muestra el indicador mientras se copia.
  bool _guardado = false; // Para saber si al salir hay que borrar la foto.

  // Dictado (paso 9)
  bool _escuchando = false;
  String _textoDictado = '';

  // NUEVO (paso 10): ubicación
  bool _guardarUbicacion = false; // Estado de la casilla.
  bool _obteniendoUbicacion = false; // Para el texto del botón Guardar.

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController();
    _descripcionController = TextEditingController();
    _descripcionFocus = FocusNode();
    _categoria = Categorias.egresos.first.nombre; // "Comida"
  }

  @override
  void dispose() {
    // Si el usuario tomó una foto pero salió sin guardar,
    // la borramos para no dejar archivos huérfanos ocupando espacio (S24).
    if (!_guardado && _rutaImagen != null) {
      _imageService.eliminarImagen(_rutaImagen);
    }

    _voiceService.cancelar(); // Apagar el micrófono al salir.

    _montoController.dispose();
    _descripcionController.dispose();
    _descripcionFocus.dispose();
    super.dispose();
  }

  // ---------------- Lógica ----------------

  /// Al cambiar entre Ingreso y Egreso, la lista de categorías es otra,
  /// así que elegimos la primera de la nueva lista.
  void _cambiarTipo(String? nuevoTipo) {
    if (nuevoTipo == null) return;
    setState(() {
      _tipo = nuevoTipo;
      _categoria = Categorias.porTipo(nuevoTipo).first.nombre;
    });
  }

  /// Convierte el texto del campo en número. Acepta "1,250.50" quitando comas.
  double? _leerMonto(String texto) {
    return double.tryParse(texto.trim().replaceAll(',', ''));
  }

  /// Regla de validación del monto. Devuelve el mensaje de error, o null si está bien.
  String? _validarMonto(String? texto) {
    if (texto == null || texto.trim().isEmpty) {
      return 'Escribe el monto';
    }
    final monto = _leerMonto(texto);
    if (monto == null) {
      return 'Escribe un número válido (ej. 35.50)';
    }
    if (monto <= 0) {
      return 'El monto debe ser mayor a 0';
    }
    return null;
  }

  // ----- Foto del ticket (paso 8) -----

  Future<void> _seleccionarImagen({required bool desdeCamara}) async {
    setState(() => _procesandoImagen = true);

    try {
      final ruta = desdeCamara
          ? await _imageService.tomarFoto()
          : await _imageService.elegirDeGaleria();

      // Si la pantalla se cerró mientras tanto, borramos la foto y salimos.
      if (!mounted) {
        _imageService.eliminarImagen(ruta);
        return;
      }

      // ruta es null si el usuario canceló: simplemente no cambia nada.
      if (ruta != null) {
        setState(() => _rutaImagen = ruta);
      }
    } on ImagenException catch (e) {
      // Permiso negado u otro error: avisamos sin cerrar la app.
      if (mounted) _mostrarMensaje(e.mensaje);
    } finally {
      // "finally" se ejecuta siempre: haya salido bien, mal o cancelado.
      if (mounted) setState(() => _procesandoImagen = false);
    }
  }

  void _quitarImagen() {
    final rutaAnterior = _rutaImagen;
    setState(() => _rutaImagen = null);
    _imageService.eliminarImagen(rutaAnterior);
  }

  // ----- Dictado (paso 9) -----

  Future<void> _alternarDictado() async {
    // Si ya está escuchando, el toque significa "terminé de hablar".
    if (_escuchando) {
      await _voiceService.detener();
      // No esperamos el aviso del teléfono (a veces no llega):
      // apagamos el estado nosotros mismos.
      if (mounted) setState(() => _escuchando = false);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _escuchando = true;
      _textoDictado = '';
    });

    try {
      await _voiceService.escuchar(
        onResultado: (texto, esFinal) {
          if (!mounted) return;
          setState(() {
            _textoDictado = texto;
            // Si es el resultado final, el dictado terminó:
            // apagamos el estado aunque el teléfono no avise.
            if (esFinal) _escuchando = false;
          });
          if (esFinal) _aplicarDictado(texto);
        },
        onTerminado: () {
          if (mounted) setState(() => _escuchando = false);
        },
        onError: (mensaje) {
          if (!mounted) return;
          setState(() => _escuchando = false);
          _mostrarMensaje(mensaje);
        },
      );
    } on VozException catch (e) {
      // Sin permiso o sin reconocedor de voz: avisamos sin cerrar la app.
      if (!mounted) return;
      setState(() => _escuchando = false);
      _mostrarMensaje(e.mensaje);
    }
  }

  /// Llena el formulario con lo que se entendió del dictado.
  void _aplicarDictado(String frase) {
    if (frase.trim().isEmpty) return;

    final resultado = DictadoParser.analizar(frase);

    setState(() {
      _tipo = resultado.tipo;
      _categoria = resultado.categoria;
      _descripcionController.text = resultado.descripcion;

      final monto = resultado.monto;
      if (monto != null) {
        // 35.0 → "35"   |   35.5 → "35.50"
        _montoController.text = monto == monto.roundToDouble()
            ? monto.toStringAsFixed(0)
            : monto.toStringAsFixed(2);
      }
    });

    _mostrarMensaje(resultado.monto == null
        ? 'No escuché el monto. Escríbelo a mano.'
        : 'Listo. Revisa los datos antes de guardar.');
  }

  // ----- NUEVO (paso 10): Ubicación -----

  /// Al marcar la casilla, revisamos GPS y permiso EN ESE MOMENTO,
  /// para que el usuario sepa de inmediato si se podrá guardar el lugar.
  Future<void> _cambiarGuardarUbicacion(bool? marcada) async {
    if (marcada != true) {
      setState(() => _guardarUbicacion = false);
      return;
    }

    setState(() => _guardarUbicacion = true);

    try {
      await _locationService.verificarPermiso();
    } on UbicacionException catch (e) {
      // Si no se puede, desmarcamos la casilla y explicamos por qué.
      if (!mounted) return;
      setState(() => _guardarUbicacion = false);
      _mostrarErrorUbicacion(e);
    }
  }

  /// Muestra el error de ubicación con un botón para ir a Ajustes si aplica.
  void _mostrarErrorUbicacion(UbicacionException e, {String extra = ''}) {
    SnackBarAction? accion;
    if (e.gpsApagado) {
      accion = SnackBarAction(
        label: 'Encender',
        onPressed: _locationService.abrirAjustesUbicacion,
      );
    } else if (e.permisoBloqueado) {
      accion = SnackBarAction(
        label: 'Ajustes',
        onPressed: _locationService.abrirAjustesApp,
      );
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${e.mensaje}$extra'), action: accion),
    );
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  // ----- Guardar -----

  Future<void> _guardar() async {
    // 1. Validar todos los campos. Si alguno falla, se marca en rojo y no seguimos.
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus(); // Oculta el teclado.
    setState(() => _guardando = true);

    // 2. NUEVO (paso 10): obtener la ubicación si el usuario la pidió.
    //    Si falla, seguimos y guardamos sin ubicación.
    double? latitud;
    double? longitud;

    if (_guardarUbicacion) {
      setState(() => _obteniendoUbicacion = true);
      try {
        final coordenadas = await _locationService.obtenerUbicacion();
        latitud = coordenadas.latitud;
        longitud = coordenadas.longitud;
        debugPrint('Ubicación obtenida: $latitud, $longitud');
      } on UbicacionException catch (e) {
        if (mounted) {
          _mostrarErrorUbicacion(e, extra: ' Se guardó sin ubicación.');
        }
      } finally {
        if (mounted) setState(() => _obteniendoUbicacion = false);
      }
      if (!mounted) return;
    }

    // 3. Armar el objeto con los datos del formulario.
    final movimiento = Movimiento(
      tipo: _tipo,
      monto: _leerMonto(_montoController.text)!,
      categoria: _categoria,
      descripcion: _descripcionController.text.trim(),
      fecha: DateTime.now(), // La fecha es siempre la del registro.
      rutaImagen: _rutaImagen,
      latitud: latitud, // NUEVO (paso 10)
      longitud: longitud, // NUEVO (paso 10)
    );

    // 4. Guardar con manejo de errores.
    try {
      await _repositorio.insertar(movimiento);
      _guardado = true; // La foto ya pertenece a un movimiento.
      if (!mounted) return;
      // Regresamos a la lista avisando que sí se guardó (true).
      Navigator.pop(context, true);
    } on DatosException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _mostrarMensaje(e.mensaje);
    }
  }

  // ---------------- Interfaz ----------------

  @override
  Widget build(BuildContext context) {
    final categorias = Categorias.porTipo(_tipo);
    final ocupado = _guardando || _procesandoImagen || _escuchando;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo movimiento')),
      body: Form(
        key: _formKey,
        // ListView permite hacer scroll cuando el teclado tapa los campos (S14).
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // --- Dictado (va primero: es la forma más rápida) ---
            BotonDictado(
              escuchando: _escuchando,
              textoReconocido: _textoDictado,
              onPressed: _alternarDictado,
            ),
            const SizedBox(height: 16),

            // --- Tipo: Ingreso o Egreso (S11: exclusión mutua con RadioGroup) ---
            _etiqueta('Tipo'),
            RadioGroup<String>(
              groupValue: _tipo,
              onChanged: _cambiarTipo,
              child: const Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      value: Movimiento.tipoEgreso,
                      title: Text('Egreso'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      value: Movimiento.tipoIngreso,
                      title: Text('Ingreso'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // --- Monto ---
            _etiqueta('Monto'),
            TextFormField(
              controller: _montoController,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next, // Botón "Siguiente".
              decoration: const InputDecoration(
                prefixText: '\$ ',
                hintText: '0.00',
              ),
              validator: _validarMonto,
              // Al presionar "Siguiente", el cursor salta a Descripción (S10: FocusNode).
              onFieldSubmitted: (_) => _descripcionFocus.requestFocus(),
            ),
            const SizedBox(height: 16),

            // --- Categoría (S11: DropdownButton) ---
            _etiqueta('Categoría'),
            DropdownButtonFormField<String>(
              // La key cambia cuando cambia el tipo o la categoría (por ejemplo,
              // al dictar). Así Flutter reconstruye el campo con el valor correcto.
              key: ValueKey('$_tipo|$_categoria'),
              initialValue: _categoria,
              items: categorias.map((categoria) {
                return DropdownMenuItem<String>(
                  value: categoria.nombre,
                  child: Row(
                    children: [
                      Icon(categoria.icono, size: 20),
                      const SizedBox(width: 12),
                      Text(categoria.nombre),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (valor) {
                if (valor != null) {
                  setState(() => _categoria = valor);
                }
              },
            ),
            const SizedBox(height: 16),

            // --- Descripción (opcional) ---
            _etiqueta('Descripción'),
            TextFormField(
              controller: _descripcionController,
              focusNode: _descripcionFocus,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              maxLength: 100,
              decoration: const InputDecoration(
                hintText: 'Ej. Uber a la escuela',
              ),
            ),
            const SizedBox(height: 8),

            // --- Ticket (paso 8) ---
            _etiqueta('Ticket'),
            SelectorTicket(
              rutaImagen: _rutaImagen,
              cargando: _procesandoImagen,
              onCamara: () => _seleccionarImagen(desdeCamara: true),
              onGaleria: () => _seleccionarImagen(desdeCamara: false),
              onQuitar: _quitarImagen,
            ),
            const SizedBox(height: 16),

            // --- NUEVO (paso 10): Ubicación (S11: Checkbox) ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TemaApp.borde),
              ),
              child: CheckboxListTile(
                value: _guardarUbicacion,
                onChanged: ocupado ? null : _cambiarGuardarUbicacion,
                secondary: const Icon(Icons.location_on_outlined),
                title: const Text('Guardar ubicación'),
                subtitle: const Text('Registra dónde hiciste este movimiento'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- Guardar ---
            ElevatedButton(
              // null desactiva el botón mientras algo está en proceso.
              onPressed: ocupado ? null : _guardar,
              child: _guardando
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(_obteniendoUbicacion
                      ? 'Obteniendo ubicación…'
                      : 'Guardando…'),
                ],
              )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Título pequeño y gris arriba de cada campo.
  Widget _etiqueta(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}