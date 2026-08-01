import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io_client;
import 'api_service.dart';

/// Envoltorio del socket de tracking en tiempo real (CRD-005).
/// El servidor exige el mismo JWT emitido por /auth/verify-otp o el registro.
class SocketService {
  static io_client.Socket? _socket;

  static final List<void Function(Map<String, dynamic>)> _newDriverRequestCallbacks = [];
  static final List<void Function(Map<String, dynamic>)> _orderStatusCallbacks = [];
  static final List<void Function(Map<String, dynamic>)> _locationUpdatedCallbacks = [];

  static bool get isConnected => _socket?.connected ?? false;

  static void connect() {
    if (_socket != null) return;

    _socket = io_client.io(
      ApiService.baseUrl,
      io_client.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': ApiService.authToken})
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[SOCKET] Conectado con id: ${_socket?.id}');
      _attachListeners();
    });

    _socket!.onConnectError(
      (data) => debugPrint('[SOCKET] Connect error: $data'),
    );
    _socket!.onError((data) => debugPrint('[SOCKET] Error: $data'));

    _attachListeners();
  }

  static void _attachListeners() {
    if (_socket == null) return;

    _socket!.off('driver:new_request');
    _socket!.on('driver:new_request', (data) {
      final mapData = Map<String, dynamic>.from(data as Map);
      for (var cb in List.from(_newDriverRequestCallbacks)) {
        cb(mapData);
      }
    });

    _socket!.off('order:status');
    _socket!.on('order:status', (data) {
      final mapData = Map<String, dynamic>.from(data as Map);
      for (var cb in List.from(_orderStatusCallbacks)) {
        cb(mapData);
      }
    });

    _socket!.off('location:updated');
    _socket!.on('location:updated', (data) {
      final mapData = Map<String, dynamic>.from(data as Map);
      for (var cb in List.from(_locationUpdatedCallbacks)) {
        cb(mapData);
      }
    });
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  static void joinOrder(String orderId, String rol) {
    connect();
    _socket?.emit('join:order', {'id_pedido': orderId, 'rol': rol});
  }

  static void leaveOrder(String orderId) {
    _socket?.emit('leave:order', {'id_pedido': orderId});
  }

  static void sendLocationUpdate({
    required String idCisternero,
    required String idPedido,
    required double latitud,
    required double longitud,
  }) {
    _socket?.emit('location:update', {
      'id_cisternero': idCisternero,
      'id_pedido': idPedido,
      'latitud': latitud,
      'longitud': longitud,
    });
  }

  /// Ping de presencia mientras el cisternero está disponible pero sin pedido activo.
  /// No se persiste en BD; solo mantiene su última posición en memoria en el servidor
  /// para que el algoritmo de asignación pueda encontrarlo.
  static void sendLocationPing({
    required String idCisternero,
    required double latitud,
    required double longitud,
  }) {
    connect();
    _socket?.emit('location:ping', {
      'id_cisternero': idCisternero,
      'latitud': latitud,
      'longitud': longitud,
    });
  }

  static void notifyStartTransit(String idPedido) {
    _socket?.emit('order:start', {'id_pedido': idPedido});
  }

  static void notifyDelivered(String idPedido) {
    _socket?.emit('order:delivered', {'id_pedido': idPedido});
  }

  static void onLocationUpdated(
    void Function(Map<String, dynamic> data) callback,
  ) {
    if (!_locationUpdatedCallbacks.contains(callback)) {
      _locationUpdatedCallbacks.add(callback);
    }
    connect();
    _attachListeners();
  }

  static void onOrderStatus(void Function(Map<String, dynamic> data) callback) {
    if (!_orderStatusCallbacks.contains(callback)) {
      _orderStatusCallbacks.add(callback);
    }
    connect();
    _attachListeners();
  }

  /// Aviso al cisternero de que le acaban de asignar un pedido nuevo. Independiente de
  /// order:status/join:order porque el cisternero no conoce el id del pedido de antemano
  /// (no puede haberse unido a esa sala) — llega por su sala personal (`usuario:<id>`).
  static void onNewDriverRequest(
    void Function(Map<String, dynamic> data) callback,
  ) {
    if (!_newDriverRequestCallbacks.contains(callback)) {
      _newDriverRequestCallbacks.add(callback);
    }
    connect();
    _attachListeners();
  }

  static void offLocationUpdated() => _locationUpdatedCallbacks.clear();
  static void offOrderStatus() => _orderStatusCallbacks.clear();
  static void offNewDriverRequest() => _newDriverRequestCallbacks.clear();
}
