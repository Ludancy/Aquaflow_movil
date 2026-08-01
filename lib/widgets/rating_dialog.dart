import 'package:flutter/material.dart';
import '../models/order.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Diálogo para calificar el servicio de un pedido entregado. Compartido entre
/// ClientHistoryScreen (calificar desde el historial) y ClientTrackingScreen
/// (calificar apenas se completa el viaje en curso).
void showRatingDialog(
  BuildContext context,
  AppState appState,
  WaterOrder order, {
  VoidCallback? onDone,
}) {
  int rating = 5;
  final commentCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      title: const Text(
        'Calificar Servicio',
        style: TextStyle(color: AppTheme.textWhite),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '¿Cuántas estrellas le das a esta entrega?',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
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
          onPressed: () {
            Navigator.pop(ctx);
            onDone?.call();
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final driverId = order.driverId;
            final clientId = appState.currentClientId;
            if (driverId == null || clientId == null) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'No se pudo identificar al cisternero de este pedido.',
                  ),
                ),
              );
              onDone?.call();
              return;
            }
            final ok = await appState.submitRating(
              driverId: driverId,
              clientId: clientId,
              puntaje: rating,
              comentario: commentCtrl.text.trim(),
            );
            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? '¡Gracias por tu calificación!'
                        : 'No se pudo enviar la calificación. Intenta de nuevo.',
                  ),
                ),
              );
            }
            onDone?.call();
          },
          child: const Text('Enviar'),
        ),
      ],
    ),
  );
}
