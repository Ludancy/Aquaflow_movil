import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../services/socket_service.dart';
import '../widgets/mock_map.dart';

enum AppRole { client, driver }

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
    _stopPresenceUpdates();
    _stopLocationUpdates();
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
  LatLng?
  deliveryCoords; // coordenadas reales del punto elegido en el buscador/mapa
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
        selectLiters(selectedLiters, selectedPrice);
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
        userAddresses = dirs
            .map(
              (d) => {
                'id_direccion': d['id_direccion'],
                'etiqueta': d['etiqueta'],
                'direccion_exacta': d['direccion_exacta'],
                'coordenadas': d['coordenadas'],
              },
            )
            .toList();
        deliveryAddress = userAddresses.first['direccion_exacta'];
        if (userAddresses.first['coordenadas'] != null) {
          final coordsStr = userAddresses.first['coordenadas'] as String;
          final parts = coordsStr.split(',');
          if (parts.length == 2) {
            final lat = double.tryParse(parts[0].trim());
            final lng = double.tryParse(parts[1].trim());
            if (lat != null && lng != null) {
              deliveryCoords = LatLng(lat, lng);
            }
          }
        }
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
      if (isDriverAvailable) {
        _startPresenceUpdates();
      }
      _listenForNewDriverRequests();
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
  int get unreadNotificationsCount =>
      notifications.where((n) => n['leida'] != true).length;

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
  String paymentMethod =
      'Pago Movil'; // debe coincidir con el literal Zod del backend (sin tilde)

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
  LatLng? driverCurrentCoords;
  List<WaterOrder> pendingDriverRequests = [];
  final List<WaterOrder> driverHistory = [];
  double totalDriverEarnings = 0.0;
  double totalWithdrawn = 0.0;
  int tripsCompleted = 0;
  double driverRating = 5.0;

  // CRD-005: Envío periódico de la ubicación real del cisternero mientras el pedido está en curso
  Timer? _locationTimer;

  void _startLocationUpdates() {
    _locationTimer?.cancel();
    // El servidor ya aplica un intervalo mínimo de 10s (CRD-005); este timer solo
    // asegura que no se manden lecturas más seguido que eso.
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (activeOrder == null || currentDriverId == null || !isBackendConnected)
        return;
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

  // Ping de presencia: mientras el cisternero está "Disponible" pero sin pedido activo,
  // el algoritmo de asignación del backend necesita saber dónde está para poder
  // encontrarlo (ver AppState.toggleDriverAvailability y SocketService.sendLocationPing).
  Timer? _presenceTimer;
  Timer? _driverPollTimer;

  void _startPresenceUpdates() {
    if (currentDriverId == null || !isBackendConnected) return;
    _sendPresencePing();
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _sendPresencePing(),
    );
    _startDriverPolling();
  }

  void _stopPresenceUpdates() {
    _presenceTimer?.cancel();
    _presenceTimer = null;
    _stopDriverPolling();
  }

  void _startDriverPolling() {
    _driverPollTimer?.cancel();
    // Polling de respaldo cada 8s para sincronizar nuevos pedidos pendientes en vivo
    // aun si una señal de socket se pierde por parpadeo de red móvil.
    _driverPollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) {
        if (isDriverAvailable && currentDriverId != null && isBackendConnected) {
          fetchUserOrders();
        }
      },
    );
  }

  void _stopDriverPolling() {
    _driverPollTimer?.cancel();
    _driverPollTimer = null;
  }

  Future<void> _sendPresencePing() async {
    if (currentDriverId == null || !isBackendConnected || !isDriverAvailable) {
      debugPrint(
        '[PRESENCE] Ping omitido: driverId=$currentDriverId backendConnected=$isBackendConnected available=$isDriverAvailable',
      );
      return;
    }
    final position = await LocationService.getCurrentPosition();
    if (position == null) {
      debugPrint(
        '[PRESENCE] Ping omitido: no se pudo obtener la posición (GPS/permiso)',
      );
      return;
    }
    driverCurrentCoords = LatLng(position.latitude, position.longitude);
    SocketService.connect();
    debugPrint(
      '[PRESENCE] Enviando ping para $currentDriverId (socket conectado: ${SocketService.isConnected})',
    );
    SocketService.sendLocationPing(
      idCisternero: currentDriverId!,
      latitud: position.latitude,
      longitud: position.longitude,
    );
  }

  // Sin esto, un cisternero solo se enteraba de un pedido nuevo cerrando y volviendo a
  // abrir la app (lo único que dispara fetchUserOrders). offNewDriverRequest() primero
  // evita apilar listeners duplicados si esto se llama más de una vez en la misma sesión.
  void _listenForNewDriverRequests() {
    SocketService.connect();
    SocketService.offNewDriverRequest();
    SocketService.onNewDriverRequest((data) {
      debugPrint(
        '[DRIVER] Nuevo pedido recibido por socket: ${data['id_pedido']}',
      );
      fetchUserOrders();
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _presenceTimer?.cancel();
    _driverPollTimer?.cancel();
    super.dispose();
  }

  void setRole(AppRole role) {
    _currentRole = role;
    notifyListeners();
  }

  void selectLiters(int liters, double price) {
    selectedLiters = liters;
    selectedPrice = price;
    if (backendTarifas.isNotEmpty) {
      final matching = backendTarifas.firstWhere(
        (t) => (t['volumen_litros'] as num?)?.toInt() == liters,
        orElse: () => backendTarifas.first,
      );
      activeTarifaId = matching['id_tarifa'];
    }
    notifyListeners();
  }

  void setAddress(String address) {
    deliveryAddress = address;
    final found = userAddresses.firstWhere(
      (d) => d['direccion_exacta'] == address,
      orElse: () => {},
    );
    if (found.isNotEmpty && found['coordenadas'] != null) {
      final coordsStr = found['coordenadas'] as String;
      final parts = coordsStr.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          deliveryCoords = LatLng(lat, lng);
        }
      }
    }
    notifyListeners();
  }

  // Establecido al elegir un resultado del buscador de lugares (autocompletado)
  void setDeliveryLocation(String address, LatLng coords) {
    if (address.contains('(') || address.startsWith('Ubicación GPS')) {
      final fallback = GeocodingService.getCachedAddress(coords) ??
          '${coords.latitude.toStringAsFixed(5)}, ${coords.longitude.toStringAsFixed(5)}';
      deliveryAddress = fallback;
    } else {
      deliveryAddress = address;
    }
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

  Future<void> savePreferredPaymentMethod(
    String method, {
    String? bancoEmisor,
  }) async {
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
  Future<bool> addNewAddress(
    String label,
    String address,
    String coords,
  ) async {
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

  // Pedido recién entregado en vivo (vía socket), pendiente de que el cliente lo
  // califique. Se muestra automáticamente en ClientTrackingScreen apenas se completa
  // el viaje, en vez de obligar al cliente a ir a buscarlo al historial.
  WaterOrder? lastDeliveredOrderPendingRating;

  void clearLastDeliveredOrderPendingRating() {
    lastDeliveredOrderPendingRating = null;
    notifyListeners();
  }

  // CRD-005: Aplicar un cambio de estado recibido en vivo por el socket de tracking
  // (necesario porque cliente y conductor suelen estar en dispositivos distintos).
  // `cisternero` llega desde notificarCambioEstado (Asignado/Aceptado en adelante) y
  // es la única forma en que el cliente se entera de quién le asignaron/aceptó su pedido,
  // ya que esos dos pasos ocurren por REST, no por un evento de socket propio.
  void applyRemoteOrderStatus(
    String idPedido,
    String estadoBackend, {
    Map<String, dynamic>? cisternero,
  }) {
    if (activeOrder == null || activeOrder!.id != idPedido) return;
    activeOrder!.status = _mapEstado(estadoBackend);
    if (cisternero != null) {
      activeOrder!.driverId = cisternero['id_cisternero'] as String?;
      activeOrder!.driverName = cisternero['nombre'] as String?;
      activeOrder!.driverPhone = cisternero['telefono'] as String?;
      activeOrder!.driverPlate = cisternero['placa'] as String?;
    }
    if (activeOrder!.status == OrderStatus.delivered) {
      lastDeliveredOrderPendingRating = activeOrder;
      activeOrder = null;
    } else if (activeOrder!.status == OrderStatus.cancelled) {
      activeOrder = null;
    }
    notifyListeners();
  }

  void _resolveOrderAddress(WaterOrder order) {
    final coordsStr = order.coordinates;
    if (coordsStr == null || coordsStr.trim().isEmpty) return;

    final coords = RealMapWidget.parseCoords(coordsStr);
    if (coords == null) return;

    final cached = GeocodingService.getCachedAddress(coords);
    if (cached != null && cached.isNotEmpty && !cached.startsWith('Ubicación')) {
      order.address = cached;
    }

    GeocodingService.reverseGeocode(coords).then((resolved) {
      if (resolved != null && resolved.isNotEmpty) {
        order.address = resolved;
        notifyListeners();
      }
    });
  }

  // Fetch backend orders strictly from database
  Future<void> fetchUserOrders() async {
    if (!isBackendConnected || currentUserId == null) return;

    final ordersData = await ApiService.getUserOrders(currentUserId!);
    clientHistory.clear();
    driverHistory.clear();
    pendingDriverRequests.clear();
    activeOrder = null;

    double calcEarned = 0.0;
    int calcCompleted = 0;

    if (ordersData.isNotEmpty) {
      for (var o in ordersData) {
        final orderStatusStr = o['estado_actual'] as String? ?? 'Pendiente';
        final status = _mapEstado(orderStatusStr);

        final driverObj = o['cisternero'];
        String? dId;
        String? dName;
        String? dPhone;
        String? dPlate;
        if (driverObj != null && driverObj['usuario'] != null) {
          dId = driverObj['id_cisternero'];
          dName = driverObj['usuario']['nombre'];
          dPhone = driverObj['usuario']['telefono'];
          if (driverObj['vehiculo'] != null) {
            dPlate = driverObj['vehiculo']['placa'];
          }
        }

        final destCoordsStr = o['coordenadas_destino'] as String? ?? '';
        String readableAddressStr = '';

        // Check if matching address is in saved addresses list
        final matchSaved = userAddresses.firstWhere(
          (d) => d['coordenadas'] == destCoordsStr,
          orElse: () => {},
        );
        if (matchSaved.isNotEmpty && matchSaved['direccion_exacta'] != null) {
          readableAddressStr = matchSaved['direccion_exacta'];
        } else if (o['cliente'] != null &&
            o['cliente']['direcciones'] != null &&
            (o['cliente']['direcciones'] as List).isNotEmpty) {
          final dirs = o['cliente']['direcciones'] as List;
          final foundDir = dirs.firstWhere(
            (d) => d['coordenadas'] == destCoordsStr,
            orElse: () => dirs.first,
          );
          if (foundDir['direccion_exacta'] != null) {
            readableAddressStr = foundDir['direccion_exacta'];
          }
        }

        if (readableAddressStr.isEmpty &&
            deliveryAddress.isNotEmpty &&
            !deliveryAddress.startsWith('Ubicación de entrega (')) {
          readableAddressStr = deliveryAddress;
        }

        final mappedOrder = WaterOrder(
          id: o['id_pedido'] ?? 'Pedido',
          dateTime:
              DateTime.tryParse(o['fecha_creacion'] ?? '') ?? DateTime.now(),
          liters: (o['tarifa'] != null && o['tarifa']['volumen_litros'] != null)
              ? (o['tarifa']['volumen_litros'] as num).toInt()
              : 2000,
          price: (o['monto_total'] as num?)?.toDouble() ?? selectedPrice,
          address: readableAddressStr.isNotEmpty
              ? readableAddressStr
              : 'Cargando ubicación...',
          coordinates: destCoordsStr,
          paymentMethod: 'Pago Movil',
          status: status,
          driverId: dId,
          driverName: dName,
          driverPhone: dPhone,
          driverPlate: dPlate,
        );

        _resolveOrderAddress(mappedOrder);

        if (status == OrderStatus.requested ||
            status == OrderStatus.accepted ||
            status == OrderStatus.inTransit) {
          if (activeOrder == null) {
            activeOrder = mappedOrder;
          }
          if (orderStatusStr == 'Pendiente' || orderStatusStr == 'Asignado') {
            pendingDriverRequests.add(mappedOrder);
          }
        }

        clientHistory.add(mappedOrder);

        if (status == OrderStatus.delivered &&
            (dId == currentDriverId || currentRole == AppRole.driver)) {
          driverHistory.add(mappedOrder);
          calcEarned += mappedOrder.price;
          calcCompleted += 1;
        }
      }
    }

    if (currentDriverId != null || currentRole == AppRole.driver) {
      totalDriverEarnings = calcEarned;
      walletBalanceUsd = (calcEarned - totalWithdrawn).clamp(0.0, double.infinity);
      tripsCompleted = calcCompleted;
    }

    notifyListeners();
  }

  Future<bool> cleanupStuckOrders() async {
    if (!isBackendConnected || currentUserId == null) return false;
    final ok = await ApiService.cancelAllActiveUserOrders(currentUserId!);
    if (ok) {
      activeOrder = null;
      pendingDriverRequests.clear();
      await fetchUserOrders();
      notifyListeners();
    }
    return ok;
  }

  // Mensaje del backend cuando createOrder() falla estando conectado (ej. calificación
  // pendiente), para que la UI pueda mostrar el motivo real en vez de uno genérico.
  String? lastOrderError;
  bool isCreatingOrder = false;

  // Create order from client. Devuelve false si el backend rechazó/falló la solicitud
  // estando conectado: en ese caso NO se simula un pedido local, porque un pedido con
  // un ID falso no existe en el backend y no se puede pagar ni cancelar después.
  Future<bool> createOrder() async {
    if (isCreatingOrder) return false;
    isCreatingOrder = true;
    lastOrderError = null;
    try {

    if (isBackendConnected) {
      final clientId = currentClientId;
      final tarifaId = activeTarifaId;

      if (clientId != null && tarifaId != null) {
        final coordsStr = deliveryCoords != null
            ? '${deliveryCoords!.latitude},${deliveryCoords!.longitude}'
            : (deliveryAddress.isNotEmpty ? deliveryAddress : '10.48,-66.90');

        final res = await ApiService.requestOrder(
          clientId: clientId,
          tarifaId: tarifaId,
          destinationCoords: coordsStr,
        );

        if (res != null &&
            res['data'] != null &&
            res['data']['id_pedido'] != null) {
          activeOrder = WaterOrder(
            id: res['data']['id_pedido'],
            dateTime: DateTime.now(),
            liters: selectedLiters,
            price: selectedPrice,
            address: deliveryAddress,
            coordinates: coordsStr,
            paymentMethod: paymentMethod,
            status: OrderStatus.requested,
          );
          clientHistory.insert(0, activeOrder!);
          pendingDriverRequests.clear();
          pendingDriverRequests.add(activeOrder!);
          notifyListeners();
          return true;
        }

        lastOrderError = ApiService.extractErrorMessage(res);
        notifyListeners();
        return false;
      }
    }

    // Sin backend conectado (o sin ids de cliente/tarifa todavía): simular el pedido
    // localmente, como el resto de AppState hace cuando no hay conexión al servidor.
    final orderId =
        'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
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
    notifyListeners();
    return true;
    } finally {
      isCreatingOrder = false;
      notifyListeners();
    }
  }

  // Mensaje del backend cuando cancelActiveOrder() falla (ej. el pedido ya fue
  // entregado y por lo tanto es inmutable), para mostrarle el motivo real al usuario.
  String? lastCancelError;

  // Cancel order. Devuelve false si el backend rechaza la cancelación estando conectado
  // (ej. el cisternero ya lo marcó "Entregado" justo antes): en ese caso NO se borra el
  // pedido localmente, para no mostrarle al usuario un "cancelado" que nunca ocurrió.
  Future<bool> cancelActiveOrder({
    String reason = 'Cancelado por usuario',
  }) async {
    lastCancelError = null;
    if (activeOrder == null) return true;
    final oldOrderId = activeOrder!.id;

    if (isBackendConnected) {
      final res = await ApiService.cancelOrder(
        oldOrderId,
        reason,
        _currentRole == AppRole.client ? 'cliente' : 'cisternero',
      );
      if (res == null) {
        lastCancelError =
            'No se pudo cancelar el pedido. Puede que ya haya sido entregado.';
        notifyListeners();
        return false;
      }
    }

    activeOrder!.status = OrderStatus.cancelled;
    pendingDriverRequests.clear();
    _stopLocationUpdates();
    activeOrder = null;
    notifyListeners();
    return true;
  }

  // Driver actions
  void toggleDriverAvailability() {
    isDriverAvailable = !isDriverAvailable;
    notifyListeners();
    if (isDriverAvailable) {
      _startPresenceUpdates();
    } else {
      _stopPresenceUpdates();
    }
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
        'title': 'Entrega de ${activeOrder!.liters} Litros',
        'time':
            'Hoy, ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
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
  Future<bool> processOrderPayment(
    String reference, {
    String? bancoEmisor,
    String? comprobanteUrl,
  }) async {
    if (activeOrder != null) {
      recentTransactions.insert(0, {
        'title': 'Pago Pedido (${activeOrder!.paymentMethod})',
        'time':
            'Hoy, ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
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

  // Support & Rating. driverId/clientId identifican al conductor y cliente del
  // PEDIDO que se está calificando, no a la sesión actual: un cliente calificando
  // no tiene currentDriverId (ese campo solo se llena en sesiones de cisternero) y
  // viceversa, así que no sirven como sustituto de los IDs reales del pedido.
  Future<bool> submitRating({
    required String driverId,
    required String clientId,
    required int puntaje,
    String? comentario,
  }) async {
    if (isBackendConnected) {
      final res = await ApiService.submitRating(
        driverId: driverId,
        clientId: clientId,
        puntaje: puntaje,
        comentario: comentario,
        rolEmisor: _currentRole == AppRole.client ? 'Cliente' : 'Cisternero',
      );
      return res != null;
    }
    return true;
  }

  Future<bool> submitDispute({
    required String tipo,
    required String descripcion,
  }) async {
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
        walletBalanceUsd =
            (wData['saldo_billetera'] as num?)?.toDouble() ?? walletBalanceUsd;
        clientWalletRecargas =
            (wData['recargas'] as List?)?.cast<Map<String, dynamic>>() ?? [];
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
        'time':
            'Hoy, ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
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
