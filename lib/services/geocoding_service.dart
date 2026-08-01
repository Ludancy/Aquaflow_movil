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

  /// Mantiene la dirección completa de Nominatim (calle, sector, edificio, municipio, estado)
  /// eliminando únicamente el código postal o sufijos redundantes de país.
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

  static String getFallbackRegionAddress(LatLng location) {
    final lat = location.latitude;
    final lon = location.longitude;

    if (lat >= 8.15 && lat <= 8.45 && lon >= -62.90 && lon <= -62.55) {
      return 'Puerto Ordaz, Estado Bolívar';
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
          displayName: 'Sector Alta Vista, Puerto Ordaz, Municipio Caroní, Estado Bolívar',
          location: LatLng(8.2975, -62.7118)),
      PlaceSuggestion(
          displayName: 'Sector Unare, Puerto Ordaz, Municipio Caroní, Estado Bolívar',
          location: LatLng(8.2831, -62.7482)),
      PlaceSuggestion(
          displayName: 'Castillito, Puerto Ordaz, Municipio Caroní, Estado Bolívar',
          location: LatLng(8.3491, -62.6789)),
      PlaceSuggestion(
          displayName: 'Chilemex, Puerto Ordaz, Municipio Caroní, Estado Bolívar',
          location: LatLng(8.3050, -62.7150)),
      PlaceSuggestion(
          displayName: 'Urbanización Los Olivos, Puerto Ordaz, Estado Bolívar',
          location: LatLng(8.2910, -62.7230)),
      PlaceSuggestion(
          displayName: 'Urbanización Villa Alianza, Puerto Ordaz, Estado Bolívar',
          location: LatLng(8.3120, -62.7050)),
      PlaceSuggestion(
          displayName: 'San Félix, Ciudad Guayana, Municipio Caroní, Estado Bolívar',
          location: LatLng(8.3540, -62.6320)),
      PlaceSuggestion(
          displayName: 'Avenida Guayana, Puerto Ordaz, Estado Bolívar',
          location: LatLng(8.3131, -62.7270)),
      PlaceSuggestion(
          displayName: 'Avenida Angosturita, Puerto Ordaz, Estado Bolívar',
          location: LatLng(8.3150, -62.7100)),
      PlaceSuggestion(
          displayName: 'Paseo Caroní, Unare, Puerto Ordaz, Estado Bolívar',
          location: LatLng(8.2890, -62.7350)),

      // Caracas / Distrito Capital / Miranda
      PlaceSuggestion(
          displayName: 'Caracas, Distrito Capital',
          location: LatLng(10.4806, -66.9036)),
      PlaceSuggestion(
          displayName: 'Altamira, Municipio Chacao, Caracas, Estado Miranda',
          location: LatLng(10.4960, -66.8530)),
      PlaceSuggestion(
          displayName: 'Las Mercedes, Municipio Baruta, Caracas, Estado Miranda',
          location: LatLng(10.4810, -66.8620)),
      PlaceSuggestion(
          displayName: 'Plaza Venezuela, Los Caobos, Caracas, Distrito Capital',
          location: LatLng(10.4980, -66.8850)),
      PlaceSuggestion(
          displayName: 'Bulevar de Sabana Grande, Caracas, Distrito Capital',
          location: LatLng(10.4950, -66.8780)),
      PlaceSuggestion(
          displayName: 'Catia, Parroquia Sucre, Caracas, Distrito Capital',
          location: LatLng(10.5210, -66.9422)),
      PlaceSuggestion(
          displayName: 'El Valle, Parroquia El Valle, Caracas, Distrito Capital',
          location: LatLng(10.4610, -66.9080)),
      PlaceSuggestion(
          displayName: 'Petare, Municipio Sucre, Estado Miranda',
          location: LatLng(10.4780, -66.8150)),

      // Other main cities
      PlaceSuggestion(
          displayName: 'Valencia, Estado Carabobo',
          location: LatLng(10.1620, -68.0077)),
      PlaceSuggestion(
          displayName: 'Maracay, Estado Aragua',
          location: LatLng(10.2469, -67.5958)),
      PlaceSuggestion(
          displayName: 'Maracaibo, Estado Zulia',
          location: LatLng(10.6427, -71.6125)),
      PlaceSuggestion(
          displayName: 'Barquisimeto, Estado Lara',
          location: LatLng(10.0678, -69.3474)),
      PlaceSuggestion(
          displayName: 'Lechería, Municipio Urbaneja, Estado Anzoátegui',
          location: LatLng(10.1980, -64.6930)),
      PlaceSuggestion(
          displayName: 'Maturín, Estado Monagas',
          location: LatLng(9.7457, -63.1832)),
      PlaceSuggestion(
          displayName: 'Mérida, Municipio Libertador, Estado Mérida',
          location: LatLng(8.5983, -71.1449)),
      PlaceSuggestion(
          displayName: 'Porlamar, Municipio Mariño, Estado Nueva Esparta',
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
          .timeout(const Duration(seconds: 8));

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

    final localMatches = getLocalPlaceSuggestions(cleanQuery);
    for (var match in localMatches) {
      if (!suggestions.any((s) =>
          s.displayName.toLowerCase().contains(match.displayName.toLowerCase()) ||
          match.displayName.toLowerCase().contains(s.displayName.toLowerCase()))) {
        suggestions.add(match);
      }
    }

    return suggestions;
  }

  /// Geocodificación inversa detallada completa: convierte LatLng a la dirección completa de Nominatim
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
