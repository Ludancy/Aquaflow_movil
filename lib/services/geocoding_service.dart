import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PlaceSuggestion {
  final String displayName;
  final LatLng location;

  PlaceSuggestion({required this.displayName, required this.location});
}

/// Geocodificación 100% REAL vía Nominatim (OpenStreetMap). Sin lugares genéricos ni fallbacks simulados.
class GeocodingService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org/search';
  static const _reverseUrl = 'https://nominatim.openstreetmap.org/reverse';

  // Cache en memoria de coordenadas -> dirección formateada recibida desde Nominatim
  static final Map<String, String> _reverseCache = {};

  /// Limpia únicamente el código postal o sufijo redundante del país para legibilidad
  static String cleanDisplayName(String fullAddress) {
    if (fullAddress.trim().isEmpty) return fullAddress;
    final parts = fullAddress
        .split(',')
        .map((s) => s.trim())
        .where((s) =>
            s.isNotEmpty &&
            s.toLowerCase() != 'venezuela' &&
            !RegExp(r'^\d{4,5}$').hasMatch(s))
        .toList();
    return parts.join(', ');
  }

  /// Busca lugares usando exclusivamente la API pública de Nominatim
  static Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return [];

    final suggestions = <PlaceSuggestion>[];

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': cleanQuery,
        'countrycodes': 've',
        'format': 'jsonv2',
        'limit': '10',
        'addressdetails': '1',
      });

      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AquaFlowApp/1.0',
              'Accept-Language': 'es-VE,es;q=0.9',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        for (var r in results) {
          final lat = double.tryParse(r['lat']?.toString() ?? '') ?? 0.0;
          final lon = double.tryParse(r['lon']?.toString() ?? '') ?? 0.0;
          final rawName = r['display_name'] as String? ?? cleanQuery;
          final name = cleanDisplayName(rawName);
          if (lat != 0.0 && lon != 0.0) {
            suggestions.add(PlaceSuggestion(
              displayName: name,
              location: LatLng(lat, lon),
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Geocoding search error: $e');
    }

    return suggestions;
  }

  /// Geocodificación inversa real: solicita a Nominatim los detalles de las coordenadas
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
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AquaFlowApp/1.0',
              'Accept-Language': 'es-VE,es;q=0.9',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final rawName = data['display_name'] as String?;
        if (rawName != null && rawName.trim().isNotEmpty) {
          final clean = cleanDisplayName(rawName);
          _reverseCache[cacheKey] = clean;
          return clean;
        }

        if (data['address'] != null) {
          final addr = data['address'] as Map<String, dynamic>;
          final houseNum = addr['house_number'] ?? addr['building'];
          final road = addr['road'] ??
              addr['pedestrian'] ??
              addr['residential'] ??
              addr['footway'] ??
              addr['path'] ??
              addr['amenity'];
          final suburb = addr['suburb'] ??
              addr['neighbourhood'] ??
              addr['quarter'] ??
              addr['city_district'];
          final city = addr['city'] ??
              addr['town'] ??
              addr['village'] ??
              addr['municipality'] ??
              addr['county'] ??
              addr['state'];

          final parts = <String>[];
          if (road != null) {
            if (houseNum != null) {
              parts.add('$road #$houseNum');
            } else {
              parts.add(road.toString());
            }
          }
          if (suburb != null) parts.add(suburb.toString());
          if (city != null) parts.add(city.toString());

          if (parts.isNotEmpty) {
            final detailed = parts.join(', ');
            _reverseCache[cacheKey] = detailed;
            return detailed;
          }
        }
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
