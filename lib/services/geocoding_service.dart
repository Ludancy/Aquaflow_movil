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
    if (parts.length <= 3) return parts.join(', ');
    return '${parts[0]}, ${parts[1]}, ${parts[2]}';
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

  static List<PlaceSuggestion> getLocalPlaceSuggestions(String query) {
    final q = query.toLowerCase().trim();
    if (q.length < 2) return [];

    final localDb = [
      // Puerto Ordaz / Ciudad Guayana / Bolívar
      PlaceSuggestion(
          displayName: 'Alta Vista, Puerto Ordaz, Bolívar',
          location: LatLng(8.2975, -62.7118)),
      PlaceSuggestion(
          displayName: 'Unare, Puerto Ordaz, Bolívar',
          location: LatLng(8.2831, -62.7482)),
      PlaceSuggestion(
          displayName: 'Castillito, Puerto Ordaz, Bolívar',
          location: LatLng(8.3491, -62.6789)),
      PlaceSuggestion(
          displayName: 'Chilemex, Puerto Ordaz, Bolívar',
          location: LatLng(8.3050, -62.7150)),
      PlaceSuggestion(
          displayName: 'Los Olivos, Puerto Ordaz, Bolívar',
          location: LatLng(8.2910, -62.7230)),
      PlaceSuggestion(
          displayName: 'Villa Alianza, Puerto Ordaz, Bolívar',
          location: LatLng(8.3120, -62.7050)),
      PlaceSuggestion(
          displayName: 'San Félix, Ciudad Guayana, Bolívar',
          location: LatLng(8.3540, -62.6320)),
      PlaceSuggestion(
          displayName: 'Avenida Guayana, Puerto Ordaz, Bolívar',
          location: LatLng(8.3131, -62.7270)),
      PlaceSuggestion(
          displayName: 'Avenida Angosturita, Puerto Ordaz, Bolívar',
          location: LatLng(8.3150, -62.7100)),
      PlaceSuggestion(
          displayName: 'Paseo Caroní, Puerto Ordaz, Bolívar',
          location: LatLng(8.2890, -62.7350)),

      // Caracas / Distrito Capital / Miranda
      PlaceSuggestion(
          displayName: 'Caracas, Distrito Capital',
          location: LatLng(10.4806, -66.9036)),
      PlaceSuggestion(
          displayName: 'Altamira, Chacao, Caracas',
          location: LatLng(10.4960, -66.8530)),
      PlaceSuggestion(
          displayName: 'Las Mercedes, Baruta, Caracas',
          location: LatLng(10.4810, -66.8620)),
      PlaceSuggestion(
          displayName: 'Plaza Venezuela, Caracas',
          location: LatLng(10.4980, -66.8850)),
      PlaceSuggestion(
          displayName: 'Sabana Grande, Caracas',
          location: LatLng(10.4950, -66.8780)),
      PlaceSuggestion(
          displayName: 'Chacao, Miranda, Caracas',
          location: LatLng(10.4920, -66.8560)),
      PlaceSuggestion(
          displayName: 'El Recreo, Caracas',
          location: LatLng(10.4930, -66.8810)),
      PlaceSuggestion(
          displayName: 'Catia, Sucre, Caracas',
          location: LatLng(10.5210, -66.9422)),
      PlaceSuggestion(
          displayName: 'El Valle, Caracas',
          location: LatLng(10.4610, -66.9080)),
      PlaceSuggestion(
          displayName: 'Petare, Sucre, Miranda',
          location: LatLng(10.4780, -66.8150)),

      // Other main cities
      PlaceSuggestion(
          displayName: 'Valencia, Carabobo',
          location: LatLng(10.1620, -68.0077)),
      PlaceSuggestion(
          displayName: 'Maracay, Aragua',
          location: LatLng(10.2469, -67.5958)),
      PlaceSuggestion(
          displayName: 'Maracaibo, Zulia',
          location: LatLng(10.6427, -71.6125)),
      PlaceSuggestion(
          displayName: 'Barquisimeto, Lara',
          location: LatLng(10.0678, -69.3474)),
      PlaceSuggestion(
          displayName: 'Lechería, Anzoátegui',
          location: LatLng(10.1980, -64.6930)),
      PlaceSuggestion(
          displayName: 'Barcelona, Anzoátegui',
          location: LatLng(10.1360, -64.6860)),
      PlaceSuggestion(
          displayName: 'Maturín, Monagas',
          location: LatLng(9.7457, -63.1832)),
      PlaceSuggestion(
          displayName: 'Mérida, Estado Mérida',
          location: LatLng(8.5983, -71.1449)),
      PlaceSuggestion(
          displayName: 'Porlamar, Nueva Esparta',
          location: LatLng(10.9577, -63.8697)),
    ];

    return localDb.where((p) {
      final name = p.displayName.toLowerCase();
      return name.contains(q);
    }).toList();
  }

  static Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return [];

    final suggestions = <PlaceSuggestion>[];

    try {
      final qParam = cleanQuery.toLowerCase().contains('venezuela')
          ? cleanQuery
          : '$cleanQuery, Venezuela';

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': qParam,
        'format': 'jsonv2',
        'limit': '8',
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
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        for (var r in results) {
          final lat = double.tryParse(r['lat']?.toString() ?? '') ?? 0.0;
          final lon = double.tryParse(r['lon']?.toString() ?? '') ?? 0.0;
          final rawName = r['display_name'] as String? ?? cleanQuery;
          final name = formatShortAddress(rawName);
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

    final localMatches = getLocalPlaceSuggestions(cleanQuery);
    for (var match in localMatches) {
      if (!suggestions.any((s) =>
          s.displayName.toLowerCase() == match.displayName.toLowerCase())) {
        suggestions.add(match);
      }
    }

    return suggestions;
  }

  /// Geocodificación inversa detallada: convierte LatLng a Calle, Sector y Ciudad
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
    return _reverseCache[cacheKey];
  }
}
