import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/api_service.dart';

enum AppRole {
  client,
  driver
}

class AppState extends ChangeNotifier {
  // Backend Integration State
  bool isBackendConnected = false;
  String? activeTarifaId;
  List<dynamic> backendTarifas = [];

  // Active Logged User Identity
  String? currentUserId;
  String? currentClientId;
  String? currentDriverId;

  // Active User Info (Empty by default, populated strictly from DB/Registration)
  String userName = '';
  String userEmail = '';
  String userPhone = '';
  String deliveryAddress = '';
  List<Map<String, dynamic>> userAddresses = [];

  // Driver details (Empty by default)
  String driverName = '';
  String driverUnit = '';
  String driverPhone = '';
  String driverPlate = '';
  String driverEmail = '';
  String driverTruck = '';

  AppState() {
    initBackendConnection();
  }

  Future<void> initBackendConnection() async {
    isBackendConnected = await ApiService.checkHealth();
    if (isBackendConnected) {
      final tarifas = await ApiService.getTarifas();
      backendTarifas = tarifas;
      if (tarifas.isNotEmpty) {
        activeTarifaId = tarifas.first['id_tarifa'];
      }
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
    }

    notifyListeners();
  }

  // Global Role
  AppRole _currentRole = AppRole.client;
  AppRole get currentRole => _currentRole;

  // Client Selection State
  int selectedLiters = 2000;
  double selectedPrice = 20.00;
  String paymentMethod = 'Pago Móvil';

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

  void setPaymentMethod(String method) {
    paymentMethod = method;
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
        OrderStatus status = OrderStatus.requested;
        if (orderStatusStr == 'Asignado' || orderStatusStr == 'Aceptado') {
          status = OrderStatus.accepted;
        } else if (orderStatusStr == 'En Ruta') {
          status = OrderStatus.inTransit;
        } else if (orderStatusStr == 'Entregado') {
          status = OrderStatus.delivered;
        } else if (orderStatusStr == 'Cancelado') {
          status = OrderStatus.cancelled;
        }

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
          paymentMethod: 'Pago Móvil',
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
  void createOrder() async {
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
          destinationCoords: deliveryAddress.isNotEmpty ? deliveryAddress : '10.48,-66.90',
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
        if (currentDriverId != null) {
          ApiService.updateLocation(
            driverId: currentDriverId!,
            orderId: activeOrder!.id,
            latitud: 10.48,
            longitud: -66.90,
          );
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
        refreshDriverWallet();
      }
      
      activeOrder = null;
    }
    notifyListeners();
  }

  // Payment process
  Future<bool> processOrderPayment(String reference) async {
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

  void rechargeWallet(double amount, String method) {
    walletBalanceUsd += amount;
    recentTransactions.insert(0, {
      'title': 'Recarga $method',
      'time': 'Hoy, ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      'amount': amount,
      'type': 'deposit',
    });
    notifyListeners();
  }
}
