import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/mock_map.dart';
import 'driver_home_screen.dart';

class DriverActiveOrderScreen extends StatelessWidget {
  const DriverActiveOrderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final activeOrder = appState.activeOrder;

    // If order was completed and cleared, redirect to completed summary screen
    if (activeOrder == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_outlined,
                      color: AppTheme.success,
                      size: 64,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '¡Entrega Completada!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Buen trabajo. Los fondos han sido agregados a tu cuenta y el cliente ha sido notificado.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Volver a Inicio'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isAccepted = activeOrder.status == OrderStatus.accepted;
    final isInTransit = activeOrder.status == OrderStatus.inTransit;
    final progress = appState.simulationProgress;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(isAccepted ? 'Pedido Aceptado' : 'Ruta de Entrega', style: const TextStyle(color: AppTheme.textWhite)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Map covering background
          const Positioned.fill(
            child: MockMapWidget(showRoute: true),
          ),

          // Navigation directions floating banner (GPS look)
          if (isInTransit)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.turn_right, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'En 200m gira a la derecha',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'Ruta optimizada hacia la dirección del cliente',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom details and action buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: AppTheme.borderDark),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Client detail row
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D1724),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: AppTheme.primaryBlue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appState.userName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textWhite),
                            ),
                            Text(
                              'Pedido: ${activeOrder.liters} L • \$${activeOrder.price.toInt()}',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      
                      // Contact client
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Llamando a ${appState.userName}...')),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppTheme.borderDark),

                  // Destination Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dirección de Entrega',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              activeOrder.address,
                              style: const TextStyle(color: AppTheme.textWhite, fontSize: 13, fontWeight: FontWeight.w500),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),

                  // Status display / Action button
                  if (isAccepted) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'El cliente está esperando. Inicia el viaje cuando estés listo.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        appState.driverStartTransit();
                      },
                      child: const Text('Iniciar Viaje (Simular)'),
                    ),
                  ] else if (isInTransit) ...[
                    // Progress bar showing simulation status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              progress < 1.0 ? 'Simulando tránsito en mapa...' : 'Cisterna en destino',
                              style: TextStyle(
                                fontSize: 12, 
                                color: progress < 1.0 ? AppTheme.primaryBlue : AppTheme.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: const Color(0xFF0D1724),
                          color: progress < 1.0 ? AppTheme.primaryBlue : AppTheme.success,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 16),
                        
                        // Complete button
                        ElevatedButton(
                          onPressed: progress >= 1.0
                              ? () {
                                  appState.driverCompleteOrder();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: progress >= 1.0 ? AppTheme.success : Colors.grey.shade800,
                            foregroundColor: progress >= 1.0 ? Colors.white : Colors.grey.shade500,
                          ),
                          child: const Text('Completar Entrega'),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),
                  
                  // Cancel Trip Button
                  OutlinedButton(
                    onPressed: () {
                      appState.cancelActiveOrder();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Viaje cancelado por el conductor.')),
                      );
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                    ),
                    child: const Text('Cancelar Viaje', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
