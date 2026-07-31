import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/bancos_venezuela.dart';
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
                    'Saldo AquaFlow',
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
                  const SizedBox(height: 8),
                  const Text(
                    'Recarga tu saldo y úsalo para pagar pedidos al instante, sin reingresar datos de pago cada vez.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: _buildWalletActionButton(
                      icon: Icons.add_circle_outline,
                      label: 'Recargar Saldo',
                      backgroundColor: AppTheme.primaryBlue,
                      textColor: Colors.white,
                      onTap: () => _showRechargeDialog(context, appState),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Recharge history header
            const Row(
              children: [
                Icon(Icons.history, size: 20, color: AppTheme.primaryBlue),
                SizedBox(width: 8),
                Text(
                  'Historial de Recargas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (appState.clientWalletRecargas.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: const Text(
                  'Aún no has recargado saldo. Toca "Recargar Saldo" para empezar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: appState.clientWalletRecargas.length,
                itemBuilder: (context, index) {
                  final recarga = appState.clientWalletRecargas[index];
                  final estatus = recarga['estatus'] as String? ?? 'Pendiente';
                  final color = estatus == 'Verificado'
                      ? AppTheme.success
                      : (estatus == 'Rechazado' ? AppTheme.error : Colors.amber);

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
                          decoration: const BoxDecoration(
                            color: Color(0xFF0D1724),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add_card_outlined, color: color, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recarga · ${recarga['metodo']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                estatus,
                                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+\$${(recarga['monto'] as num).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textWhite,
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
    final montoCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    String metodo = 'Pago Movil';
    String? bancoEmisor;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('Recargar Saldo', style: TextStyle(color: AppTheme.textWhite)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'La recarga queda pendiente hasta que verifiquemos el pago (${metodo == 'Pago Movil' ? appState.paymentInfo?['pago_movil']?['telefono'] ?? '' : metodo == 'Zelle' ? appState.paymentInfo?['zelle']?['email'] ?? '' : appState.paymentInfo?['binance_pay']?['id'] ?? ''}).',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: metodo,
                    dropdownColor: AppTheme.cardDark,
                    style: const TextStyle(color: AppTheme.textWhite, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Método'),
                    items: const [
                      DropdownMenuItem(value: 'Pago Movil', child: Text('Pago Móvil')),
                      DropdownMenuItem(value: 'Zelle', child: Text('Zelle')),
                      DropdownMenuItem(value: 'Binance Pay', child: Text('Binance Pay')),
                    ],
                    onChanged: (value) => setDialogState(() => metodo = value!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: montoCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textWhite, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Monto a recargar (USD)', hintText: 'Ej. 20'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: refCtrl,
                    style: const TextStyle(color: AppTheme.textWhite, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: metodo == 'Pago Movil' ? 'Últimos 4 dígitos de la referencia' : 'Número de referencia',
                    ),
                  ),
                  if (metodo == 'Pago Movil') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: bancoEmisor,
                      dropdownColor: AppTheme.cardDark,
                      style: const TextStyle(color: AppTheme.textWhite, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Banco emisor'),
                      items: bancosVenezuela.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (value) => setDialogState(() => bancoEmisor = value),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final monto = double.tryParse(montoCtrl.text.trim());
                        if (monto == null || monto <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Ingresa un monto válido')),
                          );
                          return;
                        }
                        if (metodo == 'Pago Movil') {
                          if (!RegExp(r'^\d{4}$').hasMatch(refCtrl.text.trim())) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Ingresa los últimos 4 dígitos de la referencia')),
                            );
                            return;
                          }
                          if (bancoEmisor == null) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Selecciona el banco emisor')),
                            );
                            return;
                          }
                        }

                        setDialogState(() => isSubmitting = true);
                        final ok = await appState.requestClientWalletRecharge(
                          metodo: metodo,
                          monto: monto,
                          referencia: refCtrl.text.trim(),
                          bancoEmisor: metodo == 'Pago Movil' ? bancoEmisor : null,
                        );
                        setDialogState(() => isSubmitting = false);

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Solicitud de recarga enviada. Quedará acreditada al verificarse.'
                                    : 'No se pudo enviar la solicitud de recarga. Intenta de nuevo.',
                              ),
                            ),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Solicitar Recarga'),
              ),
            ],
          );
        },
      ),
    );
  }
}
