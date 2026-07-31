import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../welcome_screen.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({Key? key}) : super(key: key);

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
                          appState.driverName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appState.driverEmail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appState.driverPhone,
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

            // Cistern details section
            _buildProfileSection(
              title: 'Detalles de la Cisterna',
              items: [
                _DriverInfoTile(
                  icon: Icons.local_shipping_outlined,
                  title: 'Modelo de camión',
                  value: appState.driverTruck.isNotEmpty ? appState.driverTruck : 'No registrado',
                ),
                _DriverInfoTile(
                  icon: Icons.badge_outlined,
                  title: 'Placa del vehículo',
                  value: appState.driverPlate.isNotEmpty ? appState.driverPlate : 'No registrada',
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Driver settings section
            _buildProfileSection(
              title: 'Opciones de Conductor',
              items: [
                _DriverInfoTile(
                  icon: Icons.settings_outlined,
                  title: 'Ajustes de la aplicación',
                  value: 'Configurar alertas',
                  isLink: true,
                  onTap: () {},
                ),
                _DriverInfoTile(
                  icon: Icons.contact_support_outlined,
                  title: 'Soporte técnico',
                  value: 'Contactar central',
                  isLink: true,
                  onTap: () {},
                ),
              ],
            ),
            
            const SizedBox(height: 36),
            
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

  Widget _buildProfileSection({required String title, required List<Widget> items}) {
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

class _DriverInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isLink;
  final VoidCallback? onTap;

  const _DriverInfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.isLink = false,
    this.onTap,
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
          fontSize: 13,
          color: AppTheme.textMuted,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.textWhite,
        ),
      ),
      trailing: isLink ? const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textMuted) : null,
      onTap: onTap,
    );
  }
}
