import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme.dart';

class ClientWalletScreen extends StatelessWidget {
  const ClientWalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const Icon(Icons.location_on_outlined, color: AppTheme.textWhite),
        title: const Text(
          'AquaFlow',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textWhite),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppTheme.textWhite),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance Card
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
                    'Saldo Disponible',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '\$${appState.walletBalanceUsd.toStringAsFixed(2)} USD',
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '≈ Bs. ${(appState.walletBalanceUsd * appState.exchangeRate).toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Reload & Withdraw buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildWalletActionButton(
                          icon: Icons.add_circle_outline,
                          label: 'Recargar',
                          backgroundColor: AppTheme.primaryBlue,
                          textColor: Colors.white,
                          onTap: () => _showRechargeDialog(context, appState),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildWalletActionButton(
                          icon: Icons.arrow_upward,
                          label: 'Retirar',
                          backgroundColor: const Color(0xFF0D1724),
                          textColor: AppTheme.textWhite,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Saved payment methods header
            Row(
              children: [
                const Icon(Icons.credit_card, size: 20, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  'Métodos de Pago Guardados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Saved payment methods list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appState.savedPaymentMethods.length,
              itemBuilder: (context, index) {
                final method = appState.savedPaymentMethods[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1724),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            method['type'][0], // Show Z or P
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method['type'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textWhite,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              method['detail'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (method['checked'])
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.success,
                          size: 20,
                        ),
                    ],
                  ),
                );
              },
            ),
            
            // Add payment method dashed card
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.borderDark,
                    width: 1.5,
                    style: BorderStyle.solid, // solid fallback
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: AppTheme.textMuted, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Añadir Método',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Recent activity header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, size: 20, color: AppTheme.primaryBlue),
                    SizedBox(width: 8),
                    Text(
                      'Actividad Reciente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Ver Todo',
                    style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Recent activity list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appState.recentTransactions.length,
              itemBuilder: (context, index) {
                final tx = appState.recentTransactions[index];
                final isNegative = tx['amount'] < 0;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                          color: const Color(0xFF0D1724),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          tx['type'] == 'order' ? Icons.water_drop_outlined : Icons.account_balance_wallet_outlined,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textWhite,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tx['time'],
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isNegative ? '-' : '+'}\$${tx['amount'].abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isNegative ? AppTheme.textWhite : AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletActionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRechargeDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: const Text('Recargar Saldo (USD)'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textWhite),
            decoration: const InputDecoration(
              hintText: 'Ingresa el monto a recargar',
              hintStyle: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final amt = double.tryParse(controller.text);
                if (amt != null && amt > 0) {
                  appState.rechargeWallet(amt, 'Zelle');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Recargado \$${amt.toStringAsFixed(2)} exitosamente.')),
                  );
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }
}
