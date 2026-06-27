enum OrderStatus {
  requested,
  accepted,
  inTransit,
  delivered,
  cancelled
}

class WaterOrder {
  final String id;
  final DateTime dateTime;
  final int liters;
  final double price;
  final String address;
  final String paymentMethod;
  OrderStatus status;
  
  // Driver Details (only set if status is accepted/inTransit/delivered)
  String? driverName;
  String? driverPhone;
  String? driverPlate;

  WaterOrder({
    required this.id,
    required this.dateTime,
    required this.liters,
    required this.price,
    required this.address,
    required this.paymentMethod,
    required this.status,
    this.driverName,
    this.driverPhone,
    this.driverPlate,
  });

  String get statusText {
    switch (status) {
      case OrderStatus.requested:
        return 'Solicitado';
      case OrderStatus.accepted:
        return 'Aceptado';
      case OrderStatus.inTransit:
        return 'En camino';
      case OrderStatus.delivered:
        return 'Entregado';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }
}
