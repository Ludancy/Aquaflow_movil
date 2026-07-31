import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else {
      try {
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:3000';
        }
      } catch (_) {}
      return 'http://localhost:3000';
    }
  }

  // Health check endpoint
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'ok';
      }
    } catch (e) {
      debugPrint('API Health Check failed: $e');
    }
    return false;
  }

  // Get active tariffs / rates
  static Future<List<dynamic>> getTarifas() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/admin/tarifas'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return data['data'] as List<dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Error fetching tarifas: $e');
    }
    return [];
  }

  // Request OTP login
  static Future<Map<String, dynamic>?> login(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'telefono': phone}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }
    return null;
  }

  // Request water order
  static Future<Map<String, dynamic>?> requestOrder({
    required String clientId,
    required String tarifaId,
    required String destinationCoords,
    String? promoCode,
  }) async {
    try {
      final bodyMap = <String, dynamic>{
        'id_cliente': clientId,
        'id_tarifa': tarifaId,
        'coordenadas_destino': destinationCoords,
      };
      if (promoCode != null && promoCode.isNotEmpty) {
        bodyMap['codigo_promocion'] = promoCode;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/orders/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyMap),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Request order error: $e');
    }
    return null;
  }

  // Accept order as driver
  static Future<Map<String, dynamic>?> acceptOrder(
      String orderId, String driverId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/orders/$orderId/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_cisternero': driverId}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Accept order error: $e');
    }
    return null;
  }
}
