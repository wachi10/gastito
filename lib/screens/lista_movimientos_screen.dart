import 'package:flutter/material.dart';

import '../data/movimiento_repository.dart';
import '../models/movimiento.dart';
import '../models/resumen_mes.dart';
import '../rutas.dart';
import '../tema.dart';
import '../utils/formato.dart';
import '../widgets/app_drawer.dart';
import '../widgets/balance_mes.dart';
import '../widgets/movimiento_card.dart';

/// Pantalla principal: movimientos del mes seleccionado.
///
/// Es StatefulWidget porque cambia con el tiempo: el mes elegido
/// y los datos que se cargan de la base de datos.
class ListaMovimientosScreen extends StatefulWidget {
  const ListaMovimientosScreen({super.key});

  @override
  State<ListaMovimientosScreen> createState() => _ListaMovimientosScreenState();
}

class _ListaMovimientosScreenState extends State<ListaMovimientosScreen> {
  final MovimientoRepository _repositorio = MovimientoRepository();

  /// Primer día del mes que se está viendo (ej. 1 de noviembre de 2026).
  late DateTime _mesSeleccionado;

  /// La consulta a la base de datos. Se guarda en una variable de estado y
  /// NO se crea dentro de build (S18): build se ejecuta muchas veces y
  /// repetiría la consulta en cada redibujo.
  late Future<List<Movimiento>> _futureMovimientos;

  @override
  void initState() {
    super.initState();
    _mesSeleccionado = _inicioDeMes(DateTime.now());
    _cargarMovimientos();
  }

  // ---------------- Lógica ----------------

  DateTime _inicioDeMes(DateTime fecha) => DateTime(fecha.year, fecha.month, 1);

  bool get _esMesActual {
    final hoy = DateTime.now();
    return _mesSeleccionado.year == hoy.year &&
        _mesSeleccionado.month == hoy.month;
  }

  /// Pide al repositorio los movimientos del mes seleccionado.
  void _cargarMovimientos() {
    _futureMovimientos = _repositorio.obtenerPorMes(_mesSeleccionado);
  }

  /// Avanza (+1) o retrocede (-1) un mes y recarga los datos.
  void _cambiarMes(int meses) {
    setState(() {
      _mesSeleccionado = DateTime(
        _mesSeleccionado.year,
        _mesSeleccionado.month + meses,
        1,
      );
      _cargarMovimientos();
    });
  }

  /// Abre el formulario. Si regresa "true", se guardó algo: volvemos
  /// al mes actual (ahí quedó el movimiento nuevo) y recargamos.
  Future<void> _irANuevoMovimiento() async {
    final guardado = await Navigator.pushNamed(context, Rutas.nuevo);

    // Después de un await, la pantalla pudo haberse cerrado (S13).
    if (!mounted) return;

    if (guardado == true) {
      setState(() {
        _mesSeleccionado = _inicioDeMes(DateTime.now());
        _cargarMovimientos();
      });
    }
  }

  /// Abre el detalle enviando el movimiento como argumento (S17).
  /// Si regresa "true", el movimiento se eliminó y recargamos.
  Future<void> _irADetalle(Movimiento movimiento) async {
    final eliminado = await Navigator.pushNamed(
      context,
      Rutas.detalle,
      arguments: movimiento,
    );

    if (!mounted) return;

    if (eliminado == true) {
      setState(() {
        _cargarMovimientos();
      });
    }
  }

  // ----- TEMPORAL: datos de prueba (se borra cuando el formulario funcione) -----
  Future<void> _insertarDatosDePrueba() async {
    final hoy = DateTime.now();
    final mesPasado = DateTime(hoy.year, hoy.month - 1, 15);

    await _repositorio.insertar(Movimiento(
      tipo: Movimiento.tipoIngreso,
      monto: 4000,
      categoria: 'Beca',
      descripcion: 'Beca del mes',
      fecha: hoy,
    ));
    await _repositorio.insertar(Movimiento(
      tipo: Movimiento.tipoEgreso,
      monto: 35,
      categoria: 'Transporte',
      descripcion: 'Uber a la escuela',
      fecha: hoy,
    ));
    await _repositorio.insertar(Movimiento(
      tipo: Movimiento.tipoEgreso,
      monto: 1250.5,
      categoria: 'Comida',
      descripcion: 'Despensa del mes pasado',
      fecha: mesPasado,
    ));

    if (!mounted) return;
    setState(() {
      _cargarMovimientos();
    });
  }
  // ----- FIN TEMPORAL -----

  // ---------------- Interfaz ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastito'),
        actions: [
          // TEMPORAL: botón para insertar datos de prueba.
          IconButton(
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Datos de prueba',
            onPressed: _insertarDatosDePrueba,
          ),
        ],
      ),
      drawer: const AppDrawer(rutaActual: Rutas.inicio),
      body: Column(
        children: [
          _construirSelectorMes(),
          // Expanded: la lista ocupa todo el espacio que sobra.
          Expanded(child: _construirContenido()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _irANuevoMovimiento,
        tooltip: 'Agregar movimiento',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// ‹ Noviembre 2026 ›
  Widget _construirSelectorMes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Mes anterior',
            onPressed: () => _cambiarMes(-1),
          ),
          SizedBox(
            width: 170,
            child: Text(
              Formato.mesAnio(_mesSeleccionado),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: TemaApp.textoPrincipal,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Mes siguiente',
            // No hay movimientos en el futuro: si ya estamos en el mes
            // actual, onPressed es null y Flutter desactiva el botón.
            onPressed: _esMesActual ? null : () => _cambiarMes(1),
          ),
        ],
      ),
    );
  }

  /// Muestra carga, error, vacío o la lista, según el estado del Future (S18).
  Widget _construirContenido() {
    return FutureBuilder<List<Movimiento>>(
      future: _futureMovimientos,
      builder: (context, snapshot) {
        // 1. Cargando: la consulta todavía no termina.
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Error: el repositorio lanzó un DatosException.
        if (snapshot.hasError) {
          return _VistaError(
            mensaje: snapshot.error.toString(),
            onReintentar: () {
              setState(() {
                _cargarMovimientos();
              });
            },
          );
        }

        // 3. Datos listos.
        final movimientos = snapshot.data ?? [];
        final resumen = ResumenMes.desde(movimientos);

        // 3a. Sin movimientos en este mes.
        if (movimientos.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              BalanceMes(resumen: resumen),
              const SizedBox(height: 56),
              const _VistaVacia(),
            ],
          );
        }

        // 3b. Lista: el elemento 0 es el balance y los demás son tarjetas.
        return ListView.builder(
          // 96 abajo para que el botón + no tape la última tarjeta.
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: movimientos.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: BalanceMes(resumen: resumen),
              );
            }

            final movimiento = movimientos[index - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MovimientoCard(
                movimiento: movimiento,
                onTap: () => _irADetalle(movimiento),
              ),
            );
          },
        );
      },
    );
  }
}

/// Mensaje cuando el mes no tiene movimientos.
class _VistaVacia extends StatelessWidget {
  const _VistaVacia();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 64,
          color: TemaApp.textoSecundario,
        ),
        SizedBox(height: 12),
        Text(
          'Aún no hay movimientos este mes',
          style: TextStyle(fontSize: 16, color: TemaApp.textoPrincipal),
        ),
        SizedBox(height: 4),
        Text(
          'Toca + para agregar el primero',
          style: TextStyle(color: TemaApp.textoSecundario),
        ),
      ],
    );
  }
}

/// Mensaje cuando la base de datos falla, con botón para reintentar.
class _VistaError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _VistaError({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: TemaApp.rojoSuave),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}