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

  const RealMapWidget({
    Key? key,
    this.clientLocation,
    this.driverLocation,
    this.showRoute = true,
    this.zoom = 14.0,
    this.controller,
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
    final newLoc = widget.clientLocation;
    if (newLoc != null && newLoc != oldWidget.clientLocation) {
      // El buscador (u otra fuente) movió la ubicación de referencia: recentrar el mapa.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(newLoc, _mapController.camera.zoom);
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
    // Coordinates default: Caracas, Venezuela (10.4806, -66.9036)
    final clientPos = widget.clientLocation ?? const LatLng(10.4806, -66.9036);
    final driverPos = widget.driverLocation ?? LatLng(clientPos.latitude + 0.012, clientPos.longitude - 0.015);

    final routePoints = [
      driverPos,
      LatLng(driverPos.latitude - 0.004, driverPos.longitude + 0.005),
      LatLng(driverPos.latitude - 0.008, driverPos.longitude + 0.009),
      clientPos,
    ];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: clientPos,
        initialZoom: widget.zoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // CARTO Dark Matter — tiles oscuras gratuitas (sin API key), en sintonía con
        // el tema navy/azul de la app en vez del blanco de OSM estándar.
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.aguaexpress.aguaexpress',
        ),

        // Atribución requerida por CARTO/OpenStreetMap, con estilo acorde al tema oscuro
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

        // Route Polyline
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

        // Markers
        MarkerLayer(
          markers: [
            // Client Location Marker
            Marker(
              point: clientPos,
              width: 50,
              height: 50,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryBlue, width: 2),
                    ),
                    child: const Icon(
                      Icons.home,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Driver Cistern Truck Marker
            Marker(
              point: driverPos,
              width: 50,
              height: 50,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFC2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Alias for backwards compatibility with existing screens
typedef MockMapWidget = RealMapWidget;
