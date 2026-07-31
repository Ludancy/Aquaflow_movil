import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().fetchNotifications();
    });
  }

  IconData _iconFor(String? tipo) {
    switch (tipo) {
      case 'alerta':
        return Icons.warning_amber_rounded;
      case 'sistema':
        return Icons.info_outline;
      case 'estado_pedido':
      default:
        return Icons.local_shipping_outlined;
    }
  }

  String _formatFecha(String? iso) {
    final date = DateTime.tryParse(iso ?? '');
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final notifications = appState.notifications;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Notificaciones', style: TextStyle(color: AppTheme.textWhite)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (appState.unreadNotificationsCount > 0)
            TextButton(
              onPressed: () => appState.markAllNotificationsRead(),
              child: const Text('Marcar todas', style: TextStyle(color: AppTheme.primaryBlue)),
            ),
        ],
      ),
      body: SafeArea(
        child: notifications.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No tienes notificaciones todavía.',
                    style: TextStyle(color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => appState.fetchNotifications(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    final leida = n['leida'] == true;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        final id = n['id_notificacion'] as String?;
                        if (id != null) appState.markNotificationRead(id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: leida ? AppTheme.borderDark : AppTheme.primaryBlue,
                            width: leida ? 1 : 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_iconFor(n['tipo'] as String?), color: AppTheme.primaryBlue, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n['titulo'] as String? ?? 'Notificación',
                                    style: TextStyle(
                                      color: AppTheme.textWhite,
                                      fontWeight: leida ? FontWeight.normal : FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n['mensaje'] as String? ?? '',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatFecha(n['fecha_creacion'] as String?),
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (!leida)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
