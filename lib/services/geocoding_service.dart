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
  static const _reverseUrl = 'https://nominatim.openstreetmap.org/reverse';

  // Cache en memoria de coordenadas -> dirección formateada legible
  static final Map<String, String> _reverseCache = {};

  static String formatShortAddress(String fullAddress) {
    if (fullAddress.trim().isEmpty) return fullAddress;
    final parts = fullAddress
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.toLowerCase() != 'venezuela')
        .toList();
    if (parts.length <= 2) return fullAddress;
    return '${parts[0]}, ${parts[1]}';
  }

  static Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    String countryCode = 've',
  }) async {
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
          .get(
            uri,
            headers: {
              'User-Agent': 'AquaFlowApp/1.0 (contacto@aquaflow.com)',
            },
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return [];

      final List<dynamic> results = jsonDecode(response.body);
      return results.map((r) {
        final lat = double.tryParse(r['lat']?.toString() ?? '') ?? 0.0;
        final lon = double.tryParse(r['lon']?.toString() ?? '') ?? 0.0;
        final name = formatShortAddress(r['display_name'] as String? ?? query);
        return PlaceSuggestion(
          displayName: name,
          location: LatLng(lat, lon),
        );
      }).toList();
    } catch (e) {
      debugPrint('Geocoding search error: $e');
      return [];
    }
  }

  /// Geocodificación inversa: convierte coordenadas LatLng a una dirección corta legible
  static Future<String?> reverseGeocode(LatLng location) async {
    final cacheKey =
        '${location.latitude.toStringAsFixed(4)},${location.longitude.toStringAsFixed(4)}';
    if (_reverseCache.containsKey(cacheKey)) {
      return _reverseCache[cacheKey];
    }

    try {
      final uri = Uri.parse(_reverseUrl).replace(queryParameters: {
        'lat': location.latitude.toString(),
        'lon': location.longitude.toString(),
        'format': 'jsonv2',
      });

      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'AquaFlowApp/1.0 (contacto@aquaflow.com)',
            },
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = jsonDecode(response.body);
      final rawName = data['display_name'] as String?;
      if (rawName != null && rawName.isNotEmpty) {
        final formatted = formatShortAddress(rawName);
        _reverseCache[cacheKey] = formatted;
        return formatted;
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
    return null;
  }

  static String? getCachedAddress(LatLng location) {
    final cacheKey =
        '${location.latitude.toStringAsFixed(4)},${location.longitude.toStringAsFixed(4)}';
    return _reverseCache[cacheKey];
  }
}
