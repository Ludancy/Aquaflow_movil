import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // JWT emitido por /auth/verify-otp o por el registro; lo setea AppState tras autenticar.
  static String? authToken;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  static Map<String, String> get _authHeadersOnly => {
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  // Default apunta a producción (Render); override con
  // --dart-define=API_BASE_URL=http://10.0.2.2:3000 para desarrollo local.
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) {
      return _apiBaseUrlOverride;
    }
    return 'https://aquaflow-api-qs31.onrender.com';
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

  // Get active tariffs / rates (público)
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

  // Auth: Login directo por teléfono o correo + contraseña (público)
  static Future<Map<String, dynamic>?> login(
    String identificador,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identificador': identificador,
          'password': password,
        }),
      );
      final body = jsonDecode(response.body);
      return {'statusCode': response.statusCode, 'data': body};
    } catch (e) {
      debugPrint('Login error: $e');
    }
    return null;
  }

  // Auth: Send registration OTP to email (público; requerido antes de registrar cuenta nueva)
  static Future<Map<String, dynamic>?> sendRegistrationOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/send-registration-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      debugPrint('Send registration OTP error: $e');
    }
    return null;
  }

  // Users: Register new client (público; devuelve el token de sesión)
  // Nota: siempre devuelve {statusCode, data} -- inclusive en errores (400/409/500) --
  // para que el llamador pueda mostrar el mensaje real de validación, no solo null.
  static Future<Map<String, dynamic>?> registerClient({
    required String nombre,
    required String telefono,
    required String email,
    required String otp,
    required String password,
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
          'otp': otp,
          'password': password,
          if (identificacionFiscal != null)
            'identificacion_fiscal': identificacionFiscal,
        }),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      debugPrint('Register client error: $e');
    }
    return null;
  }

  // Users: Driver onboarding (público; devuelve el token de sesión)
  // Nota: siempre devuelve {statusCode, data}, ver comentario en registerClient.
  static Future<Map<String, dynamic>?> driverOnboarding({
    required String nombre,
    required String telefono,
    required String email,
    required String otp,
    required String password,
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
          'otp': otp,
          'password': password,
          'licencia_conducir': licenciaConducir,
          'rif_personal': rifPersonal,
          'vehiculo': vehiculo,
        }),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      debugPrint('Driver onboarding error: $e');
    }
    return null;
  }

  // Extrae un mensaje legible de una respuesta de error del backend.
  // Cubre tanto errores de validación de Zod ({errors: [{field, message}]})
  // como errores simples de controlador ({error: '...'} / {message: '...'}).
  static String extractErrorMessage(
    dynamic body, {
    String fallback = 'Ocurrió un error inesperado. Intenta de nuevo.',
  }) {
    if (body is! Map) return fallback;
    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is Map && first['message'] != null) {
        return first['message'].toString();
      }
    }
    if (body['error'] != null) return body['error'].toString();
    if (body['message'] != null) return body['message'].toString();
    return fallback;
  }

  // Users: Get profile details (requiere sesión)
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/users/$userId/profile'),
        headers: _authHeadersOnly,
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

  // Users: Add client address (requiere sesión)
  static Future<Map<String, dynamic>?> addAddress({
    required String clientId,
    required String etiqueta,
    required String direccionExacta,
    required String coordenadas,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/users/$clientId/addresses'),
        headers: _headers,
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

  // Orders: Request water order (requiere sesión)
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
        headers: _headers,
        body: jsonEncode(bodyMap),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return decoded;
      }
      // Conservar el cuerpo del error (ej. "Debe calificar el servicio anterior...")
      // en vez de descartarlo: el llamador lo necesita para no simular un pedido
      // que el backend en realidad rechazó.
      debugPrint('Request order failed (${response.statusCode}): $decoded');
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      debugPrint('Request order error: $e');
    }
    return null;
  }

  // Orders: Get orders for a user (requiere sesión)
  static Future<List<dynamic>> getUserOrders(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/orders/user/$userId'),
        headers: _authHeadersOnly,
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

  // Orders: Accept order as driver (requiere sesión)
  static Future<Map<String, dynamic>?> acceptOrder(
    String orderId,
    String driverId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/orders/$orderId/accept'),
        headers: _headers,
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

  // Orders: Update order status (En Ruta, Entregado, etc.) (requiere sesión)
  static Future<Map<String, dynamic>?> updateOrderStatus(
    String orderId,
    String status, {
    String? detalle,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/v1/orders/$orderId/status'),
        headers: _headers,
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

  // Orders: Cancel order (requiere sesión)
  static Future<Map<String, dynamic>?> cancelOrder(
    String orderId,
    String motivo,
    String canceladoPor,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/orders/$orderId/cancel'),
        headers: _headers,
        body: jsonEncode({'motivo': motivo, 'cancelado_por': canceladoPor}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Cancel order error: $e');
    }
    return null;
  }

  // Payments: Upload payment receipt/comprobante image, returns the server URL (requiere sesión)
  static Future<String?> uploadComprobante(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/payments/upload-comprobante'),
      );
      request.headers.addAll(_authHeadersOnly);
      request.files.add(
        await http.MultipartFile.fromPath('comprobante', file.path),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 20),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final relativeUrl = data['data']?['comprobante_url'];
        if (relativeUrl != null) {
          return '$baseUrl$relativeUrl';
        }
      }
    } catch (e) {
      debugPrint('Upload comprobante error: $e');
    }
    return null;
  }

  // Payments: Get company fiscal/financial data (bank, RIF, Zelle, Binance Pay) (público)
  static Future<Map<String, dynamic>?> getPaymentInfo() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/payments/info'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
    } catch (e) {
      debugPrint('Get payment info error: $e');
    }
    return null;
  }

  // Payments: Process payment (requiere sesión)
  static Future<Map<String, dynamic>?> processPayment({
    required String orderId,
    required String metodo,
    required String referencia,
    required double montoPagado,
    String? bancoEmisor,
    String? comprobanteUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/payments/process'),
        headers: _headers,
        body: jsonEncode({
          'id_pedido': orderId,
          'metodo': metodo,
          'referencia': referencia,
          'monto_pagado': montoPagado,
          if (bancoEmisor != null) 'banco_emisor': bancoEmisor,
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

  // Payments: Get driver wallet balance (requiere sesión)
  static Future<Map<String, dynamic>?> getWallet(String driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/payments/wallet/$driverId'),
        headers: _authHeadersOnly,
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

  // Payments: Request wallet withdrawal (requiere sesión)
  static Future<Map<String, dynamic>?> withdrawWallet(
    String driverId,
    double monto,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/payments/wallet/withdraw'),
        headers: _headers,
        body: jsonEncode({'id_cisternero': driverId, 'monto': monto}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Withdraw error: $e');
    }
    return null;
  }

  // Wallet: Get client wallet balance + recharge history (requiere sesión)
  static Future<Map<String, dynamic>?> getClientWallet(String clientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/wallet/$clientId'),
        headers: _authHeadersOnly,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      }
    } catch (e) {
      debugPrint('Get client wallet error: $e');
    }
    return null;
  }

  // Wallet: Request a balance recharge (queda pendiente de verificación por un admin)
  static Future<Map<String, dynamic>?> requestWalletRecharge({
    required String clientId,
    required String metodo,
    required double monto,
    String? referencia,
    String? bancoEmisor,
    String? comprobanteUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/wallet/recharge'),
        headers: _headers,
        body: jsonEncode({
          'id_cliente': clientId,
          'metodo': metodo,
          'monto': monto,
          if (referencia != null) 'referencia': referencia,
          if (bancoEmisor != null) 'banco_emisor': bancoEmisor,
          if (comprobanteUrl != null) 'comprobante_url': comprobanteUrl,
        }),
      );
      return {
        'statusCode': response.statusCode,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      debugPrint('Request wallet recharge error: $e');
    }
    return null;
  }

  // Support: Rating (requiere sesión)
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
        headers: _headers,
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

  // Support: Dispute (requiere sesión)
  static Future<Map<String, dynamic>?> submitDispute({
    required String orderId,
    required String reportadoPor,
    required String tipo,
    required String descripcion,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/support/disputes'),
        headers: _headers,
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

  // Tracking: Update location (requiere sesión)
  static Future<Map<String, dynamic>?> updateLocation({
    required String driverId,
    required String orderId,
    required double latitud,
    required double longitud,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/tracking/location/$driverId'),
        headers: _headers,
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

  // Tracking: Get order location (requiere sesión)
  static Future<Map<String, dynamic>?> getOrderLocation(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/tracking/order/$orderId/location'),
        headers: _authHeadersOnly,
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

  // Tracking: Get notifications (requiere sesión)
  static Future<List<dynamic>> getNotifications(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/tracking/notifications/$userId'),
        headers: _authHeadersOnly,
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

  // Tracking: Mark a single notification as read (requiere sesión)
  static Future<bool> markNotificationRead(String notificationId) async {
    try {
      final response = await http.patch(
        Uri.parse(
          '$baseUrl/api/v1/tracking/notifications/$notificationId/read',
        ),
        headers: _authHeadersOnly,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Mark notification read error: $e');
      return false;
    }
  }

  // Tracking: Mark all notifications as read for a user (requiere sesión)
  static Future<bool> markAllNotificationsRead(String userId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/v1/tracking/notifications/$userId/read-all'),
        headers: _authHeadersOnly,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Mark all notifications read error: $e');
      return false;
    }
  }
}
