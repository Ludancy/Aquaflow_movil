import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/bancos_venezuela.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import 'client_tracking_screen.dart';

class ClientConfirmScreen extends StatefulWidget {
  const ClientConfirmScreen({Key? key}) : super(key: key);

  @override
  State<ClientConfirmScreen> createState() => _ClientConfirmScreenState();
}

class _ClientConfirmScreenState extends State<ClientConfirmScreen> {
  final _refController = TextEditingController();
  String? _bancoEmisor;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _bancoEmisor = context.read<AppState>().preferredBancoEmisor;
  }

  @override
  void dispose() {
    _refController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Theme(
      data: AppTheme.clientTheme,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: const Text(
            'Confirmar Pedido',
            style: TextStyle(color: AppTheme.textWhite),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textWhite),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  // Order Summary Card
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              color: AppTheme.primaryBlue,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Resumen de Pedido',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textWhite,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32, color: AppTheme.borderDark),

                        // Volume row
                        _buildSummaryRow(
                          'Volumen de agua:',
                          '${appState.selectedLiters.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} Litros',
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 12),

                        // Address row
                        _buildSummaryRow(
                          'Dirección de entrega:',
                          appState.deliveryAddress,
                          isMultiLine: true,
                        ),
                        const SizedBox(height: 12),

                        // Price row
                        _buildSummaryRow(
                          'Precio estimado:',
                          '\$${appState.selectedPrice.toStringAsFixed(2)}',
                          valueColor: AppTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Method Header
                  const Text(
                    'Método de Pago',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Zelle option
                  _PaymentMethodCard(
                    title: 'Zelle',
                    subtitle:
                        appState.paymentInfo?['zelle']?['email'] ??
                        'Datos no disponibles',
                    icon: Icons.account_balance_wallet_outlined,
                    isSelected: appState.paymentMethod == 'Zelle',
                    onTap: () => appState.setPaymentMethod('Zelle'),
                  ),
                  const SizedBox(height: 12),

                  // Pago Móvil option
                  _PaymentMethodCard(
                    title:
                        'Pago Móvil${appState.paymentInfo?['pago_movil']?['banco'] != null ? ' - ${appState.paymentInfo!['pago_movil']['banco']}' : ''}',
                    subtitle:
                        appState.paymentInfo?['pago_movil']?['telefono'] != null
                        ? '${appState.paymentInfo!['pago_movil']['telefono']} · RIF ${appState.paymentInfo!['pago_movil']['rif']}'
                        : 'Paga con datos telefónicos',
                    icon: Icons.phone_android_outlined,
                    isSelected: appState.paymentMethod == 'Pago Movil',
                    onTap: () => appState.setPaymentMethod('Pago Movil'),
                  ),
                  const SizedBox(height: 12),

                  // Binance Pay option
                  _PaymentMethodCard(
                    title: 'Binance Pay',
                    subtitle:
                        appState.paymentInfo?['binance_pay']?['id'] != null
                        ? 'Pay ID: ${appState.paymentInfo!['binance_pay']['id']}'
                        : 'Paga con USDT/cripto',
                    icon: Icons.currency_bitcoin,
                    isSelected: appState.paymentMethod == 'Binance Pay',
                    onTap: () => appState.setPaymentMethod('Binance Pay'),
                  ),
                  const SizedBox(height: 12),

                  // Saldo AquaFlow option
                  _PaymentMethodCard(
                    title: 'Saldo AquaFlow',
                    subtitle:
                        'Disponible: \$${appState.walletBalanceUsd.toStringAsFixed(2)}'
                        '${appState.walletBalanceUsd < appState.selectedPrice ? ' · insuficiente para este pedido' : ''}',
                    icon: Icons.account_balance_wallet,
                    isSelected: appState.paymentMethod == 'Saldo AquaFlow',
                    onTap: appState.walletBalanceUsd >= appState.selectedPrice
                        ? () => appState.setPaymentMethod('Saldo AquaFlow')
                        : null,
                  ),

                  if (appState.paymentMethod != 'Saldo AquaFlow') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _refController,
                      keyboardType: appState.paymentMethod == 'Pago Movil'
                          ? TextInputType.number
                          : TextInputType.text,
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        labelText: appState.paymentMethod == 'Pago Movil'
                            ? 'Últimos 4 dígitos de la referencia'
                            : appState.paymentMethod == 'Binance Pay'
                            ? 'ID de transacción (TxID)'
                            : 'Número de Referencia de Pago',
                        hintText: appState.paymentMethod == 'Pago Movil'
                            ? 'Ej. 1234'
                            : 'Ej. REF-123456',
                        prefixIcon: const Icon(Icons.numbers, size: 18),
                      ),
                    ),
                  ],

                  if (appState.paymentMethod == 'Pago Movil') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _bancoEmisor,
                      dropdownColor: AppTheme.cardDark,
                      style: const TextStyle(
                        color: AppTheme.textWhite,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Banco emisor',
                        prefixIcon: Icon(
                          Icons.account_balance_outlined,
                          size: 18,
                        ),
                      ),
                      items: bancosVenezuela
                          .map(
                            (banco) => DropdownMenuItem(
                              value: banco,
                              child: Text(banco),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _bancoEmisor = value),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Confirm Payment Button
                  ElevatedButton(
                    onPressed: () async {
                      final referencia = _refController.text.trim();
                      final bancoEmisor = _bancoEmisor ?? '';

                      if (appState.paymentMethod == 'Pago Movil') {
                        if (!RegExp(r'^\d{4}$').hasMatch(referencia)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ingresa los últimos 4 dígitos de la referencia',
                              ),
                            ),
                          );
                          return;
                        }
                        if (bancoEmisor.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Selecciona el banco emisor'),
                            ),
                          );
                          return;
                        }
                      } else if (appState.paymentMethod != 'Saldo AquaFlow' &&
                          referencia.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ingresa el número de referencia de pago',
                            ),
                          ),
                        );
                        return;
                      }

                      if (_isSubmitting) return;
                      setState(() => _isSubmitting = true);

                      try {
                        if (appState.paymentMethod != 'Saldo AquaFlow') {
                          await appState.savePreferredPaymentMethod(
                            appState.paymentMethod,
                            bancoEmisor: appState.paymentMethod == 'Pago Movil'
                                ? bancoEmisor
                                : null,
                          );
                        }

                        final orderCreated = await appState.createOrder();
                        if (!orderCreated) {
                          if (context.mounted) {
                            final errMsg = appState.lastOrderError ??
                                'No se pudo crear el pedido. Intenta de nuevo.';
                            final isStuckActive = errMsg.toLowerCase().contains('activo') ||
                                errMsg.toLowerCase().contains('curso') ||
                                errMsg.toLowerCase().contains('calificar');

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errMsg),
                                backgroundColor: AppTheme.error,
                                duration: const Duration(seconds: 5),
                                action: isStuckActive
                                    ? SnackBarAction(
                                        label: 'Limpiar Pedidos',
                                        textColor: Colors.white,
                                        onPressed: () async {
                                          final ok = await appState.cleanupStuckOrders();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  ok
                                                      ? 'Pedidos estancados limpiados exitosamente.'
                                                      : 'No se pudieron limpiar los pedidos.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      )
                                    : null,
                              ),
                            );
                          }
                          return;
                        }
                        final ok = await appState.processOrderPayment(
                          appState.paymentMethod == 'Saldo AquaFlow'
                              ? 'Saldo AquaFlow'
                              : referencia,
                          bancoEmisor: appState.paymentMethod == 'Pago Movil'
                              ? bancoEmisor
                              : null,
                        );
                        if (appState.paymentMethod == 'Saldo AquaFlow') {
                          await appState.refreshClientWallet();
                        }
                        if (context.mounted) {
                          if (ok) {
                            _showSuccessDialog(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No se pudo registrar el pago. Intenta de nuevo.',
                                ),
                              ),
                            );
                          }
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isSubmitting = false);
                        }
                      }
                    },
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirmar y Solicitar'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color valueColor = AppTheme.textWhite,
    FontWeight fontWeight = FontWeight.normal,
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiLine
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontWeight: fontWeight,
              fontSize: 14,
            ),
            maxLines: isMultiLine ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.success,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Solicitud Creada Exitosamente!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Hemos enviado tu solicitud a los conductores cercanos y registrado tu pago.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClientTrackingScreen(),
                    ),
                  );
                },
                child: const Text('Rastrear Cisterna'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PaymentMethodCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: disabled ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1724),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.borderDark,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : AppTheme.borderDark,
                      width: isSelected ? 6.0 : 2.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
