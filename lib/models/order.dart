enum OrderStatus { requested, accepted, inTransit, delivered, cancelled }

class WaterOrder {
  final String id;
  final DateTime dateTime;
  final int liters;
  final double price;
  String address;
  final String? coordinates;
  final String paymentMethod;
  OrderStatus status;

  // Driver Details (only set if status is accepted/inTransit/delivered)
  String? driverId;
  String? driverName;
  String? driverPhone;
  String? driverPlate;

  WaterOrder({
    required this.id,
    required this.dateTime,
    required this.liters,
    required this.price,
    required this.address,
    this.coordinates,
    required this.paymentMethod,
    required this.status,
    this.driverId,
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
