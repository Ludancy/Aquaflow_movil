import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PlaceSuggestion {
  final String displayName;
  final LatLng location;

  PlaceSuggestion({required this.displayName, required this.location});
}

/// Servicio de Geocodificación híbrido: Nominatim (OpenStreetMap) + Base de Datos de Referencias Locales
class GeocodingService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org/search';
  static const _reverseUrl = 'https://nominatim.openstreetmap.org/reverse';

  static final Map<String, String> _reverseCache = {};
  static final Map<String, List<PlaceSuggestion>> _searchCache = {};

  static DateTime? _lastRequestTime;

  static Future<void> _throttle() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed.inMilliseconds < 1000) {
        await Future.delayed(
            Duration(milliseconds: 1000 - elapsed.inMilliseconds));
      }
    }
    _lastRequestTime = DateTime.now();
  }

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

  // Base de Datos exhaustiva de referencias conocidas (Villa Granada, Alta Vista, San Félix, Upata, etc.)
  static final List<PlaceSuggestion> knownDataset = [
    // Villa Granada, Alta Vista y Puerto Ordaz Centro
    PlaceSuggestion(displayName: 'Calle Antigua (Villa Granada)', location: LatLng(8.3031, -62.7155)),
    PlaceSuggestion(displayName: 'Farmatodo (Villa Granada)', location: LatLng(8.3050, -62.7142)),
    PlaceSuggestion(displayName: 'Bodegón La Caribeña II (Centro Puerto Ordaz)', location: LatLng(8.2985, -62.7210)),
    PlaceSuggestion(displayName: 'Orinokia Mall (Alta Vista)', location: LatLng(8.2941, -62.7231)),
    PlaceSuggestion(displayName: 'Centro Comercial Ciudad Alta Vista I', location: LatLng(8.2965, -62.7250)),
    PlaceSuggestion(displayName: 'Centro Comercial Ciudad Alta Vista II', location: LatLng(8.2970, -62.7245)),
    PlaceSuggestion(displayName: 'Plaza Monumento CVG (Alta Vista)', location: LatLng(8.2952, -62.7261)),
    PlaceSuggestion(displayName: 'Torre Loreto', location: LatLng(8.2990, -62.7235)),
    PlaceSuggestion(displayName: 'Arturo\'s (Alta Vista)', location: LatLng(8.2955, -62.7240)),
    PlaceSuggestion(displayName: 'Mario Bros (Feria Orinokia)', location: LatLng(8.2945, -62.7225)),
    PlaceSuggestion(displayName: 'Clínica Chilemex', location: LatLng(8.3012, -62.7185)),
    PlaceSuggestion(displayName: 'Colegio Loyola Gumilla', location: LatLng(8.3075, -62.7120)),
    PlaceSuggestion(displayName: 'UNEG Sede Principal (Las Américas)', location: LatLng(8.2988, -62.7275)),
    PlaceSuggestion(displayName: 'UNEG Villa Asia', location: LatLng(8.2861, -62.7303)),
    PlaceSuggestion(displayName: 'Universidad Católica Andrés Bello (UCAB Guayana)', location: LatLng(8.2817, -62.7483)),
    PlaceSuggestion(displayName: 'Unexpo (Puerto Ordaz)', location: LatLng(8.2895, -62.7410)),
    PlaceSuggestion(displayName: 'Hotel Rosa Bela', location: LatLng(8.3025, -62.7205)),
    PlaceSuggestion(displayName: 'Hotel Eurobuilding Plaza Guayana', location: LatLng(8.2968, -62.7220)),
    PlaceSuggestion(displayName: 'Supermercado Santo Tomé (Los Olivos)', location: LatLng(8.2880, -62.7355)),
    PlaceSuggestion(displayName: 'Supermercado Santo Tomé (Unare)', location: LatLng(8.2845, -62.7510)),
    PlaceSuggestion(displayName: 'Plaza de las Banderas (Alta Vista)', location: LatLng(8.2930, -62.7285)),
    PlaceSuggestion(displayName: 'Parque La Llovizna (Entrada Principal)', location: LatLng(8.3106, -62.6739)),
    PlaceSuggestion(displayName: 'Parque Cachamay', location: LatLng(8.2939, -62.6958)),
    PlaceSuggestion(displayName: 'Estadio CTE Cachamay', location: LatLng(8.2925, -62.6970)),
    PlaceSuggestion(displayName: 'Aeropuerto Internacional Manuel Piar', location: LatLng(8.2883, -62.7600)),
    PlaceSuggestion(displayName: 'Terminal de Pasajeros Puerto Ordaz', location: LatLng(8.2855, -62.7565)),
    PlaceSuggestion(displayName: 'Redoma de Chilemex', location: LatLng(8.3005, -62.7190)),
    PlaceSuggestion(displayName: 'Redoma La Piña', location: LatLng(8.2810, -62.7650)),
    PlaceSuggestion(displayName: 'C.C. Naraya', location: LatLng(8.2950, -62.7215)),
    PlaceSuggestion(displayName: 'C.C. Mamy', location: LatLng(8.2935, -62.7290)),
    PlaceSuggestion(displayName: 'C.C. Trece', location: LatLng(8.2980, -62.7265)),
    PlaceSuggestion(displayName: 'C.C. Babilonia', location: LatLng(8.2975, -62.7270)),
    PlaceSuggestion(displayName: 'C.C. Zulia', location: LatLng(8.2940, -62.7200)),
    PlaceSuggestion(displayName: 'McDonald\'s Alta Vista', location: LatLng(8.2960, -62.7255)),
    PlaceSuggestion(displayName: 'McDonald\'s Castillito', location: LatLng(8.3150, -62.7050)),
    PlaceSuggestion(displayName: 'Farmatodo (Alta Vista)', location: LatLng(8.2955, -62.7260)),
    PlaceSuggestion(displayName: 'Farmatodo (Los Olivos)', location: LatLng(8.2890, -62.7345)),
    PlaceSuggestion(displayName: 'Mercado Municipal de Unare', location: LatLng(8.2825, -62.7533)),
    PlaceSuggestion(displayName: 'Mercado de Puerto Ordaz (Centro)', location: LatLng(8.3185, -62.7085)),
    PlaceSuggestion(displayName: 'Iglesia Nuestra Señora de Fátima (Centro Cívico)', location: LatLng(8.3170, -62.7090)),
    PlaceSuggestion(displayName: 'Iglesia San Charbel', location: LatLng(8.2995, -62.7160)),
    PlaceSuggestion(displayName: 'Clínica Puerto Ordaz', location: LatLng(8.3165, -62.7065)),
    PlaceSuggestion(displayName: 'Clínica Familia', location: LatLng(8.2865, -62.7495)),
    PlaceSuggestion(displayName: 'Hospital Uyapar', location: LatLng(8.2905, -62.7450)),
    PlaceSuggestion(displayName: 'Sede CVG (Edificio Principal)', location: LatLng(8.2960, -62.7245)),
    PlaceSuggestion(displayName: 'Palacio de Justicia Puerto Ordaz', location: LatLng(8.2920, -62.7295)),
    PlaceSuggestion(displayName: 'Club Ítalo Venezolano de Guayana', location: LatLng(8.3120, -62.6900)),
    PlaceSuggestion(displayName: 'Club Náutico Caroní', location: LatLng(8.3145, -62.6850)),
    PlaceSuggestion(displayName: 'Club Portugués de Guayana', location: LatLng(8.3080, -62.7000)),
    PlaceSuggestion(displayName: 'Plaza del Hierro', location: LatLng(8.2970, -62.7230)),

    // Sectores Residenciales, Avenidas y Escuelas (Puerto Ordaz y San Félix)
    PlaceSuggestion(displayName: 'Av. Guayana (Tramo Alta Vista)', location: LatLng(8.2950, -62.7240)),
    PlaceSuggestion(displayName: 'Av. Atlántico (Intersección UNEG)', location: LatLng(8.2865, -62.7310)),
    PlaceSuggestion(displayName: 'Av. Las Américas', location: LatLng(8.2980, -62.7280)),
    PlaceSuggestion(displayName: 'Av. Paseo Caroní', location: LatLng(8.2850, -62.7480)),
    PlaceSuggestion(displayName: 'Av. Leopoldo Sucre Figarella (Macagua)', location: LatLng(8.3075, -62.6653)),
    PlaceSuggestion(displayName: 'Av. Norte Sur 4 (Unare)', location: LatLng(8.2830, -62.7550)),
    PlaceSuggestion(displayName: 'Calle Caura (Alta Vista)', location: LatLng(8.2965, -62.7225)),
    PlaceSuggestion(displayName: 'Calle Cuchivero', location: LatLng(8.2975, -62.7215)),
    PlaceSuggestion(displayName: 'Calle Aro', location: LatLng(8.2985, -62.7205)),
    PlaceSuggestion(displayName: 'Sector Los Olivos (Plaza)', location: LatLng(8.2875, -62.7360)),
    PlaceSuggestion(displayName: 'Sector Villa Africana', location: LatLng(8.2855, -62.7330)),
    PlaceSuggestion(displayName: 'Sector Villa Asia', location: LatLng(8.2860, -62.7300)),
    PlaceSuggestion(displayName: 'Sector Toro Muerto', location: LatLng(8.2750, -62.7400)),
    PlaceSuggestion(displayName: 'Sector Curagua', location: LatLng(8.2780, -62.7600)),
    PlaceSuggestion(displayName: 'Sector Caujaro', location: LatLng(8.2805, -62.7620)),
    PlaceSuggestion(displayName: 'Sector Core 8 (Entrada)', location: LatLng(8.2650, -62.7800)),
    PlaceSuggestion(displayName: 'Sector Las Garzas', location: LatLng(8.2700, -62.7750)),
    PlaceSuggestion(displayName: 'Sector Río Negro', location: LatLng(8.2850, -62.7420)),
    PlaceSuggestion(displayName: 'Sector Castillito (Plaza)', location: LatLng(8.3155, -62.7055)),
    PlaceSuggestion(displayName: 'Sector Los Mangos', location: LatLng(8.3055, -62.7150)),
    PlaceSuggestion(displayName: 'Colegio Lino Valle', location: LatLng(8.2900, -62.7400)),
    PlaceSuggestion(displayName: 'Colegio Los Próceres', location: LatLng(8.3020, -62.7170)),
    PlaceSuggestion(displayName: 'Colegio Nazaret', location: LatLng(8.3160, -62.7070)),
    PlaceSuggestion(displayName: 'Colegio Iberoamericano', location: LatLng(8.2840, -62.7350)),
    PlaceSuggestion(displayName: 'Escuela Fe y Alegría (Unare)', location: LatLng(8.2810, -62.7540)),
    PlaceSuggestion(displayName: 'Liceo Los Olivos', location: LatLng(8.2885, -62.7365)),
    PlaceSuggestion(displayName: 'Centro Cívico Puerto Ordaz', location: LatLng(8.3175, -62.7080)),
    PlaceSuggestion(displayName: 'Ecomuseo del Caroní (Macagua)', location: LatLng(8.3050, -62.6680)),
    PlaceSuggestion(displayName: 'Represa de Macagua', location: LatLng(8.3075, -62.6653)),
    PlaceSuggestion(displayName: 'Mirador de Macagua', location: LatLng(8.3065, -62.6675)),
    PlaceSuggestion(displayName: 'Plaza Bicentenario (San Félix)', location: LatLng(8.3450, -62.6410)),
    PlaceSuggestion(displayName: 'Cerro El Gallo (San Félix)', location: LatLng(8.3380, -62.6350)),
    PlaceSuggestion(displayName: 'Malecón de San Félix', location: LatLng(8.3485, -62.6450)),
    PlaceSuggestion(displayName: 'Mercado Municipal de San Félix', location: LatLng(8.3460, -62.6430)),
    PlaceSuggestion(displayName: 'Alcaldía de Caroní (Centro San Félix)', location: LatLng(8.3445, -62.6420)),
    PlaceSuggestion(displayName: 'Hospital Dr. Raúl Leoni (Guaiparo)', location: LatLng(8.3350, -62.6550)),
    PlaceSuggestion(displayName: 'Maternidad Negra Hipólita', location: LatLng(8.3300, -62.6500)),
    PlaceSuggestion(displayName: 'Fundación La Salle (San Félix)', location: LatLng(8.3420, -62.6480)),
    PlaceSuggestion(displayName: 'Av. Manuel Piar (San Félix)', location: LatLng(8.3320, -62.6380)),
    PlaceSuggestion(displayName: 'Av. Dalla Costa', location: LatLng(8.3280, -62.6600)),
    PlaceSuggestion(displayName: 'Av. Guayana (Tramo San Félix)', location: LatLng(8.3350, -62.6500)),
    PlaceSuggestion(displayName: 'Redoma El Dorado (San Félix)', location: LatLng(8.3310, -62.6450)),
    PlaceSuggestion(displayName: 'Sector El Roble', location: LatLng(8.3390, -62.6520)),
    PlaceSuggestion(displayName: 'Sector Doña Bárbara', location: LatLng(8.3410, -62.6400)),
    PlaceSuggestion(displayName: 'Sector Moreno de Mendoza', location: LatLng(8.3360, -62.6580)),
    PlaceSuggestion(displayName: 'Sector Vista al Sol', location: LatLng(8.3200, -62.6200)),
    PlaceSuggestion(displayName: 'Sector 11 de Abril', location: LatLng(8.3250, -62.6300)),
    PlaceSuggestion(displayName: 'Sector 25 de Marzo', location: LatLng(8.3150, -62.6100)),
    PlaceSuggestion(displayName: 'Sector Manoa', location: LatLng(8.3350, -62.6480)),
    PlaceSuggestion(displayName: 'Sector UD-145', location: LatLng(8.3300, -62.6550)),

    // Upata
    PlaceSuggestion(displayName: 'Plaza Bolívar de Upata', location: LatLng(8.0142, -62.3931)),
    PlaceSuggestion(displayName: 'Alcaldía del Municipio Piar (Upata)', location: LatLng(8.0145, -62.3928)),
    PlaceSuggestion(displayName: 'Iglesia San Antonio de Padua (Upata)', location: LatLng(8.0139, -62.3935)),
    PlaceSuggestion(displayName: 'Plaza Piar (Upata)', location: LatLng(8.0160, -62.3950)),
    PlaceSuggestion(displayName: 'Mercado Municipal de Upata', location: LatLng(8.0125, -62.3910)),
    PlaceSuggestion(displayName: 'Hospital Andrea Gutiérrez (Upata)', location: LatLng(8.0180, -62.3900)),
    PlaceSuggestion(displayName: 'Terminal de Pasajeros de Upata', location: LatLng(8.0105, -62.3895)),
    PlaceSuggestion(displayName: 'Colegio Morales Marcano (Upata)', location: LatLng(8.0155, -62.3940)),
    PlaceSuggestion(displayName: 'U.E.N. Tavera Acosta (Upata)', location: LatLng(8.0130, -62.3960)),
    PlaceSuggestion(displayName: 'Escuela Básica Nacional Carlos Enrique Álvarez', location: LatLng(8.0175, -62.3920)),
    PlaceSuggestion(displayName: 'U.E. Colegio San Antonio (Upata)', location: LatLng(8.0148, -62.3915)),
    PlaceSuggestion(displayName: 'Liceo Nacional J.M. Siso Martínez (Upata)', location: LatLng(8.0190, -62.3880)),
    PlaceSuggestion(displayName: 'Escuela Técnica Agropecuaria (Upata)', location: LatLng(8.0080, -62.4000)),
    PlaceSuggestion(displayName: 'UNEG Sede Upata', location: LatLng(8.0110, -62.3850)),
    PlaceSuggestion(displayName: 'UDO Extensión Upata', location: LatLng(8.0120, -62.3860)),
    PlaceSuggestion(displayName: 'Misión Sucre Sede Upata', location: LatLng(8.0165, -62.3930)),
    PlaceSuggestion(displayName: 'Plaza Miranda (Upata)', location: LatLng(8.0128, -62.3945)),
    PlaceSuggestion(displayName: 'Plaza Anzoátegui (Upata)', location: LatLng(8.0150, -62.3970)),
    PlaceSuggestion(displayName: 'Parque Bicentenario (Upata)', location: LatLng(8.0185, -62.3955)),
    PlaceSuggestion(displayName: 'Cerro El Toro (Punto de Ascenso)', location: LatLng(8.0250, -62.3800)),
    PlaceSuggestion(displayName: 'Monumento a la Virgen (Entrada Upata)', location: LatLng(8.0210, -62.4050)),
    PlaceSuggestion(displayName: 'Calle Bolívar (Upata)', location: LatLng(8.0140, -62.3930)),
    PlaceSuggestion(displayName: 'Calle Ayacucho (Upata)', location: LatLng(8.0145, -62.3940)),
    PlaceSuggestion(displayName: 'Calle Sucre (Upata)', location: LatLng(8.0150, -62.3920)),
    PlaceSuggestion(displayName: 'Calle Miranda (Upata)', location: LatLng(8.0135, -62.3950)),
    PlaceSuggestion(displayName: 'Calle Vargas (Upata)', location: LatLng(8.0160, -62.3935)),
    PlaceSuggestion(displayName: 'Calle Piar (Upata)', location: LatLng(8.0155, -62.3960)),
    PlaceSuggestion(displayName: 'Calle Unión (Upata)', location: LatLng(8.0125, -62.3925)),
    PlaceSuggestion(displayName: 'Av. Valmore Rodríguez (Upata)', location: LatLng(8.0180, -62.3980)),
    PlaceSuggestion(displayName: 'Av. Bicentenario (Upata)', location: LatLng(8.0110, -62.3900)),
    PlaceSuggestion(displayName: 'Av. Raúl Leoni (Upata)', location: LatLng(8.0100, -62.3950)),
    PlaceSuggestion(displayName: 'Sector Bicentenario (Upata)', location: LatLng(8.0170, -62.3990)),
    PlaceSuggestion(displayName: 'Sector La Romana (Upata)', location: LatLng(8.0190, -62.3920)),
    PlaceSuggestion(displayName: 'Sector San Marcos (Upata)', location: LatLng(8.0200, -62.3950)),
    PlaceSuggestion(displayName: 'Sector Las Malvinas (Upata)', location: LatLng(8.0090, -62.3970)),
    PlaceSuggestion(displayName: 'Sector El Guamito (Upata)', location: LatLng(8.0150, -62.4000)),
    PlaceSuggestion(displayName: 'Sector San Lorenzo (Upata)', location: LatLng(8.0120, -62.4020)),
    PlaceSuggestion(displayName: 'Sector Los Pinos (Upata)', location: LatLng(8.0115, -62.3880)),
    PlaceSuggestion(displayName: 'Sector Coviaguard (Upata)', location: LatLng(8.0085, -62.3910)),
    PlaceSuggestion(displayName: 'Sector Banco Obrero (Upata)', location: LatLng(8.0130, -62.3890)),
    PlaceSuggestion(displayName: 'Farmatodo Upata (Referencia Centro)', location: LatLng(8.0140, -62.3925)),
    PlaceSuggestion(displayName: 'Supermercado El Diamante (Upata)', location: LatLng(8.0135, -62.3930)),
    PlaceSuggestion(displayName: 'Panadería La Mansión del Pan (Upata)', location: LatLng(8.0145, -62.3915)),
    PlaceSuggestion(displayName: 'Banco de Venezuela (Sede Upata)', location: LatLng(8.0142, -62.3920)),
    PlaceSuggestion(displayName: 'Banco Banesco (Upata)', location: LatLng(8.0138, -62.3932)),
    PlaceSuggestion(displayName: 'Banco Mercantil (Upata)', location: LatLng(8.0148, -62.3938)),
    PlaceSuggestion(displayName: 'Banco Provincial (Upata)', location: LatLng(8.0152, -62.3942)),
    PlaceSuggestion(displayName: 'CICPC Sede Upata', location: LatLng(8.0110, -62.3930)),
    PlaceSuggestion(displayName: 'Bomberos de Upata', location: LatLng(8.0120, -62.3905)),
    PlaceSuggestion(displayName: 'Comando GNB (Upata)', location: LatLng(8.0100, -62.3920)),
    PlaceSuggestion(displayName: 'Estadio Simón Chávez (Upata)', location: LatLng(8.0165, -62.3900)),
    PlaceSuggestion(displayName: 'Polideportivo de Upata', location: LatLng(8.0175, -62.3890)),
    PlaceSuggestion(displayName: 'Manga de Coleo (Upata)', location: LatLng(8.0095, -62.3850)),
    PlaceSuggestion(displayName: 'Cementerio Municipal de Upata', location: LatLng(8.0185, -62.3960)),
    PlaceSuggestion(displayName: 'Clínica Piar (Upata)', location: LatLng(8.0150, -62.3955)),
    PlaceSuggestion(displayName: 'Centro Médico Upata', location: LatLng(8.0140, -62.3945)),
    PlaceSuggestion(displayName: 'CDI Bicentenario (Upata)', location: LatLng(8.0170, -62.3985)),
    PlaceSuggestion(displayName: 'Registro Civil de Upata', location: LatLng(8.0144, -62.3929)),
    PlaceSuggestion(displayName: 'Cantv Sede Upata', location: LatLng(8.0136, -62.3938)),
    PlaceSuggestion(displayName: 'Corpoelec Sede Upata', location: LatLng(8.0125, -62.3965)),
    PlaceSuggestion(displayName: 'Abasto Bicentenario (Antiguo CADA Upata)', location: LatLng(8.0140, -62.3910)),
    PlaceSuggestion(displayName: 'Ferretería El Constructor (Upata)', location: LatLng(8.0155, -62.3925)),
    PlaceSuggestion(displayName: 'Hotel Andrea (Upata)', location: LatLng(8.0145, -62.3945)),
    PlaceSuggestion(displayName: 'Hotel Comercio (Upata)', location: LatLng(8.0135, -62.3920)),
    PlaceSuggestion(displayName: 'Posada Turística El Toro (Upata)', location: LatLng(8.0220, -62.3850)),
    PlaceSuggestion(displayName: 'Radio Excelente 107.9 FM (Upata)', location: LatLng(8.0150, -62.3930)),
    PlaceSuggestion(displayName: 'Redoma de los Pinos (Upata)', location: LatLng(8.0110, -62.3870)),
    PlaceSuggestion(displayName: 'Autopista San Félix - Upata (Peaje)', location: LatLng(8.1650, -62.5150)),
    PlaceSuggestion(displayName: 'Club de Leones (Upata)', location: LatLng(8.0160, -62.3910)),
    PlaceSuggestion(displayName: 'Casa de la Cultura (Upata)', location: LatLng(8.0146, -62.3935)),

    // Más comercios, sectores, escuelas y calles
    PlaceSuggestion(displayName: 'C.C. Las Cúpulas (San Félix)', location: LatLng(8.3440, -62.6435)),
    PlaceSuggestion(displayName: 'C.C. Icabarú (San Félix)', location: LatLng(8.3410, -62.6450)),
    PlaceSuggestion(displayName: 'C.C. La Churuata (Puerto Ordaz)', location: LatLng(8.2870, -62.7420)),
    PlaceSuggestion(displayName: 'C.C. Los Olivos', location: LatLng(8.2880, -62.7360)),
    PlaceSuggestion(displayName: 'C.C. Portofino', location: LatLng(8.2930, -62.7210)),
    PlaceSuggestion(displayName: 'C.C. El Trébol 3', location: LatLng(8.2960, -62.7280)),
    PlaceSuggestion(displayName: 'C.C. Trébol 1', location: LatLng(8.2970, -62.7285)),
    PlaceSuggestion(displayName: 'C.C. Plaza Atlántico Mall', location: LatLng(8.2750, -62.7550)),
    PlaceSuggestion(displayName: 'Farmatodo (Paseo Caroní)', location: LatLng(8.2860, -62.7470)),
    PlaceSuggestion(displayName: 'Locatel (Alta Vista)', location: LatLng(8.2945, -62.7240)),
    PlaceSuggestion(displayName: 'Locatel (Unare)', location: LatLng(8.2835, -62.7540)),
    PlaceSuggestion(displayName: 'Redoma de Makro / Redoma La Paz', location: LatLng(8.2920, -62.7150)),
    PlaceSuggestion(displayName: 'Makro Puerto Ordaz', location: LatLng(8.2910, -62.7160)),
    PlaceSuggestion(displayName: 'EPA Puerto Ordaz', location: LatLng(8.2925, -62.7140)),
    PlaceSuggestion(displayName: 'Traki (Alta Vista)', location: LatLng(8.2955, -62.7270)),
    PlaceSuggestion(displayName: 'Traki (San Félix)', location: LatLng(8.3450, -62.6420)),
    PlaceSuggestion(displayName: 'Sede Seniat Puerto Ordaz', location: LatLng(8.2985, -62.7250)),
    PlaceSuggestion(displayName: 'Universidad de Oriente (UDO) San Félix', location: LatLng(8.3300, -62.6450)),
    PlaceSuggestion(displayName: 'Instituto Universitario Pedro Emilio Coll (IUTPEC)', location: LatLng(8.2855, -62.7460)),
    PlaceSuggestion(displayName: 'Colegio Monte Carmelo', location: LatLng(8.2840, -62.7300)),
    PlaceSuggestion(displayName: 'Liceo Manuel Carlos Piar (San Félix)', location: LatLng(8.3380, -62.6480)),
    PlaceSuggestion(displayName: 'Escuela Básica José Luis Ramos (San Félix)', location: LatLng(8.3400, -62.6500)),
    PlaceSuggestion(displayName: 'Escuela Wenceslao Monserratte (San Félix)', location: LatLng(8.3360, -62.6400)),
    PlaceSuggestion(displayName: 'U.E. Antonio José de Sucre (Puerto Ordaz)', location: LatLng(8.2875, -62.7380)),
    PlaceSuggestion(displayName: 'Liceo Oscar Luis Perfetti', location: LatLng(8.2830, -62.7490)),
    PlaceSuggestion(displayName: 'Polideportivo Venalum', location: LatLng(8.2810, -62.7550)),
    PlaceSuggestion(displayName: 'Club Sintralcasa', location: LatLng(8.2790, -62.7600)),
    PlaceSuggestion(displayName: 'Zona Industrial Matanzas (Entrada CVG Alcasa)', location: LatLng(8.2600, -62.8100)),
    PlaceSuggestion(displayName: 'Zona Industrial Matanzas (Entrada CVG Venalum)', location: LatLng(8.2550, -62.8200)),
    PlaceSuggestion(displayName: 'Zona Industrial Matanzas (Entrada Sidor)', location: LatLng(8.2450, -62.8500)),
    PlaceSuggestion(displayName: 'Zona Industrial Unare I', location: LatLng(8.2850, -62.7550)),
    PlaceSuggestion(displayName: 'Zona Industrial Unare II', location: LatLng(8.2810, -62.7600)),
    PlaceSuggestion(displayName: 'Zona Industrial Chirica (San Félix)', location: LatLng(8.3200, -62.6150)),
    PlaceSuggestion(displayName: 'Parque Recreacional Loefling', location: LatLng(8.3050, -62.6900)),
    PlaceSuggestion(displayName: 'Parque La Fundación (San Félix)', location: LatLng(8.3410, -62.6460)),
    PlaceSuggestion(displayName: 'Paseo Rotario', location: LatLng(8.2980, -62.7150)),
    PlaceSuggestion(displayName: 'Iglesia Virgen del Valle (Mendoza, San Félix)', location: LatLng(8.3370, -62.6590)),
    PlaceSuggestion(displayName: 'Iglesia San Buenaventura (El Roble)', location: LatLng(8.3380, -62.6510)),
    PlaceSuggestion(displayName: 'Iglesia Sagrada Familia (Unare)', location: LatLng(8.2840, -62.7520)),
    PlaceSuggestion(displayName: 'Parroquia San Pablo Apóstol (Core 8)', location: LatLng(8.2660, -62.7810)),
    PlaceSuggestion(displayName: 'Catedral de Ciudad Guayana (Pro-Catedral Juan Pablo II)', location: LatLng(8.2960, -62.7205)),
    PlaceSuggestion(displayName: 'Gimnasio Hermanas González (CTE Cachamay)', location: LatLng(8.2930, -62.6980)),
    PlaceSuggestion(displayName: 'Teatro Sidor', location: LatLng(8.3160, -62.7090)),
    PlaceSuggestion(displayName: 'Sede Corpoelec Alta Vista', location: LatLng(8.2950, -62.7230)),
    PlaceSuggestion(displayName: 'Sede Cantv Alta Vista', location: LatLng(8.2975, -62.7250)),
    PlaceSuggestion(displayName: 'Sede Hidrobolívar (Puerto Ordaz)', location: LatLng(8.2980, -62.7240)),
    PlaceSuggestion(displayName: 'Banco Caroní (Sede Principal Alta Vista)', location: LatLng(8.2965, -62.7225)),
    PlaceSuggestion(displayName: 'Banesco (Torre Alta Vista)', location: LatLng(8.2955, -62.7250)),
    PlaceSuggestion(displayName: 'Provincial (Centro Cívico)', location: LatLng(8.3170, -62.7085)),
    PlaceSuggestion(displayName: 'Banco Nacional de Crédito BNC (Alta Vista)', location: LatLng(8.2940, -62.7235)),
    PlaceSuggestion(displayName: 'Panadería La Coromoto (Los Olivos)', location: LatLng(8.2885, -62.7350)),
    PlaceSuggestion(displayName: 'Panadería Majestic (Alta Vista)', location: LatLng(8.2970, -62.7215)),
    PlaceSuggestion(displayName: 'Panadería La espiga de Oro (San Félix)', location: LatLng(8.3430, -62.6410)),
    PlaceSuggestion(displayName: 'McDonald\'s San Félix', location: LatLng(8.3440, -62.6420)),
    PlaceSuggestion(displayName: 'Arturo\'s (San Félix)', location: LatLng(8.3445, -62.6430)),
    PlaceSuggestion(displayName: 'Sector Los Sabanales (San Félix)', location: LatLng(8.3400, -62.6470)),
    PlaceSuggestion(displayName: 'Sector El Gallo (San Félix)', location: LatLng(8.3375, -62.6360)),
    PlaceSuggestion(displayName: 'Sector Inés Romero (San Félix)', location: LatLng(8.3350, -62.6300)),
    PlaceSuggestion(displayName: 'Sector Nueva Chirica (San Félix)', location: LatLng(8.3300, -62.6250)),
    PlaceSuggestion(displayName: 'Sector Francisco de Miranda (San Félix)', location: LatLng(8.3280, -62.6200)),
    PlaceSuggestion(displayName: 'Sector Bella Vista (San Félix)', location: LatLng(8.3150, -62.6050)),
    PlaceSuggestion(displayName: 'Sector Las Amazonas (Core 8)', location: LatLng(8.2640, -62.7820)),
    PlaceSuggestion(displayName: 'Sector Sabana Linda (Core 8)', location: LatLng(8.2655, -62.7850)),
    PlaceSuggestion(displayName: 'Sector Villa Bahía', location: LatLng(8.2700, -62.7900)),
    PlaceSuggestion(displayName: 'Sector Villa Jade', location: LatLng(8.2720, -62.7850)),
    PlaceSuggestion(displayName: 'Sector Yara Yara', location: LatLng(8.2750, -62.7750)),
    PlaceSuggestion(displayName: 'Sector Loma Colorada', location: LatLng(8.2780, -62.7650)),
    PlaceSuggestion(displayName: 'Av. Vía Venezuela', location: LatLng(8.3000, -62.7150)),
    PlaceSuggestion(displayName: 'Av. Caracas', location: LatLng(8.3020, -62.7200)),
    PlaceSuggestion(displayName: 'Av. Norte Sur 1', location: LatLng(8.2900, -62.7400)),
    PlaceSuggestion(displayName: 'Av. Fuerzas Armadas', location: LatLng(8.2800, -62.7500)),
    PlaceSuggestion(displayName: 'Av. Cisneros (San Félix)', location: LatLng(8.3300, -62.6300)),
    PlaceSuggestion(displayName: 'Av. Libertador (San Félix)', location: LatLng(8.3400, -62.6500)),
    PlaceSuggestion(displayName: 'Av. Centurión (San Félix)', location: LatLng(8.3420, -62.6450)),
    PlaceSuggestion(displayName: 'Plaza del Agua (Macagua)', location: LatLng(8.3040, -62.6690)),
    PlaceSuggestion(displayName: 'Isla de Piedra (Parque Llovizna)', location: LatLng(8.3090, -62.6750)),
    PlaceSuggestion(displayName: 'Salto La Llovizna (Mirador)', location: LatLng(8.3085, -62.6730)),
    PlaceSuggestion(displayName: 'Salto Cachamay (Mirador)', location: LatLng(8.2930, -62.6950)),
    PlaceSuggestion(displayName: 'Puente Caroní', location: LatLng(8.3110, -62.6800)),
    PlaceSuggestion(displayName: 'Puente Orinoquia (Peaje)', location: LatLng(8.2883, -62.8944)),
    PlaceSuggestion(displayName: 'Río Caroní (Desembocadura)', location: LatLng(8.3400, -62.6850)),
    PlaceSuggestion(displayName: 'Punta Vista', location: LatLng(8.3100, -62.6950)),
    PlaceSuggestion(displayName: 'CVG Ferrominera Orinoco (Sede Administrativa)', location: LatLng(8.3050, -62.7050)),
    PlaceSuggestion(displayName: 'Club Ferrominera', location: LatLng(8.3060, -62.7020)),
    PlaceSuggestion(displayName: 'Hospital Clínico de Ferrominera (Américo Babó)', location: LatLng(8.3070, -62.7000)),
    PlaceSuggestion(displayName: 'Campo A2 de Ferrominera', location: LatLng(8.3120, -62.7080)),
    PlaceSuggestion(displayName: 'Campo B de Ferrominera', location: LatLng(8.3100, -62.7100)),
    PlaceSuggestion(displayName: 'Campo C de Ferrominera', location: LatLng(8.3080, -62.7120)),
    PlaceSuggestion(displayName: 'Campo Rojo', location: LatLng(8.3200, -62.6950)),
    PlaceSuggestion(displayName: 'Residencias Los Raudales', location: LatLng(8.2950, -62.7280)),
    PlaceSuggestion(displayName: 'Residencias Karuai', location: LatLng(8.2960, -62.7290)),
    PlaceSuggestion(displayName: 'Urbanización Chilemex', location: LatLng(8.3010, -62.7180)),
    PlaceSuggestion(displayName: 'Urbanización Los Saltos', location: LatLng(8.3030, -62.7160)),
    PlaceSuggestion(displayName: 'Urbanización Arivana', location: LatLng(8.3040, -62.7140)),
    PlaceSuggestion(displayName: 'Urbanización Los Rosales', location: LatLng(8.3050, -62.7120)),
    PlaceSuggestion(displayName: 'Urbanización Río Aro', location: LatLng(8.2800, -62.7550)),
    PlaceSuggestion(displayName: 'Urbanización Lomas del Caroní', location: LatLng(8.2750, -62.7600)),
    PlaceSuggestion(displayName: 'Urbanización El Guamo', location: LatLng(8.2720, -62.7650)),
    PlaceSuggestion(displayName: 'Mercado Bicentenario (Unare II)', location: LatLng(8.2815, -62.7580)),
    PlaceSuggestion(displayName: 'Comando de Tránsito (Unare)', location: LatLng(8.2830, -62.7500)),
    PlaceSuggestion(displayName: 'Parque Ecoturístico Macagua', location: LatLng(8.3060, -62.6660)),
    PlaceSuggestion(displayName: 'Balneario Mi Bohío', location: LatLng(8.2700, -62.6500)),
    PlaceSuggestion(displayName: 'Balneario Tierra Nueva', location: LatLng(8.2750, -62.6450)),
    PlaceSuggestion(displayName: 'Balneario El Faro', location: LatLng(8.2800, -62.6400)),
    PlaceSuggestion(displayName: 'Campamento La Llovizna (CVG)', location: LatLng(8.3115, -62.6745)),
    PlaceSuggestion(displayName: 'Puerto de Palúa (San Félix)', location: LatLng(8.3500, -62.6500)),
    PlaceSuggestion(displayName: 'Astilleros de Ciudad Guayana', location: LatLng(8.3450, -62.6600)),
    PlaceSuggestion(displayName: 'Estación de Bomberos de Unare', location: LatLng(8.2820, -62.7520)),
    PlaceSuggestion(displayName: 'Estación de Bomberos de San Félix', location: LatLng(8.3415, -62.6440)),
    PlaceSuggestion(displayName: 'C.C. La Granja (San Félix)', location: LatLng(8.3385, -62.6410)),
    PlaceSuggestion(displayName: 'C.C. Icabarú (San Félix)', location: LatLng(8.3410, -62.6450)),
    PlaceSuggestion(displayName: 'C.C. Piacoa (San Félix)', location: LatLng(8.3395, -62.6420)),
    PlaceSuggestion(displayName: 'C.C. Virgen del Valle', location: LatLng(8.3375, -62.6580)),
    PlaceSuggestion(displayName: 'Clínica Manuel Piar (San Félix)', location: LatLng(8.3405, -62.6435)),
    PlaceSuggestion(displayName: 'Módulo de Barrio Adentro (Vista al Sol)', location: LatLng(8.3210, -62.6210)),
    PlaceSuggestion(displayName: 'Comisaría Guaiparo', location: LatLng(8.3355, -62.6545)),
    PlaceSuggestion(displayName: 'Destacamento 625 GNB (Puerto Ordaz)', location: LatLng(8.2915, -62.7300)),
    PlaceSuggestion(displayName: 'Base Aérea Teófilo Luis Méndez', location: LatLng(8.2870, -62.7610)),
    PlaceSuggestion(displayName: 'Universidad Bicentenaria de Aragua (UBA) Sede San Félix', location: LatLng(8.3320, -62.6390)),
    PlaceSuggestion(displayName: 'Instituto Tecnológico Antonio José de Sucre (UTS)', location: LatLng(8.2965, -62.7210)),
    PlaceSuggestion(displayName: 'Escuela de Canto y Música (Centro Cívico)', location: LatLng(8.3172, -62.7082)),
    PlaceSuggestion(displayName: 'Calle Upata (Puerto Ordaz Centro)', location: LatLng(8.3180, -62.7095)),
    PlaceSuggestion(displayName: 'Calle Guasipati (Puerto Ordaz Centro)', location: LatLng(8.3175, -62.7090)),
    PlaceSuggestion(displayName: 'Calle El Callao (Puerto Ordaz Centro)', location: LatLng(8.3182, -62.7088)),
    PlaceSuggestion(displayName: 'Calle Tumeremo (Puerto Ordaz Centro)', location: LatLng(8.3178, -62.7100)),
    PlaceSuggestion(displayName: 'Farmatodo (Castillito)', location: LatLng(8.3152, -62.7052)),
    PlaceSuggestion(displayName: 'Ferretería EPA (San Félix)', location: LatLng(8.3330, -62.6350)),
    PlaceSuggestion(displayName: 'Auto Mercado El Diamante (Core 8)', location: LatLng(8.2652, -62.7805)),
    PlaceSuggestion(displayName: 'Río Claro (Vía El Pao)', location: LatLng(8.2000, -62.6000)),
    PlaceSuggestion(displayName: 'Distribuidor Redoma El Dorado', location: LatLng(8.3312, -62.6455)),
    PlaceSuggestion(displayName: 'Puesto de Control Peaje Palo Grande (Vía Upata)', location: LatLng(8.2500, -62.5800)),
  ];

  /// Busca coincidencias en la base de datos de referencias locales
  static List<PlaceSuggestion> searchDataset(String query) {
    final q = query.toLowerCase().trim();
    if (q.length < 2) return [];

    final terms = q.split(' ').where((t) => t.length >= 2).toList();
    return knownDataset.where((item) {
      final name = item.displayName.toLowerCase();
      if (terms.isEmpty) return name.contains(q);
      return terms.every((t) => name.contains(t));
    }).toList();
  }

  /// Calcula la distancia en kilómetros entre dos coordenadas (Fórmula Haversine)
  static double _calculateDistanceKm(LatLng p1, LatLng p2) {
    const double r = 6371.0; // Radio de la Tierra en km
    final dLat = (p2.latitude - p1.latitude) * (pi / 180.0);
    final dLon = (p2.longitude - p1.longitude) * (pi / 180.0);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p1.latitude * (pi / 180.0)) *
            cos(p2.latitude * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  /// Encuentra el lugar de referencia más cercano de la base de datos si está a menos de 1.5 km
  static String? findNearestDatasetPlace(LatLng location, {double maxRadiusKm = 1.5}) {
    PlaceSuggestion? closest;
    double minDistance = double.infinity;

    for (var item in knownDataset) {
      final dist = _calculateDistanceKm(location, item.location);
      if (dist < minDistance) {
        minDistance = dist;
        closest = item;
      }
    }

    if (closest != null && minDistance <= maxRadiusKm) {
      return closest.displayName;
    }
    return null;
  }

  /// Busca lugares usando Nominatim en primer lugar, complementado instantáneamente con la base de datos local
  static Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return [];

    final cacheKey = cleanQuery.toLowerCase();
    if (_searchCache.containsKey(cacheKey)) {
      return _searchCache[cacheKey]!;
    }

    final suggestions = <PlaceSuggestion>[];

    // 1. Buscar coincidencias en la base de datos de referencias locales primero para respuesta instantánea
    final localMatches = searchDataset(cleanQuery);
    suggestions.addAll(localMatches);

    // 2. Consultar Nominatim vía red
    try {
      await _throttle();

      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': cleanQuery,
        'countrycodes': 've',
        'format': 'jsonv2',
        'limit': '10',
        'addressdetails': '1',
        'email': 'soporte@aquaflow.com',
      });

      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent':
                  'AquaFlowWaterDeliveryApp/2.0 (contact: soporte@aquaflow.com)',
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
            final loc = LatLng(lat, lon);
            if (!suggestions.any((s) =>
                s.displayName.toLowerCase() == name.toLowerCase() ||
                (s.location.latitude - loc.latitude).abs() < 0.0005 &&
                (s.location.longitude - loc.longitude).abs() < 0.0005)) {
              suggestions.add(PlaceSuggestion(
                displayName: name,
                location: loc,
              ));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Geocoding search error: $e');
    }

    if (suggestions.isNotEmpty) {
      _searchCache[cacheKey] = suggestions;
    }

    return suggestions;
  }

  /// Geocodificación inversa híbrida: consulta Nominatim y si no responde o está lejos, usa la referencia local cercana
  static Future<String?> reverseGeocode(LatLng location) async {
    final cacheKey =
        '${location.latitude.toStringAsFixed(4)},${location.longitude.toStringAsFixed(4)}';
    if (_reverseCache.containsKey(cacheKey)) {
      return _reverseCache[cacheKey];
    }

    try {
      await _throttle();

      final uri = Uri.parse(_reverseUrl).replace(queryParameters: {
        'lat': location.latitude.toString(),
        'lon': location.longitude.toString(),
        'format': 'jsonv2',
        'addressdetails': '1',
        'zoom': '18',
        'email': 'soporte@aquaflow.com',
      });

      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent':
                  'AquaFlowWaterDeliveryApp/2.0 (contact: soporte@aquaflow.com)',
              'Accept-Language': 'es-VE,es;q=0.9',
            },
          )
          .timeout(const Duration(seconds: 8));

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

    // Fallback a lugar conocido más cercano dentro de la base de datos de referencias si Nominatim falla/limita
    final nearest = findNearestDatasetPlace(location, maxRadiusKm: 2.5);
    if (nearest != null) {
      _reverseCache[cacheKey] = nearest;
      return nearest;
    }

    return null;
  }

  static String? getCachedAddress(LatLng location) {
    final cacheKey =
        '${location.latitude.toStringAsFixed(4)},${location.longitude.toStringAsFixed(4)}';
    return _reverseCache[cacheKey];
  }
}
