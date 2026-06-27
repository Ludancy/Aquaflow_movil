import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import 'client_tracking_screen.dart';

class ClientHistoryScreen extends StatelessWidget {
  const ClientHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final history = appState.clientHistory;

    // Calculate total delivered water from completed history
    int totalDelivered = 12000; // Mock base + custom calculations
    int activeOrdersCount = appState.activeOrder != null ? 1 : 0;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const Icon(Icons.arrow_back, color: AppTheme.textWhite),
        title: const Text(
          'Historial',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textWhite),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppTheme.textWhite),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Summary Row (Total Entregado / Pedidos Activos)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Total Entregado',
                    value: '${(totalDelivered / 1000).toInt()}k L',
                    valueColor: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Pedidos Activos',
                    value: '$activeOrdersCount',
                    valueColor: const Color(0xFF00FF66), // Greenish cyan
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // List of past/active orders
          Expanded(
            child: history.isEmpty
                ? const Center(
                    child: Text(
                      'No tienes pedidos registrados.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final order = history[index];
                      return _buildOrderCard(context, order);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, WaterOrder order) {
    // Determine status badge properties
    Color badgeColor;
    Color badgeBg;
    String statusLabel;
    
    if (order.status == OrderStatus.delivered) {
      badgeColor = const Color(0xFF00FF88);
      badgeBg = const Color(0xFF00FF88).withOpacity(0.08);
      statusLabel = 'Completado';
    } else if (order.status == OrderStatus.cancelled) {
      badgeColor = const Color(0xFFFF5252);
      badgeBg = const Color(0xFFFF5252).withOpacity(0.08);
      statusLabel = 'Cancelado';
    } else {
      badgeColor = AppTheme.primaryBlue;
      badgeBg = AppTheme.primaryBlue.withOpacity(0.08);
      statusLabel = 'En curso';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title and status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.id,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textWhite,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withOpacity(0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          
          // Time subtitle
          Text(
            'Hoy, 10:30 AM', // Mock or actual formatted time
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const Divider(height: 24, color: AppTheme.borderDark),
          
          // Driver details & Price row
          Row(
            children: [
              // Driver Avatar circular card
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1724),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Center(
                  child: Icon(
                    order.driverName == 'Conductor no asignado' 
                        ? Icons.local_shipping_outlined 
                        : Icons.person_outline,
                    color: AppTheme.textMuted,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              
              // Name and vehicle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.driverName ?? 'Conductor no asignado',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: order.driverName == 'Conductor no asignado' 
                            ? AppTheme.textMuted 
                            : AppTheme.textWhite,
                      ),
                    ),
                    if (order.driverPlate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        order.driverPlate!,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Price and action
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${order.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () {
                      if (order.status == OrderStatus.inTransit) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ClientTrackingScreen()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Abriendo detalles de pedido...')),
                        );
                      }
                    },
                    child: const Text(
                      'Ver Detalles',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
