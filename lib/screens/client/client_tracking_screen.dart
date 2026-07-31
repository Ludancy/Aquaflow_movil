import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/mock_map.dart';
import 'client_home_screen.dart';

class ClientTrackingScreen extends StatelessWidget {
  const ClientTrackingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final activeOrder = appState.activeOrder;
    
    // Fallback if somehow there's no active order
    if (activeOrder == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 64),
                const SizedBox(height: 16),
                const Text(
                  '¡Servicio Completado!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                ),
                const SizedBox(height: 8),
                const Text(
                  'El agua ha sido entregada. Tu historial de pedidos se ha actualizado.',
                  style: TextStyle(color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const ClientHomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Volver al Inicio'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isRequested = activeOrder.status == OrderStatus.requested;
    final isAccepted = activeOrder.status == OrderStatus.accepted;
    final isInTransit = activeOrder.status == OrderStatus.inTransit;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(activeOrder.statusText, style: const TextStyle(color: AppTheme.textWhite)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textWhite),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const ClientHomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // Map
          Positioned.fill(
            child: MockMapWidget(showRoute: !isRequested),
          ),

          // Top Status Banner / Instructions
          if (isRequested)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Simulador: Esperando Aceptación',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'Pulsa el botón de abajo para ir al portal del conductor y aceptar este pedido.',
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Panel Sheet
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
                  // Status Header
                  Row(
                    children: [
                      if (isRequested) ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Buscando cisterna cercana...',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                          ),
                        ),
                      ] else if (isAccepted) ...[
                        const Icon(Icons.check_circle, color: AppTheme.success, size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Cisterna asignada',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                          ),
                        ),
                        const Text(
                          'En preparación',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                        ),
                      ] else if (isInTransit) ...[
                        const Icon(Icons.local_shipping, color: AppTheme.primaryBlue, size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Cisterna en camino',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                          ),
                        ),
                        Text(
                          'ETA: ~15 min',
                          style: const TextStyle(fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                  const Divider(height: 28, color: AppTheme.borderDark),

                  // Driver info card
                  if (!isRequested && activeOrder.driverName != null) ...[
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: AppTheme.primaryBlue, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeOrder.driverName!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textWhite),
                              ),
                              Text(
                                'Cisterna: ${activeOrder.driverPlate} • ${activeOrder.liters} L',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        
                        // Action Buttons
                        _IconButton(
                          icon: Icons.phone_outlined, 
                          color: Colors.green,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Llamando a ${activeOrder.driverName}...')),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _IconButton(
                          icon: Icons.chat_bubble_outline, 
                          color: AppTheme.primaryBlue,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Abriendo chat con ${activeOrder.driverName}...')),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 12),
                  
                  // Cancel Button
                  OutlinedButton(
                    onPressed: () {
                      appState.cancelActiveOrder();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pedido cancelado.')),
                      );
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const ClientHomeScreen()),
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                    ),
                    child: const Text('Cancelar Pedido', style: TextStyle(fontWeight: FontWeight.bold)),
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

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.12),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }
}
