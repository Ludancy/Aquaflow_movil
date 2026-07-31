import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme.dart';

class RealMapWidget extends StatelessWidget {
  final LatLng? clientLocation;
  final LatLng? driverLocation;
  final bool showRoute;
  final double zoom;

  const RealMapWidget({
    Key? key,
    this.clientLocation,
    this.driverLocation,
    this.showRoute = true,
    this.zoom = 14.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Coordinates default: Caracas, Venezuela (10.4806, -66.9036)
    final clientPos = clientLocation ?? const LatLng(10.4806, -66.9036);
    final driverPos = driverLocation ?? LatLng(clientPos.latitude + 0.012, clientPos.longitude - 0.015);

    final routePoints = [
      driverPos,
      LatLng(driverPos.latitude - 0.004, driverPos.longitude + 0.005),
      LatLng(driverPos.latitude - 0.008, driverPos.longitude + 0.009),
      clientPos,
    ];

    return FlutterMap(
      options: MapOptions(
        initialCenter: clientPos,
        initialZoom: zoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // OpenStreetMap 100% Free Tile Layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.aguaexpress.aguaexpress',
        ),

        // Route Polyline
        if (showRoute)
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
