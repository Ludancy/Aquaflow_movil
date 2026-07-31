import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/bancos_venezuela.dart';
import '../../services/geocoding_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../auth/login_screen.dart';

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({Key? key}) : super(key: key);

  void _showAddressesDialog(BuildContext context, AppState appState) {
    final labelCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    List<PlaceSuggestion> suggestions = [];
    Timer? debounce;
    bool isSearching = false;
    PlaceSuggestion? selectedPlace;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('Direcciones Guardadas', style: TextStyle(color: AppTheme.textWhite)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: appState.userAddresses.length,
                      itemBuilder: (context, index) {
                        final addr = appState.userAddresses[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.location_on, color: AppTheme.primaryBlue),
                          title: Text(addr['etiqueta'] ?? 'Dirección', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(addr['direccion_exacta'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                          trailing: appState.deliveryAddress == addr['direccion_exacta']
                              ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                              : TextButton(
                                  onPressed: () {
                                    appState.setAddress(addr['direccion_exacta']);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Usar', style: TextStyle(fontSize: 11)),
                                ),
                        );
                      },
                    ),
                  ),
                  const Divider(color: AppTheme.borderDark),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Agregar Nueva Dirección', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: labelCtrl,
                    style: const TextStyle(color: AppTheme.textWhite, fontSize: 12),
                    decoration: const InputDecoration(hintText: 'Etiqueta (ej. Oficina, Casa)', hintStyle: TextStyle(color: AppTheme.textMuted)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: addrCtrl,
                    style: const TextStyle(color: AppTheme.textWhite, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Dirección exacta',
                      hintStyle: const TextStyle(color: AppTheme.textMuted),
                      suffixIcon: isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (query) {
                      selectedPlace = null;
                      debounce?.cancel();
                      if (query.trim().length < 3) {
                        setDialogState(() => suggestions = []);
                        return;
                      }
                      debounce = Timer(const Duration(milliseconds: 500), () async {
                        setDialogState(() => isSearching = true);
                        final results = await GeocodingService.searchPlaces(query);
                        setDialogState(() {
                          suggestions = results;
                          isSearching = false;
                        });
                      });
                    },
                  ),
                  if (suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      constraints: const BoxConstraints(maxHeight: 160),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: suggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderDark),
                        itemBuilder: (context, index) {
                          final place = suggestions[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined, color: AppTheme.primaryBlue, size: 18),
                            title: Text(
                              place.displayName,
                              style: const TextStyle(color: AppTheme.textWhite, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              addrCtrl.text = place.displayName;
                              selectedPlace = place;
                              setDialogState(() => suggestions = []);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
              ElevatedButton(
                onPressed: () async {
                  if (labelCtrl.text.isNotEmpty && addrCtrl.text.isNotEmpty) {
                    final coords = selectedPlace != null
                        ? '${selectedPlace!.location.latitude},${selectedPlace!.location.longitude}'
                        : '10.48,-66.90';
                    await appState.addNewAddress(
                      labelCtrl.text.trim(),
                      addrCtrl.text.trim(),
                      coords,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPaymentMethodsDialog(BuildContext context, AppState appState) {
    String selectedMethod = appState.paymentMethod;
    String? selectedBanco = appState.preferredBancoEmisor;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceDark,
            title: const Text('Métodos de Pago', style: TextStyle(color: AppTheme.textWhite)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Elige tu método preferido para que quede listo la próxima vez que pidas agua.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primaryBlue,
                    title: const Text('Zelle', style: TextStyle(color: AppTheme.textWhite, fontSize: 13)),
                    subtitle: Text(appState.paymentInfo?['zelle']?['email'] ?? '', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    value: 'Zelle',
                    groupValue: selectedMethod,
                    onChanged: (value) => setDialogState(() => selectedMethod = value!),
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primaryBlue,
                    title: const Text('Pago Móvil', style: TextStyle(color: AppTheme.textWhite, fontSize: 13)),
                    subtitle: Text(
                      appState.paymentInfo?['pago_movil']?['telefono'] != null
                          ? '${appState.paymentInfo!['pago_movil']['telefono']} · ${appState.paymentInfo!['pago_movil']['banco']}'
                          : '',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                    value: 'Pago Movil',
                    groupValue: selectedMethod,
                    onChanged: (value) => setDialogState(() => selectedMethod = value!),
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primaryBlue,
                    title: const Text('Binance Pay', style: TextStyle(color: AppTheme.textWhite, fontSize: 13)),
                    subtitle: Text(
                      appState.paymentInfo?['binance_pay']?['id'] != null
                          ? 'Pay ID: ${appState.paymentInfo!['binance_pay']['id']}'
                          : '',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                    value: 'Binance Pay',
                    groupValue: selectedMethod,
                    onChanged: (value) => setDialogState(() => selectedMethod = value!),
                  ),
                  if (selectedMethod == 'Pago Movil') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBanco,
                      dropdownColor: AppTheme.cardDark,
                      style: const TextStyle(color: AppTheme.textWhite, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Banco desde el que sueles pagar',
                        prefixIcon: Icon(Icons.account_balance_outlined, size: 18),
                      ),
                      items: bancosVenezuela
                          .map((banco) => DropdownMenuItem(value: banco, child: Text(banco)))
                          .toList(),
                      onChanged: (value) => setDialogState(() => selectedBanco = value),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  await appState.savePreferredPaymentMethod(
                    selectedMethod,
                    bancoEmisor: selectedMethod == 'Pago Movil' ? selectedBanco : null,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(color: AppTheme.textWhite)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Card Info
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppTheme.primaryBlue,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appState.userEmail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appState.userPhone,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Profile Actions List
            _buildProfileSection(
              title: 'Ajustes de cuenta',
              items: [
                _ProfileItem(
                  icon: Icons.location_on_outlined,
                  title: 'Direcciones guardadas (${appState.userAddresses.length})',
                  subtitle: 'Agrega o gestiona tus ubicaciones',
                  onTap: () => _showAddressesDialog(context, appState),
                ),
                _ProfileItem(
                  icon: Icons.credit_card_outlined,
                  title: 'Métodos de pago',
                  subtitle: appState.preferredBancoEmisor != null
                      ? '${appState.paymentMethod} · ${appState.preferredBancoEmisor}'
                      : 'Preferido: ${appState.paymentMethod}',
                  onTap: () => _showPaymentMethodsDialog(context, appState),
                ),
                _ProfileItem(
                  icon: Icons.notifications_none_outlined,
                  title: 'Notificaciones',
                  subtitle: 'Ajustes de alertas de cisterna',
                  onTap: () {},
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            _buildProfileSection(
              title: 'Soporte y legal',
              items: [
                _ProfileItem(
                  icon: Icons.help_outline_outlined,
                  title: 'Centro de ayuda',
                  subtitle: 'Preguntas frecuentes y soporte',
                  onTap: () {},
                ),
                _ProfileItem(
                  icon: Icons.shield_outlined,
                  title: 'Políticas de privacidad',
                  subtitle: 'Información sobre tus datos',
                  onTap: () {},
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Logout Button
            ElevatedButton(
              onPressed: () async {
                await context.read<AppState>().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen(initialIsDriver: false)),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error.withOpacity(0.08),
                foregroundColor: AppTheme.error,
              ),
              child: const Text('Cerrar Sesión'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection({required String title, required List<_ProfileItem> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderDark),
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFF0D1724),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.textWhite, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.textWhite,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.textMuted,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textMuted),
      onTap: onTap,
    );
  }
}
