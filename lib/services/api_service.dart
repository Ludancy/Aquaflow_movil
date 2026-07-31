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
          .timeout(const Duration(seconds: 8));
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

  // Auth: Request OTP login
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

  // Auth: Verify OTP code
  static Future<Map<String, dynamic>?> verifyOtp(String phone, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'telefono': phone, 'otp': otp}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Verify OTP error: $e');
    }
    return null;
  }

  // Users: Register new client
  static Future<Map<String, dynamic>?> registerClient({
    required String nombre,
    required String telefono,
    required String email,
    String? identificacionFiscal,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/users/clients'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'telefono': telefono,
          'email': email,
          if (identificacionFiscal != null) 'identificacion_fiscal': identificacionFiscal,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Register client error: $e');
    }
    return null;
  }

  // Users: Driver onboarding
  static Future<Map<String, dynamic>?> driverOnboarding({
    required String nombre,
    required String telefono,
    required String email,
    required String licenciaConducir,
    required String rifPersonal,
    required Map<String, dynamic> vehiculo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/users/drivers/onboarding'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'telefono': telefono,
          'email': email,
          'licencia_conducir': licenciaConducir,
          'rif_personal': rifPersonal,
          'vehiculo': vehiculo,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Driver onboarding error: $e');
    }
    return null;
  }

  // Users: Get profile details
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/users/$userId/profile'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
    } catch (e) {
      debugPrint('Get profile error: $e');
    }
    return null;
  }

  // Users: Add client address
  static Future<Map<String, dynamic>?> addAddress({
    required String clientId,
    required String etiqueta,
    required String direccionExacta,
    required String coordenadas,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/users/$clientId/addresses'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'etiqueta': etiqueta,
          'direccion_exacta': direccionExacta,
          'coordenadas': coordenadas,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Add address error: $e');
    }
    return null;
  }

  // Orders: Request water order
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

  // Orders: Get orders for a user
  static Future<List<dynamic>> getUserOrders(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/orders/user/$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return data['data'] as List<dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Get user orders error: $e');
    }
    return [];
  }

  // Orders: Accept order as driver
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

  // Orders: Update order status (En Ruta, Entregado, etc.)
  static Future<Map<String, dynamic>?> updateOrderStatus(
      String orderId, String status, {String? detalle}) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/v1/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'estado': status,
          if (detalle != null) 'detalle': detalle,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Update order status error: $e');
    }
    return null;
  }

  // Orders: Cancel order
  static Future<Map<String, dynamic>?> cancelOrder(
      String orderId, String motivo, String canceladoPor) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/orders/$orderId/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'motivo': motivo,
          'cancelado_por': canceladoPor,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Cancel order error: $e');
    }
    return null;
  }

  // Payments: Process payment
  static Future<Map<String, dynamic>?> processPayment({
    required String orderId,
    required String metodo,
    required String referencia,
    required double montoPagado,
    String? comprobanteUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/payments/process'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_pedido': orderId,
          'metodo': metodo,
          'referencia': referencia,
          'monto_pagado': montoPagado,
          if (comprobanteUrl != null) 'comprobante_url': comprobanteUrl,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Process payment error: $e');
    }
    return null;
  }

  // Payments: Get driver wallet balance
  static Future<Map<String, dynamic>?> getWallet(String driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/payments/wallet/$driverId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
    } catch (e) {
      debugPrint('Get wallet error: $e');
    }
    return null;
  }

  // Payments: Request wallet withdrawal
  static Future<Map<String, dynamic>?> withdrawWallet(
      String driverId, double monto) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/payments/wallet/withdraw'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_cisternero': driverId,
          'monto': monto,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Withdraw error: $e');
    }
    return null;
  }

  // Support: Rating
  static Future<Map<String, dynamic>?> submitRating({
    required String driverId,
    required String clientId,
    required int puntaje,
    String? comentario,
    required String rolEmisor,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/support/ratings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_cisternero': driverId,
          'id_cliente': clientId,
          'puntaje': puntaje,
          'comentario': comentario,
          'rol_emisor': rolEmisor,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Submit rating error: $e');
    }
    return null;
  }

  // Support: Dispute
  static Future<Map<String, dynamic>?> submitDispute({
    required String orderId,
    required String reportadoPor,
    required String tipo,
    required String descripcion,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/support/disputes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_pedido': orderId,
          'reportado_por': reportadoPor,
          'tipo': tipo,
          'descripcion': descripcion,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Submit dispute error: $e');
    }
    return null;
  }

  // Tracking: Update location
  static Future<Map<String, dynamic>?> updateLocation({
    required String driverId,
    required String orderId,
    required double latitud,
    required double longitud,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/tracking/location/$driverId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_pedido': orderId,
          'latitud': latitud,
          'longitud': longitud,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Update location error: $e');
    }
    return null;
  }

  // Tracking: Get order location
  static Future<Map<String, dynamic>?> getOrderLocation(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/tracking/order/$orderId/location'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
    } catch (e) {
      debugPrint('Get order location error: $e');
    }
    return null;
  }

  // Tracking: Get notifications
  static Future<List<dynamic>> getNotifications(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/tracking/notifications/$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return data['data'] as List<dynamic>;
        }
      }
    } catch (e) {
      debugPrint('Get notifications error: $e');
    }
    return [];
  }
}
