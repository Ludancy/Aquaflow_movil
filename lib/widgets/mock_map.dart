import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme.dart';

class RealMapWidget extends StatefulWidget {
  final LatLng? clientLocation;
  final LatLng? driverLocation;
  final bool showRoute;
  final double zoom;
  final MapController? controller;
  final bool isDriverView;

  const RealMapWidget({
    Key? key,
    this.clientLocation,
    this.driverLocation,
    this.showRoute = true,
    this.zoom = 14.0,
    this.controller,
    this.isDriverView = false,
  }) : super(key: key);

  @override
  State<RealMapWidget> createState() => _RealMapWidgetState();
}

class _RealMapWidgetState extends State<RealMapWidget> {
  late final MapController _mapController;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _mapController = widget.controller ?? MapController();
  }

  @override
  void didUpdateWidget(covariant RealMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focusLoc = widget.isDriverView
        ? (widget.driverLocation ?? widget.clientLocation)
        : widget.clientLocation;
    final oldFocusLoc = widget.isDriverView
        ? (oldWidget.driverLocation ?? oldWidget.clientLocation)
        : oldWidget.clientLocation;

    if (focusLoc != null && focusLoc != oldFocusLoc) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(focusLoc, _mapController.camera.zoom);
      });
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _mapController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Coordenadas por defecto: Caracas, Venezuela (10.4806, -66.9036)
    final clientPos = widget.clientLocation ?? const LatLng(10.4806, -66.9036);
    final driverPos = widget.driverLocation ??
        LatLng(clientPos.latitude + 0.012, clientPos.longitude - 0.015);
    final initialPos = widget.isDriverView ? driverPos : clientPos;

    final routePoints = [
      driverPos,
      LatLng(driverPos.latitude - 0.004, driverPos.longitude + 0.005),
      LatLng(driverPos.latitude - 0.008, driverPos.longitude + 0.009),
      clientPos,
    ];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialPos,
        initialZoom: widget.zoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // CARTO Dark Matter — tiles oscuras en sintonía con el tema de la app
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.aguaexpress.aguaexpress',
        ),

        // Atribución requerida por CARTO/OpenStreetMap
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          popupInitialDisplayDuration: const Duration(seconds: 3),
          showFlutterMapAttribution: false,
          popupBackgroundColor: AppTheme.cardDark,
          attributions: const [
            TextSourceAttribution('© OpenStreetMap contributors'),
            TextSourceAttribution('© CARTO'),
          ],
        ),

        // Línea de Ruta de Navegación
        if (widget.showRoute)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 4.5,
                color: AppTheme.primaryBlue,
              ),
            ],
          ),

        // Marcadores de Ubicación
        MarkerLayer(
          markers: [
            // Marcador de Ubicación del Cliente (Persona / Usuario)
            Marker(
              point: clientPos,
              width: 60,
              height: 60,
              child: _buildClientPersonMarker(),
            ),

            // Marcador de Ubicación del Cisternero (Camión / Conductor)
            Marker(
              point: driverPos,
              width: 60,
              height: 60,
              child: _buildDriverTruckMarker(),
            ),
          ],
        ),
      ],
    );
  }

  /// Marcador resaltante de ubicación para el Cliente (Persona con halo azul brillante)
  Widget _buildClientPersonMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Aura de pulso translúcida exterior
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.28),
                shape: BoxShape.circle,
              ),
            ),
            // Círculo brillante con icono distintivo de Persona / Usuario
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppTheme.cardDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_pin_circle,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Marcador de Ubicación para el Cisternero (Camión / Conductor con halo neón esmeralda)
  Widget _buildDriverTruckMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Aura exterior esmeralda neón
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF00FFC2).withOpacity(0.28),
                shape: BoxShape.circle,
              ),
            ),
            // Círculo neón con icono de camión de cisterna
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF00FFC2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFC2).withOpacity(0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_shipping,
                color: Colors.black,
                size: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Alias para compatibilidad con todas las pantallas de la aplicación
typedef MockMapWidget = RealMapWidget;
