import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PlaceSuggestion {
  final String displayName;
  final LatLng location;

  PlaceSuggestion({required this.displayName, required this.location});
}

/// Autocompletado de lugares usando Nominatim (OpenStreetMap) — gratuito, sin API key.
/// Respeta la política de uso de Nominatim: requiere un User-Agent identificable
/// y no debe llamarse en cada tecla (usar debounce del lado del widget).
class GeocodingService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org/search';

  static Future<List<PlaceSuggestion>> searchPlaces(String query, {String countryCode = 've'}) async {
    if (query.trim().length < 3) return [];
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'limit': '6',
        'countrycodes': countryCode,
        'addressdetails': '0',
      });

      final response = await http
          .get(uri, headers: {'User-Agent': 'AquaFlowApp/1.0 (contacto@aquaflow.com)'})
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return [];

      final List<dynamic> results = jsonDecode(response.body);
      return results.map((r) {
        final lat = double.tryParse(r['lat']?.toString() ?? '') ?? 0.0;
        final lon = double.tryParse(r['lon']?.toString() ?? '') ?? 0.0;
        return PlaceSuggestion(
          displayName: r['display_name'] as String? ?? query,
          location: LatLng(lat, lon),
        );
      }).toList();
    } catch (e) {
      debugPrint('Geocoding search error: $e');
      return [];
    }
  }
}
