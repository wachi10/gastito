import 'package:flutter/material.dart';

import '../data/movimiento_repository.dart';
import '../models/categorias.dart';
import '../models/movimiento.dart';
import '../tema.dart';
import '../utils/formato.dart';
import '../widgets/selector_mes.dart';

/// Totales del mes agrupados por categoría, separados en egresos e ingresos.
class _DatosResumen {
  final Map<String, double> egresos;
  final Map<String, double> ingresos;

  const _DatosResumen({required this.egresos, required this.ingresos});

  bool get estaVacio => egresos.isEmpty && ingresos.isEmpty;
}

/// Pantalla de Resumen: ¿en qué se fue (y de dónde vino) el dinero del mes?
class ResumenScreen extends StatefulWidget {
  const ResumenScreen({super.key});

  @override
  State<ResumenScreen> createState() => _ResumenScreenState();
}

class _ResumenScreenState extends State<ResumenScreen> {
  final MovimientoRepository _repositorio = MovimientoRepository();

  late DateTime _mesSeleccionado;

  /// Igual que en la lista: el Future se guarda en el estado, no en build (S18).
  late Future<_DatosResumen> _futureResumen;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _mesSeleccionado = DateTime(hoy.year, hoy.month, 1);
    _cargar();
  }

  void _cargar() {
    _futureResumen = _obtenerDatos();
  }

  /// Pide al repositorio los totales de egresos y de ingresos del mes.
  /// Si alguna consulta falla, el DatosException llega al FutureBuilder.
  Future<_DatosResumen> _obtenerDatos() async {
    final egresos = await _repositorio.totalesPorCategoria(
      _mesSeleccionado,
      Movimiento.tipoEgreso,
    );
    final ingresos = await _repositorio.totalesPorCategoria(
      _mesSeleccionado,
      Movimiento.tipoIngreso,
    );
    return _DatosResumen(egresos: egresos, ingresos: ingresos);
  }

  void _cambiarMes(int meses) {
    setState(() {
      _mesSeleccionado = DateTime(
        _mesSeleccionado.year,
        _mesSeleccionado.month + meses,
        1,
      );
      _cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen por categoría')),
      body: Column(
        children: [
          SelectorMes(mes: _mesSeleccionado, onCambiar: _cambiarMes),
          Expanded(
            child: FutureBuilder<_DatosResumen>(
              future: _futureResumen,
              builder: (context, snapshot) {
                // 1. Cargando
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. Error, con opción de reintentar
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 56, color: TemaApp.rojoSuave),
                          const SizedBox(height: 12),
                          Text(snapshot.error.toString(),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => setState(_cargar),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final datos = snapshot.data!;

                // 3a. Mes sin movimientos
                if (datos.estaVacio) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pie_chart_outline,
                            size: 64, color: TemaApp.textoSecundario),
                        SizedBox(height: 12),
                        Text('No hay movimientos en este mes',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  );
                }

                // 3b. Resumen
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _SeccionCategorias(
                      titulo: 'Egresos',
                      totales: datos.egresos,
                      tipo: Movimiento.tipoEgreso,
                      colorBarra: TemaApp.textoPrincipal,
                    ),
                    const SizedBox(height: 28),
                    _SeccionCategorias(
                      titulo: 'Ingresos',
                      totales: datos.ingresos,
                      tipo: Movimiento.tipoIngreso,
                      colorBarra: TemaApp.verde,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Una sección (Egresos o Ingresos) con una fila por categoría.
class _SeccionCategorias extends StatelessWidget {
  final String titulo;
  final Map<String, double> totales; // Ya viene ordenado de mayor a menor (SQL).
  final String tipo;
  final Color colorBarra;

  const _SeccionCategorias({
    required this.titulo,
    required this.totales,
    required this.tipo,
    required this.colorBarra,
  });

  @override
  Widget build(BuildContext context) {
    // Suma de toda la sección, para calcular el porcentaje de cada categoría.
    double totalSeccion = 0;
    for (final monto in totales.values) {
      totalSeccion += monto;
    }

    // Armamos las filas con una línea divisoria entre cada una.
    final filas = <Widget>[];
    for (final entrada in totales.entries) {
      if (filas.isNotEmpty) filas.add(const Divider(height: 1));
      filas.add(_fila(entrada.key, entrada.value, totalSeccion));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado: "Egresos            $1,245.50"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: TemaApp.textoPrincipal,
                ),
              ),
              const Spacer(),
              Text(
                Formato.dinero(totalSeccion),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorBarra,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (totales.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Sin ${titulo.toLowerCase()} este mes',
              style: const TextStyle(color: TemaApp.textoSecundario),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TemaApp.borde),
            ),
            child: Column(children: filas),
          ),
      ],
    );
  }

  /// Ícono, nombre, monto y una barra con el porcentaje del total.
  Widget _fila(String categoria, double monto, double totalSeccion) {
    final proporcion = totalSeccion == 0 ? 0.0 : monto / totalSeccion;
    final porcentaje = (proporcion * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: TemaApp.borde.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Categorias.iconoDe(tipo, categoria),
                  size: 18,
                  color: TemaApp.textoPrincipal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  categoria,
                  style: const TextStyle(
                    fontSize: 15,
                    color: TemaApp.textoPrincipal,
                  ),
                ),
              ),
              Text(
                Formato.dinero(monto),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: TemaApp.textoPrincipal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  // Barra de proporción: value va de 0.0 (vacía) a 1.0 (llena).
                  child: LinearProgressIndicator(
                    value: proporcion,
                    minHeight: 6,
                    backgroundColor: TemaApp.borde,
                    color: colorBarra,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 40,
                child: Text(
                  '$porcentaje%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    color: TemaApp.textoSecundario,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}