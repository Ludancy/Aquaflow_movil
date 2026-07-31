import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({Key? key}) : super(key: key);

  void _showWithdrawDialog(BuildContext context, AppState appState) {
    final amountCtrl = TextEditingController(text: '50.0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Solicitar Retiro', style: TextStyle(color: AppTheme.textWhite)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saldo Disponible: \$${appState.walletBalanceUsd.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Monto a retirar (\$)',
                hintText: '50.00',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
              if (amount > 0) {
                final success = await appState.withdrawDriverWallet(amount);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '¡Retiro de \$$amount procesado!' : 'Saldo insuficiente para retiro'),
                    ),
                  );
                }
              }
            },
            child: const Text('Confirmar Retiro'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    final List<double> weeklyEarnings = List.generate(7, (i) => 0.0);
    final List<String> weekDays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final double maxEarn = 0.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Ganancias y Billetera', style: TextStyle(color: AppTheme.textWhite)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textWhite),
            onPressed: () => appState.refreshDriverWallet(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Total Earnings Display Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                children: [
                  const Text(
                    'Balance total en billetera',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${appState.walletBalanceUsd.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Mini stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMiniStat('Entregas', '${appState.tripsCompleted}'),
                      Container(width: 1, height: 24, color: AppTheme.borderDark),
                      _buildMiniStat('Calificación', '${appState.driverRating} ★'),
                      Container(width: 1, height: 24, color: AppTheme.borderDark),
                      _buildMiniStat('Comisión', '12%'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: () => _showWithdrawDialog(context, appState),
                    icon: const Icon(Icons.account_balance_wallet, size: 18),
                    label: const Text('Solicitar Retiro de Billetera'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Weekly Chart Section
            const Text(
              'Desempeño Semanal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        final val = weeklyEarnings[index];
                        final ratio = maxEarn > 0 ? (val / maxEarn) : 0.0;
                        final height = ratio * 110;
                        
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              val > 0 ? '\$${val.toInt()}' : '',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 18,
                              height: height.toDouble(),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryBlue,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              weekDays[index],
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Driver trip history list
            const Text(
              'Historial de Viajes y Retiros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 12),
            appState.driverHistory.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: const Center(
                      child: Text(
                        'Aún no has completado ningún viaje hoy.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: appState.driverHistory.length,
                    itemBuilder: (context, index) {
                      final order = appState.driverHistory[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: AppTheme.success, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Entrega de ${order.liters} L',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Cliente: ${appState.userName}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '+\$${order.price.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.success),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: AppTheme.textWhite, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
