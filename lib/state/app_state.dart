import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/socket_service.dart';

enum AppRole {
  client,
  driver
}

class AppState extends ChangeNotifier {
  // Backend Integration State
  bool isBackendConnected = false;
  String? activeTarifaId;
  List<dynamic> backendTarifas = [];
  Map<String, dynamic>? paymentInfo;

  // Active Logged User Identity
  String? currentUserId;
  String? currentClientId;
  String? currentDriverId;
  String? authToken;

  // Sesión persistida (SharedPreferences) para "Mantener sesión iniciada"
  static const _prefTokenKey = 'aquaflow_auth_token';
  static const _prefUserIdKey = 'aquaflow_user_id';
  static const _prefRolKey = 'aquaflow_rol';

  bool isSessionRestoring = true;

  void setAuthToken(String? token) {
    authToken = token;
    ApiService.authToken = token;
    if (token != null) {
      SocketService.disconnect(); // fuerza reconexión con el token nuevo
      SocketService.connect();
    }
  }

  Future<void> saveSession(String rol) async {
    if (authToken == null || currentUserId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTokenKey, authToken!);
    await prefs.setString(_prefUserIdKey, currentUserId!);
    await prefs.setString(_prefRolKey, rol);
  }

  Future<void> _restoreSession() async {
    if (!isBackendConnected) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_prefTokenKey);
    final userId = prefs.getString(_prefUserIdKey);
    final rol = prefs.getString(_prefRolKey);
    if (token == null || userId == null || rol == null) return;

    setAuthToken(token);
    final profile = await ApiService.getProfile(userId);
    if (profile != null) {
      setCurrentUser(profile, rol);
    } else {
      // Token vencido o usuario eliminado: descartar sesión persistida
      await prefs.remove(_prefTokenKey);
      await prefs.remove(_prefUserIdKey);
      await prefs.remove(_prefRolKey);
      setAuthToken(null);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefTokenKey);
    await prefs.remove(_prefUserIdKey);
    await prefs.remove(_prefRolKey);

