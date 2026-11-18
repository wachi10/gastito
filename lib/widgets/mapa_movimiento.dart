import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../tema.dart';

/// Mapa interactivo (S22: flutter_map + OpenStreetMap) con un marcador
/// en el lugar donde se registró el movimiento.
class MapaMovimiento extends StatelessWidget {
  final double latitud;
  final double longitud;

  const MapaMovimiento({
    super.key,
    required this.latitud,
    required this.longitud,
  });

  /// OpenStreetMap pide identificar la app que descarga los mapas.
  /// CAMBIA ESTE TEXTO por el applicationId de tu app (build.gradle).
  static const String _paqueteApp = 'com.pablo.gastito';

  @override
  Widget build(BuildContext context) {
    final punto = LatLng(latitud, longitud);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 240,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: punto, // El mapa empieza centrado en el lugar.
                initialZoom: 16, // Nivel de calle.
              ),
              children: [
                // Capa 1: las imágenes del mapa (teselas / tiles, S22).
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: _paqueteApp,
                ),
                // Capa 2: el marcador.
                MarkerLayer(
                  markers: [
                    Marker(
                      point: punto,
                      width: 48,
                      height: 48,
                      // La punta del ícono queda exactamente sobre el punto.
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        color: TemaApp.verde,
                        size: 48,
                      ),
                    ),
                  ],
                ),
                // Capa 3: crédito obligatorio a OpenStreetMap.
                const SimpleAttributionWidget(
                  source: Text('OpenStreetMap'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '${latitud.toStringAsFixed(5)}, ${longitud.toStringAsFixed(5)}',
            style: const TextStyle(fontSize: 12, color: TemaApp.textoSecundario),
          ),
        ),
      ],
    );
  }
}