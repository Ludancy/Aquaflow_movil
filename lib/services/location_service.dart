import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Verifica permisos y servicio de ubicación, solicitando permiso si hace falta.
  /// Devuelve true si se puede leer la ubicación del dispositivo.
  static Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Posición actual real del dispositivo, o null si no hay permiso/servicio disponible.
  static Future<Position?> getCurrentPosition() async {
    if (!await ensurePermission()) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      return null;
    }
  }

  /// Stream de posiciones en vivo mientras la app está abierta (foreground).
  static Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // metros mínimos entre lecturas
      ),
    );
  }
}
