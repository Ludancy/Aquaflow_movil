import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../welcome_screen.dart';

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({Key? key}) : super(key: key);

  void _showAddressesDialog(BuildContext context, AppState appState) {
    final labelCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                decoration: const InputDecoration(hintText: 'Dirección exacta', hintStyle: TextStyle(color: AppTheme.textMuted)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
          ElevatedButton(
            onPressed: () async {
              if (labelCtrl.text.isNotEmpty && addrCtrl.text.isNotEmpty) {
                await appState.addNewAddress(
                  labelCtrl.text.trim(),
                  addrCtrl.text.trim(),
                  '10.48,-66.90',
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
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
                  subtitle: 'Gestiona Zelle / Pago Móvil',
                  onTap: () {},
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
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
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
