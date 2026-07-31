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

  AppState() {
    initBackendConnection();
  }

  Future<void> initBackendConnection() async {
    isBackendConnected = await ApiService.checkHealth();
    if (isBackendConnected) {
      final tarifas = await ApiService.getTarifas();
      if (tarifas.isNotEmpty) {
        activeTarifaId = tarifas.first['id_tarifa'];
      }
    }
    notifyListeners();
  }

  // Global Role
  AppRole _currentRole = AppRole.client;
  AppRole get currentRole => _currentRole;

  // Active User Info
  String userName = 'Carlos Mendoza';
  String userEmail = 'carlos@ejemplo.com';
  String userPhone = '+58 414 1234567';
  String deliveryAddress = 'Av. Principal Las Mercedes, Edf. Orinoco';

  // Driver details for simulation
  String driverName = 'Carlos M.';
  String driverUnit = 'Unidad #42';
  String driverPhone = '+58 414 987 6543';
  String driverPlate = 'A42K890';
  String driverEmail = 'carlos.m@aquaflow.com';
  String driverTruck = 'Ford F-350 (Cisterna 10K L)';

  // Client Selection State
  int selectedLiters = 2000;
  double selectedPrice = 45.00; // Base $40 + $5 Envío
  String paymentMethod = 'Zelle'; // 'Zelle' or 'Pago Móvil'

  // Wallet Simulation
  double walletBalanceUsd = 124.50;
  double exchangeRate = 36.00; // 1 USD = 36 Bs.
  
  List<Map<String, dynamic>> savedPaymentMethods = [
    {'type': 'Zelle', 'detail': 'juan.perez@email.com', 'checked': true},
    {'type': 'Pago Móvil - Banesco', 'detail': '0414-***-1234', 'checked': true},
  ];

  List<Map<String, dynamic>> recentTransactions = [
    {'title': 'Pedido #8492', 'time': 'Hoy, 10:45 AM', 'amount': -25.00, 'type': 'order'},
    {'title': 'Recarga Zelle', 'time': 'Ayer, 03:20 PM', 'amount': 50.00, 'type': 'deposit'},
  ];

  // Orders State (Matching the User's Screenshot Details)
  WaterOrder? activeOrder;
  
  final List<WaterOrder> clientHistory = [
    WaterOrder(
      id: '5000L Cisterna',
      dateTime: DateTime.now(), // active
      liters: 5000,
      price: 45.00,
      address: 'Av. Principal Las Mercedes, Edf. Orinoco',
      paymentMethod: 'Zelle',
      status: OrderStatus.inTransit,
      driverName: 'Carlos M.',
      driverPhone: '+58 414 987 6543',
      driverPlate: 'Unidad #42',
    ),
    WaterOrder(
      id: '2000L Camioneta',
      dateTime: DateTime.now().subtract(const Duration(hours: 4)),
      liters: 2000,
      price: 22.50,
      address: 'Av. Principal Las Mercedes, Edf. Orinoco',
      paymentMethod: 'Pago Móvil',
      status: OrderStatus.delivered,
      driverName: 'Ana G.',
      driverPhone: '+58 424 555 1234',
      driverPlate: 'Unidad #18',
    ),
    WaterOrder(
      id: '10000L Cisterna Especial',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      liters: 10000,
      price: 85.00,
      address: 'Av. Principal Las Mercedes, Edf. Orinoco',
      paymentMethod: 'Zelle',
      status: OrderStatus.cancelled,
      driverName: 'Conductor no asignado',
    ),
  ];

  // Driver State
  bool isDriverAvailable = true;
  List<WaterOrder> pendingDriverRequests = [];
  final List<WaterOrder> driverHistory = [];
  double totalDriverEarnings = 450.0;
  int tripsCompleted = 12;
  double driverRating = 4.9;

  // Map Animation simulation
  double simulationProgress = 0.5; // Starts at 0.5 to show it in course in mock
  Timer? _simulationTimer;

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

  // Create order from client
  void createOrder() async {
    activeOrder = WaterOrder(
      id: '${selectedLiters}L Cisterna',
      dateTime: DateTime.now(),
      liters: selectedLiters,
      price: selectedPrice,
      address: deliveryAddress,
      paymentMethod: paymentMethod,
      status: OrderStatus.requested,
    );
    
    // Insert at the top of history
    clientHistory.insert(0, activeOrder!);
    
    // Add to driver's pending list to simulate incoming request
    pendingDriverRequests.clear();
    pendingDriverRequests.add(activeOrder!);

    if (isBackendConnected && activeTarifaId != null) {
      // Send request to live backend server
      ApiService.requestOrder(
        clientId: 'cliente-id-placeholder',
        tarifaId: activeTarifaId!,
        destinationCoords: '10.48,-66.90',
      );
    }
    
    notifyListeners();
  }

  // Cancel order (Client or Driver)
  void cancelActiveOrder() {
    if (activeOrder != null) {
      activeOrder!.status = OrderStatus.cancelled;
      pendingDriverRequests.clear();
      activeOrder = null;
      stopSimulation();
    }
    notifyListeners();
  }

  // Driver actions
  void toggleDriverAvailability() {
    isDriverAvailable = !isDriverAvailable;
    notifyListeners();
  }

  void driverAcceptOrder(WaterOrder order) {
    order.status = OrderStatus.accepted;
    order.driverName = driverName;
    order.driverPhone = driverPhone;
    order.driverPlate = driverUnit;
    
    pendingDriverRequests.remove(order);
    activeOrder = order;
    
    notifyListeners();
    
    // Auto transition to "inTransit" after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (activeOrder != null && activeOrder!.status == OrderStatus.accepted) {
        driverStartTransit();
      }
    });
  }

  void driverRejectOrder(WaterOrder order) {
    pendingDriverRequests.remove(order);
    notifyListeners();
  }

  void driverStartTransit() {
    if (activeOrder != null) {
      activeOrder!.status = OrderStatus.inTransit;
      notifyListeners();
      startSimulation();
    }
  }

  void driverCompleteOrder() {
    if (activeOrder != null) {
      activeOrder!.status = OrderStatus.delivered;
      driverHistory.insert(0, activeOrder!);
      
      // Deduct from wallet if card/Zelle was selected or simulate wallet change
      walletBalanceUsd -= activeOrder!.price;
      recentTransactions.insert(0, {
        'title': 'Pedido #${1000 + clientHistory.length}',
        'time': 'Hoy, ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'amount': -activeOrder!.price,
        'type': 'order',
      });
      
      totalDriverEarnings += activeOrder!.price;
      tripsCompleted += 1;
      
      activeOrder = null;
      stopSimulation();
    }
    notifyListeners();
  }

  // Wallet Methods
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

  // Map progress simulation
  void startSimulation() {
    simulationProgress = 0.0;
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (simulationProgress < 1.0) {
        simulationProgress += 0.01;
        if (simulationProgress > 1.0) simulationProgress = 1.0;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
    simulationProgress = 0.5;
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}