    SocketService.disconnect();
    authToken = null;
    ApiService.authToken = null;
    currentUserId = null;
    currentClientId = null;
    currentDriverId = null;
    userName = '';
    userEmail = '';
    userPhone = '';
    deliveryAddress = '';
    userAddresses = [];
    driverName = '';
    driverPhone = '';
    driverEmail = '';
    driverTruck = '';
    driverPlate = '';
    notifyListeners();
  }

  // Active User Info (Empty by default, populated strictly from DB/Registration)
  String userName = '';
  String userEmail = '';
  String userPhone = '';
  String deliveryAddress = '';
  LatLng? deliveryCoords; // coordenadas reales del punto elegido en el buscador/mapa
  List<Map<String, dynamic>> userAddresses = [];

  // Driver details (Empty by default)
  String driverName = '';
  String driverUnit = '';
  String driverPhone = '';
  String driverPlate = '';
  String driverEmail = '';
  String driverTruck = '';

  AppState() {
    _init();
  }

  Future<void> _init() async {
    await initBackendConnection();
    await _restoreSession();
    await _restorePreferredPaymentMethod();
    isSessionRestoring = false;
    notifyListeners();
  }

  Future<void> initBackendConnection() async {
    isBackendConnected = await ApiService.checkHealth();
    if (isBackendConnected) {
      final tarifas = await ApiService.getTarifas();
      backendTarifas = tarifas;
      if (tarifas.isNotEmpty) {
        activeTarifaId = tarifas.first['id_tarifa'];
      }
      paymentInfo = await ApiService.getPaymentInfo();
    }
    notifyListeners();
  }

  void setCurrentUser(Map<String, dynamic> usuarioData, String roleStr) {
    currentUserId = usuarioData['id_usuario'];
    userName = usuarioData['nombre'] ?? '';
    userEmail = usuarioData['email'] ?? '';
    userPhone = usuarioData['telefono'] ?? '';

    if (usuarioData['cliente'] != null) {
      currentClientId = usuarioData['cliente']['id_cliente'];
      if (usuarioData['cliente']['direcciones'] != null &&
          (usuarioData['cliente']['direcciones'] as List).isNotEmpty) {
        final dirs = usuarioData['cliente']['direcciones'] as List;
        userAddresses = dirs.map((d) => {
          'id_direccion': d['id_direccion'],
          'etiqueta': d['etiqueta'],
          'direccion_exacta': d['direccion_exacta'],
          'coordenadas': d['coordenadas'],
        }).toList();
        deliveryAddress = userAddresses.first['direccion_exacta'];
      }
      refreshClientWallet();
    }

    if (usuarioData['cisternero'] != null) {
      currentDriverId = usuarioData['cisternero']['id_cisternero'];
      driverName = usuarioData['nombre'] ?? '';
      driverEmail = usuarioData['email'] ?? '';
      driverPhone = usuarioData['telefono'] ?? '';
      
      if (usuarioData['cisternero']['vehiculo'] != null) {
        final v = usuarioData['cisternero']['vehiculo'];
        driverTruck = '${v['marca'] ?? ''} ${v['modelo'] ?? ''}';
        driverPlate = v['placa'] ?? '';
        driverUnit = 'Unidad #${v['placa'] ?? ''}';
      }
      refreshDriverWallet();
    }

    if (roleStr == 'cisternero') {
      _currentRole = AppRole.driver;
    } else {
      _currentRole = AppRole.client;
    }

    if (currentUserId != null && isBackendConnected) {
      fetchUserOrders();
      fetchNotifications();
    }

    notifyListeners();
  }

  // Notifications (CRD-006)
  List<Map<String, dynamic>> notifications = [];
  int get unreadNotificationsCount => notifications.where((n) => n['leida'] != true).length;

  Future<void> fetchNotifications() async {
    if (!isBackendConnected || currentUserId == null) return;
    final data = await ApiService.getNotifications(currentUserId!);
    notifications = data.cast<Map<String, dynamic>>();
    notifyListeners();
  }

  Future<void> markNotificationRead(String notificationId) async {
    final notif = notifications.firstWhere(
      (n) => n['id_notificacion'] == notificationId,
      orElse: () => {},
    );
    if (notif.isEmpty || notif['leida'] == true) return;
    notif['leida'] = true;
    notifyListeners();
    if (isBackendConnected) {
      await ApiService.markNotificationRead(notificationId);
    }
  }

  Future<void> markAllNotificationsRead() async {
    for (final n in notifications) {
      n['leida'] = true;
    }
    notifyListeners();
    if (isBackendConnected && currentUserId != null) {
      await ApiService.markAllNotificationsRead(currentUserId!);
    }
  }

  // Global Role
  AppRole _currentRole = AppRole.client;
  AppRole get currentRole => _currentRole;

  // Client Selection State
  int selectedLiters = 2000;
  double selectedPrice = 20.00;
  String paymentMethod = 'Pago Movil'; // debe coincidir con el literal Zod del backend (sin tilde)

  // Wallet State (Empty by default)
  double walletBalanceUsd = 0.0;
  double exchangeRate = 36.00;
  
  List<Map<String, dynamic>> savedPaymentMethods = [];
  List<Map<String, dynamic>> recentTransactions = [];

  // Orders State (Empty by default)
  WaterOrder? activeOrder;
  final List<WaterOrder> clientHistory = [];

  // Driver State
  bool isDriverAvailable = true;
  List<WaterOrder> pendingDriverRequests = [];
  final List<WaterOrder> driverHistory = [];
  double totalDriverEarnings = 0.0;
  int tripsCompleted = 0;
  double driverRating = 5.0;

  // CRD-005: Envío periódico de la ubicación real del cisternero mientras el pedido está en curso
  Timer? _locationTimer;

  void _startLocationUpdates() {
    _locationTimer?.cancel();
    // El servidor ya aplica un intervalo mínimo de 10s (CRD-005); este timer solo
    // asegura que no se manden lecturas más seguido que eso.
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (activeOrder == null || currentDriverId == null || !isBackendConnected) return;
      final position = await LocationService.getCurrentPosition();
      if (position == null) return;
      SocketService.sendLocationUpdate(
        idCisternero: currentDriverId!,
        idPedido: activeOrder!.id,
        latitud: position.latitude,
        longitud: position.longitude,
      );
    });
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }



  void setRole(AppRole role) {
    _currentRole = role;
    notifyListeners();
  }

  void selectLiters(int liters, double price) {
    selectedLiters = liters;
    selectedPrice = price;
    notifyListeners();
  }

  void setAddress(String address) {
    deliveryAddress = address;
    notifyListeners();
  }

  // Establecido al elegir un resultado del buscador de lugares (autocompletado)
  void setDeliveryLocation(String address, LatLng coords) {
    deliveryAddress = address;
    deliveryCoords = coords;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    paymentMethod = method;
    notifyListeners();
  }

  // Método de pago preferido del cliente (banco emisor guardado para Pago Móvil).
  // Se persiste localmente para no tener que reescribirlo en cada pedido.
  static const _prefPreferredMethodKey = 'aquaflow_preferred_payment_method';
  static const _prefPreferredBancoKey = 'aquaflow_preferred_banco_emisor';

  String? preferredBancoEmisor;

  Future<void> _restorePreferredPaymentMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final method = prefs.getString(_prefPreferredMethodKey);
    if (method != null) paymentMethod = method;
    preferredBancoEmisor = prefs.getString(_prefPreferredBancoKey);
  }

  Future<void> savePreferredPaymentMethod(String method, {String? bancoEmisor}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPreferredMethodKey, method);
    paymentMethod = method;
    if (bancoEmisor != null && bancoEmisor.isNotEmpty) {
      await prefs.setString(_prefPreferredBancoKey, bancoEmisor);
      preferredBancoEmisor = bancoEmisor;
    } else {
      await prefs.remove(_prefPreferredBancoKey);
      preferredBancoEmisor = null;
    }
    notifyListeners();
  }

  // Address CRUD
  Future<bool> addNewAddress(String label, String address, String coords) async {
    final newAddr = {
      'etiqueta': label,
      'direccion_exacta': address,
      'coordenadas': coords,
    };
    userAddresses.add(newAddr);
    deliveryAddress = address;

    if (isBackendConnected && currentClientId != null) {
      final res = await ApiService.addAddress(
        clientId: currentClientId!,
        etiqueta: label,
        direccionExacta: address,
        coordenadas: coords,
      );
      notifyListeners();
      return res != null;
    }
    notifyListeners();
    return true;
  }

  static OrderStatus _mapEstado(String orderStatusStr) {
    if (orderStatusStr == 'Asignado' || orderStatusStr == 'Aceptado') {
      return OrderStatus.accepted;
    } else if (orderStatusStr == 'En Ruta') {
      return OrderStatus.inTransit;
    } else if (orderStatusStr == 'Entregado') {
      return OrderStatus.delivered;
    } else if (orderStatusStr == 'Cancelado') {
      return OrderStatus.cancelled;
    }
    return OrderStatus.requested;
  }

  // CRD-005: Aplicar un cambio de estado recibido en vivo por el socket de tracking
  // (necesario porque cliente y conductor suelen estar en dispositivos distintos).
  void applyRemoteOrderStatus(String idPedido, String estadoBackend) {
    if (activeOrder == null || activeOrder!.id != idPedido) return;
    activeOrder!.status = _mapEstado(estadoBackend);
    if (activeOrder!.status == OrderStatus.delivered || activeOrder!.status == OrderStatus.cancelled) {
      activeOrder = null;
    }
    notifyListeners();
  }

  // Fetch backend orders strictly from database
  Future<void> fetchUserOrders() async {
    if (!isBackendConnected || currentUserId == null) return;

    final ordersData = await ApiService.getUserOrders(currentUserId!);
    clientHistory.clear();
    pendingDriverRequests.clear();
    activeOrder = null;

    if (ordersData.isNotEmpty) {
      for (var o in ordersData) {
        final orderStatusStr = o['estado_actual'] as String? ?? 'Pendiente';
        final status = _mapEstado(orderStatusStr);

        final driverObj = o['cisternero'];
        String? dName;
        String? dPhone;
        String? dPlate;
        if (driverObj != null && driverObj['usuario'] != null) {
          dName = driverObj['usuario']['nombre'];
          dPhone = driverObj['usuario']['telefono'];
          if (driverObj['vehiculo'] != null) {
            dPlate = driverObj['vehiculo']['placa'];
          }
        }

        final mappedOrder = WaterOrder(
          id: o['id_pedido'] ?? 'Pedido',
          dateTime: DateTime.tryParse(o['fecha_creacion'] ?? '') ?? DateTime.now(),
          liters: (o['tarifa'] != null && o['tarifa']['volumen_litros'] != null)
              ? (o['tarifa']['volumen_litros'] as num).toInt()
              : 2000,
          price: (o['monto_total'] as num?)?.toDouble() ?? selectedPrice,
          address: o['coordenadas_destino'] ?? deliveryAddress,
          paymentMethod: 'Pago Movil',
          status: status,
          driverName: dName,
          driverPhone: dPhone,
          driverPlate: dPlate,
        );

        if (status == OrderStatus.requested || status == OrderStatus.accepted || status == OrderStatus.inTransit) {
          if (activeOrder == null) {
            activeOrder = mappedOrder;
          }
          if (orderStatusStr == 'Pendiente' || orderStatusStr == 'Asignado') {
            pendingDriverRequests.add(mappedOrder);
          }
        }

        clientHistory.add(mappedOrder);
      }
    }
    notifyListeners();
  }

  // Create order from client
  Future<void> createOrder() async {
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    activeOrder = WaterOrder(
      id: orderId,
      dateTime: DateTime.now(),
      liters: selectedLiters,
      price: selectedPrice,
      address: deliveryAddress,
      paymentMethod: paymentMethod,
      status: OrderStatus.requested,
    );
    
    clientHistory.insert(0, activeOrder!);
    pendingDriverRequests.clear();
    pendingDriverRequests.add(activeOrder!);

    if (isBackendConnected) {
      final clientId = currentClientId;
      final tarifaId = activeTarifaId;

      if (clientId != null && tarifaId != null) {
        final res = await ApiService.requestOrder(
          clientId: clientId,
          tarifaId: tarifaId,
          destinationCoords: deliveryCoords != null
              ? '${deliveryCoords!.latitude},${deliveryCoords!.longitude}'
              : (deliveryAddress.isNotEmpty ? deliveryAddress : '10.48,-66.90'),
        );

        if (res != null && res['data'] != null && res['data']['id_pedido'] != null) {
          activeOrder = WaterOrder(
            id: res['data']['id_pedido'],
            dateTime: DateTime.now(),
            liters: selectedLiters,
            price: selectedPrice,
            address: deliveryAddress,
            paymentMethod: paymentMethod,
            status: OrderStatus.requested,
          );
          if (clientHistory.isNotEmpty) {
            clientHistory[0] = activeOrder!;
          }
        }
      }
    }
    
    notifyListeners();
  }

  // Cancel order
  void cancelActiveOrder({String reason = 'Cancelado por usuario'}) async {
    if (activeOrder != null) {
      final oldOrderId = activeOrder!.id;
      activeOrder!.status = OrderStatus.cancelled;
      pendingDriverRequests.clear();
      _stopLocationUpdates();
      activeOrder = null;

      if (isBackendConnected) {
        await ApiService.cancelOrder(
          oldOrderId,
          reason,
          _currentRole == AppRole.client ? 'cliente' : 'cisternero',
        );
      }
    }
    notifyListeners();
  }

  // Driver actions
  void toggleDriverAvailability() {
    isDriverAvailable = !isDriverAvailable;
    notifyListeners();
  }

  void driverAcceptOrder(WaterOrder order) async {
    order.status = OrderStatus.accepted;
    order.driverName = driverName;
    order.driverPhone = driverPhone;
    order.driverPlate = driverUnit;
    
    pendingDriverRequests.remove(order);
    activeOrder = order;
    notifyListeners();

    if (isBackendConnected && currentDriverId != null) {
      await ApiService.acceptOrder(order.id, currentDriverId!);
    }
  }

  void driverRejectOrder(WaterOrder order) {
    pendingDriverRequests.remove(order);
    notifyListeners();
  }

  void driverStartTransit() async {
    if (activeOrder != null) {
      activeOrder!.status = OrderStatus.inTransit;
      notifyListeners();

      if (isBackendConnected) {
        await ApiService.updateOrderStatus(activeOrder!.id, 'En Ruta');
        SocketService.notifyStartTransit(activeOrder!.id);
        if (currentDriverId != null) {
          // CRD-003/CRD-005: usar la ubicación real del dispositivo, no una fija
          final position = await LocationService.getCurrentPosition();
          if (position != null) {
            SocketService.sendLocationUpdate(
              idCisternero: currentDriverId!,
              idPedido: activeOrder!.id,
              latitud: position.latitude,
              longitud: position.longitude,
            );
          }
          _startLocationUpdates();
        }
      }
    }
  }

  void driverCompleteOrder() async {
    if (activeOrder != null) {
      final completedId = activeOrder!.id;
      activeOrder!.status = OrderStatus.delivered;
      driverHistory.insert(0, activeOrder!);
      
      walletBalanceUsd += activeOrder!.price;
      recentTransactions.insert(0, {
        'title': 'Pedido #${completedId.substring(0, completedId.length > 8 ? 8 : completedId.length)}',
        'time': 'Hoy, ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'amount': activeOrder!.price,
        'type': 'order',
      });
      
      totalDriverEarnings += activeOrder!.price;
      tripsCompleted += 1;

      if (isBackendConnected) {
        await ApiService.updateOrderStatus(completedId, 'Entregado');
        SocketService.notifyDelivered(completedId);
        refreshDriverWallet();
      }

      _stopLocationUpdates();
      activeOrder = null;
    }
    notifyListeners();
  }

  // Payment process
  Future<bool> processOrderPayment(String reference, {String? bancoEmisor, String? comprobanteUrl}) async {
    if (activeOrder != null) {
      recentTransactions.insert(0, {
        'title': 'Pago Pedido (${activeOrder!.paymentMethod})',
        'time': 'Hoy, ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'amount': -activeOrder!.price,
        'type': 'order',
      });

      if (isBackendConnected) {
        final res = await ApiService.processPayment(
          orderId: activeOrder!.id,
          metodo: paymentMethod,
          referencia: reference,
          bancoEmisor: bancoEmisor,
          comprobanteUrl: comprobanteUrl,
          montoPagado: activeOrder!.price,
        );
        notifyListeners();
        return res != null;
      }
    }
    notifyListeners();
    return true;
  }

  // Support & Rating
  Future<bool> submitRating({required int puntaje, String? comentario}) async {
    if (isBackendConnected && currentClientId != null && currentDriverId != null) {
      final res = await ApiService.submitRating(
        driverId: currentDriverId!,
        clientId: currentClientId!,
        puntaje: puntaje,
        comentario: comentario,
        rolEmisor: _currentRole == AppRole.client ? 'Cliente' : 'Cisternero',
      );
      return res != null;
    }
    return true;
  }

  Future<bool> submitDispute({required String tipo, required String descripcion}) async {
    if (activeOrder != null && isBackendConnected && currentUserId != null) {
      final res = await ApiService.submitDispute(
        orderId: activeOrder!.id,
        reportadoPor: currentUserId!,
        tipo: tipo,
        descripcion: descripcion,
      );
      return res != null;
    }
    return true;
  }

  // Wallet Methods
  Future<void> refreshDriverWallet() async {
    if (isBackendConnected && currentDriverId != null) {
      final wData = await ApiService.getWallet(currentDriverId!);
      if (wData != null && wData['balance_billetera'] != null) {
        walletBalanceUsd = (wData['balance_billetera'] as num).toDouble();
        notifyListeners();
      }
    }
  }

  // Billetera del cliente (saldo real respaldado por Cliente.saldo_billetera en el backend)
  List<Map<String, dynamic>> clientWalletRecargas = [];

  Future<void> refreshClientWallet() async {
    if (isBackendConnected && currentClientId != null) {
      final wData = await ApiService.getClientWallet(currentClientId!);
      if (wData != null) {
        walletBalanceUsd = (wData['saldo_billetera'] as num?)?.toDouble() ?? walletBalanceUsd;
        clientWalletRecargas = (wData['recargas'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        notifyListeners();
      }
    }
  }

  Future<bool> requestClientWalletRecharge({
    required String metodo,
    required double monto,
    String? referencia,
    String? bancoEmisor,
  }) async {
    if (!isBackendConnected || currentClientId == null) return false;
    final res = await ApiService.requestWalletRecharge(
      clientId: currentClientId!,
      metodo: metodo,
      monto: monto,
      referencia: referencia,
      bancoEmisor: bancoEmisor,
    );
    if (res != null && (res['statusCode'] == 200 || res['statusCode'] == 201)) {
      await refreshClientWallet();
      return true;
    }
    return false;
  }

  Future<bool> withdrawDriverWallet(double amount) async {
    if (walletBalanceUsd >= amount) {
      walletBalanceUsd -= amount;
      recentTransactions.insert(0, {
        'title': 'Retiro Billetera',
        'time': 'Hoy, ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'amount': -amount,
        'type': 'withdraw',
      });

      if (isBackendConnected && currentDriverId != null) {
        final res = await ApiService.withdrawWallet(currentDriverId!, amount);
        notifyListeners();
        return res != null;
      }
      notifyListeners();
      return true;
    }
    return false;
  }

}
