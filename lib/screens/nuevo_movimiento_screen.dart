import 'package:flutter/material.dart';

import '../data/movimiento_repository.dart';
import '../models/categorias.dart';
import '../models/movimiento.dart';

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

  // Controladores y FocusNode: se crean en initState y se liberan en dispose
  // para evitar fugas de memoria (la "Regla de Oro" de S10).
  late final TextEditingController _montoController;
  late final TextEditingController _descripcionController;
  late final FocusNode _descripcionFocus;

  String _tipo = Movimiento.tipoEgreso; // Por defecto, la mayoría son gastos.
  late String _categoria;
  bool _guardando = false; // Evita guardar dos veces si tocan rápido el botón.

  // PASO 8: aquí irá la ruta de la foto del ticket.
  // PASO 10: aquí irá si el usuario quiere guardar la ubicación.

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

  Future<void> _guardar() async {
    // 1. Validar todos los campos. Si alguno falla, se marca en rojo y no seguimos.
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus(); // Oculta el teclado.
    setState(() => _guardando = true);

    // 2. Armar el objeto con los datos del formulario.
    final movimiento = Movimiento(
      tipo: _tipo,
      monto: _leerMonto(_montoController.text)!,
      categoria: _categoria,
      descripcion: _descripcionController.text.trim(),
      fecha: DateTime.now(), // La fecha es siempre la del registro.
      // PASO 8: rutaImagen
      // PASO 10: latitud y longitud
    );

    // 3. Guardar con manejo de errores.
    try {
      await _repositorio.insertar(movimiento);
      if (!mounted) return;
      // Regresamos a la lista avisando que sí se guardó (true).
      Navigator.pop(context, true);
    } on DatosException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje)),
      );
    }
  }

  // ---------------- Interfaz ----------------

  @override
  Widget build(BuildContext context) {
    final categorias = Categorias.porTipo(_tipo);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo movimiento')),
      body: Form(
        key: _formKey,
        // ListView permite hacer scroll cuando el teclado tapa los campos (S14).
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
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

            // PASO 8: aquí irá el recuadro "Agregar ticket" (cámara / galería).
            // PASO 9: aquí irá el botón del micrófono.

            const SizedBox(height: 16),

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
              // La key cambia con el tipo: así Flutter reconstruye el campo
              // con la nueva lista de categorías y su nuevo valor inicial.
              key: ValueKey(_tipo),
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

            // PASO 10: aquí irá la casilla "Guardar ubicación del gasto".

            const SizedBox(height: 24),

            // --- Guardar ---
            ElevatedButton(
              // null desactiva el botón mientras se guarda.
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
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