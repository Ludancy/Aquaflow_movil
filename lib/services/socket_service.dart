import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io_client;
import 'api_service.dart';

/// Envoltorio del socket de tracking en tiempo real (CRD-005).
/// El servidor exige el mismo JWT emitido por /auth/verify-otp o el registro.
class SocketService {
  static io_client.Socket? _socket;

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

    _socket!.onConnectError((data) => debugPrint('Socket connect error: $data'));
    _socket!.onError((data) => debugPrint('Socket error: $data'));
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

  static void notifyStartTransit(String idPedido) {
    _socket?.emit('order:start', {'id_pedido': idPedido});
  }

  static void notifyDelivered(String idPedido) {
    _socket?.emit('order:delivered', {'id_pedido': idPedido});
  }

  static void onLocationUpdated(void Function(Map<String, dynamic> data) callback) {
    _socket?.on('location:updated', (data) => callback(Map<String, dynamic>.from(data as Map)));
  }

  static void onOrderStatus(void Function(Map<String, dynamic> data) callback) {
    _socket?.on('order:status', (data) => callback(Map<String, dynamic>.from(data as Map)));
  }

  static void offLocationUpdated() => _socket?.off('location:updated');
  static void offOrderStatus() => _socket?.off('order:status');
}
