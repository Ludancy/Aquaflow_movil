import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../state/app_state.dart';
import '../../theme.dart';

class ClientHistoryScreen extends StatelessWidget {
  const ClientHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final history = appState.clientHistory;

    int totalDelivered = history.fold(0, (sum, o) => sum + (o.status == OrderStatus.delivered ? o.liters : 0));
    int activeOrdersCount = appState.activeOrder != null ? 1 : 0;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Historial de Pedidos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textWhite),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textWhite),
            onPressed: () => appState.fetchUserOrders(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Total Entregado',
                    value: '${(totalDelivered / 1000).toStringAsFixed(1)}k L',
                    valueColor: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Pedidos Activos',
                    value: '$activeOrdersCount',
                    valueColor: const Color(0xFF00FF66),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
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
                      return _buildOrderCard(context, order, appState);
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
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, WaterOrder order, AppState appState) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.id,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
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
          
          Text(
            '${order.dateTime.day}/${order.dateTime.month}/${order.dateTime.year} ${order.dateTime.hour}:${order.dateTime.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const Divider(height: 20, color: AppTheme.borderDark),
          
          Row(
            children: [
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
                    order.driverName == null 
                        ? Icons.local_shipping_outlined 
                        : Icons.person_outline,
                    color: AppTheme.textMuted,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.driverName ?? 'Conductor no asignado',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: order.driverName == null 
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
                  Row(
                    children: [
                      if (order.status == OrderStatus.delivered)
                        TextButton(
                          onPressed: () => _showRatingDialog(context, appState, order),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 20)),
                          child: const Text('Calificar', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      TextButton(
                        onPressed: () => _showDisputeDialog(context, appState, order),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 20)),
                        child: const Text('Reportar', style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, AppState appState, WaterOrder order) {
    int rating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Calificar Servicio', style: TextStyle(color: AppTheme.textWhite)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Cuántas estrellas le das a esta entrega?', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setSt) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setSt(() => rating = index + 1),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              style: const TextStyle(color: AppTheme.textWhite, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Comentario opcional...',
                hintStyle: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await appState.submitRating(
                puntaje: rating,
                comentario: commentCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('¡Gracias por tu calificación!')),
                );
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _showDisputeDialog(BuildContext context, AppState appState, WaterOrder order) {
    final descCtrl = TextEditingController();
    String tipo = 'servicio_incompleto';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Reportar Incidencia', style: TextStyle(color: AppTheme.textWhite)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: tipo,
              dropdownColor: AppTheme.surfaceDark,
              style: const TextStyle(color: AppTheme.textWhite),
              items: const [
                DropdownMenuItem(value: 'servicio_incompleto', child: Text('Servicio Incompleto')),
                DropdownMenuItem(value: 'retraso_excesivo', child: Text('Retraso Excesivo')),
                DropdownMenuItem(value: 'comprobante_invalido', child: Text('Comprobante Inválido')),
                DropdownMenuItem(value: 'otro', child: Text('Otro Motivo')),
              ],
              onChanged: (val) {
                if (val != null) tipo = val;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: AppTheme.textWhite, fontSize: 13),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe lo sucedido...',
                hintStyle: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await appState.submitDispute(
                tipo: tipo,
                descripcion: descCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incidencia reportada al equipo de soporte')),
                );
              }
            },
            child: const Text('Enviar Reporte'),
          ),
        ],
      ),
    );
  }
}
