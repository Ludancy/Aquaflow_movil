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

  static String getFallbackRegionAddress(LatLng location) {
    final lat = location.latitude;
    final lon = location.longitude;

    if (lat >= 8.15 && lat <= 8.45 && lon >= -62.90 && lon <= -62.55) {
      return 'Puerto Ordaz, Bolívar';
    }
    if (lat >= 10.35 && lat <= 10.60 && lon >= -67.05 && lon <= -66.75) {
      return 'Caracas, Distrito Capital';
    }
    if (lat >= 10.10 && lat <= 10.35 && lon >= -68.10 && lon <= -67.85) {
      return 'Valencia, Carabobo';
    }
    if (lat >= 10.10 && lat <= 10.35 && lon >= -67.70 && lon <= -67.45) {
      return 'Maracay, Aragua';
    }
    if (lat >= 10.55 && lat <= 10.80 && lon >= -71.80 && lon <= -71.45) {
      return 'Maracaibo, Zulia';
    }
    if (lat >= 9.90 && lat <= 10.20 && lon >= -69.50 && lon <= -69.20) {
      return 'Barquisimeto, Lara';
    }
    if (lat >= 8.45 && lat <= 8.75 && lon >= -71.30 && lon <= -71.05) {
      return 'Mérida, Mérida';
    }
    if (lat >= 10.05 && lat <= 10.35 && lon >= -64.80 && lon <= -64.50) {
      return 'Lechería / Barcelona, Anzoátegui';
    }
    if (lat >= 9.60 && lat <= 9.95 && lon >= -63.30 && lon <= -63.05) {
      return 'Maturín, Monagas';
    }
    if (lat >= 10.85 && lat <= 11.10 && lon >= -64.05 && lon <= -63.70) {
      return 'Porlamar, Nueva Esparta';
    }
    return 'Ubicación cercana (${lat.toStringAsFixed(3)}, ${lon.toStringAsFixed(3)})';
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
        'addressdetails': '1',
        'zoom': '18',
      });

      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'AquaFlowApp/1.0 (contacto@aquaflow.com)',
            },
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['address'] != null) {
          final addr = data['address'] as Map<String, dynamic>;
          final road = addr['road'] ??
              addr['pedestrian'] ??
              addr['suburb'] ??
              addr['neighbourhood'] ??
              addr['residential'];
          final city = addr['city'] ??
              addr['town'] ??
              addr['city_district'] ??
              addr['county'] ??
              addr['state'];
          if (road != null && city != null) {
            final res = '$road, $city';
            _reverseCache[cacheKey] = res;
            return res;
          } else if (road != null) {
            final res = road.toString();
            _reverseCache[cacheKey] = res;
            return res;
          } else if (city != null) {
            final res = city.toString();
            _reverseCache[cacheKey] = res;
            return res;
          }
        }

        final rawName = data['display_name'] as String?;
        if (rawName != null && rawName.isNotEmpty) {
          final formatted = formatShortAddress(rawName);
          _reverseCache[cacheKey] = formatted;
          return formatted;
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }

    final fallback = getFallbackRegionAddress(location);
    _reverseCache[cacheKey] = fallback;
    return fallback;
  }

  static String? getCachedAddress(LatLng location) {
    final cacheKey =
        '${location.latitude.toStringAsFixed(4)},${location.longitude.toStringAsFixed(4)}';
    return _reverseCache[cacheKey] ?? getFallbackRegionAddress(location);
  }
}
