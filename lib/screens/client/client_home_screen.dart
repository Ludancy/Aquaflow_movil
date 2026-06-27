import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/mock_map.dart';
import 'client_confirm_screen.dart';
import 'client_history_screen.dart';
import 'client_profile_screen.dart';
import 'client_tracking_screen.dart';
import 'client_wallet_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _selectedIndex = 0;

  // Options matching user screenshot
  final List<Map<String, dynamic>> _tankOptions = [
    {'liters': 1000, 'basePrice': 20.0, 'shippingPrice': 5.0, 'label': '1000L', 'isPopular': false},
    {'liters': 2000, 'basePrice': 40.0, 'shippingPrice': 5.0, 'label': '2000L', 'isPopular': true},
    {'liters': 5000, 'basePrice': 80.0, 'shippingPrice': 5.0, 'label': '5000L', 'isPopular': false},
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Determine tab content
    Widget body;
    if (_selectedIndex == 0) {
      body = _buildHomeTab(context, appState);
    } else if (_selectedIndex == 1) {
      body = const ClientHistoryScreen();
    } else if (_selectedIndex == 2) {
      body = const ClientWalletScreen();
    } else {
      body = const ClientProfileScreen();
    }

    return Theme(
      data: AppTheme.clientTheme,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.borderDark, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.backgroundDark,
            selectedItemColor: AppTheme.primaryBlue,
            unselectedItemColor: AppTheme.textMuted,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet),
                label: 'Wallet',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
        body: body,
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, AppState appState) {
    // Current selected option values
    final selectedOption = _tankOptions.firstWhere((opt) => opt['liters'] == appState.selectedLiters);
    final double basePrice = selectedOption['basePrice'];
    final double shippingPrice = selectedOption['shippingPrice'];

    return Stack(
      children: [
        // Simulated map covers full background
        const Positioned.fill(
          child: MockMapWidget(showRoute: false),
        ),

        // Custom Top Overlay HUD (Address banner)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.backgroundDark, AppTheme.backgroundDark.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row with address dropdown & Notification Icon
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.primaryBlue, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DIRECCIÓN DE ENTREGA',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  appState.deliveryAddress,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textWhite,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down, color: AppTheme.textWhite, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Notification Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.cardDark,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none, color: AppTheme.textWhite, size: 20),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Search Input Field
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: const TextField(
                    style: TextStyle(color: AppTheme.textWhite, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar nueva dirección...',
                      hintStyle: TextStyle(color: AppTheme.textMuted),
                      prefixIcon: Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Row of Chips: Reordenar / Favoritos
                Row(
                  children: [
                    _buildTopChip(
                      icon: Icons.history,
                      label: 'Reordenar: Casa',
                      onTap: () {},
                    ),
                    const SizedBox(width: 10),
                    _buildTopChip(
                      icon: Icons.star_border,
                      label: 'Favoritos',
                      onTap: () {},
                    ),
                    
                    const Spacer(),
                    
                    // Simulator toggle button
                    ElevatedButton.icon(
                      onPressed: () {
                        appState.setRole(AppRole.driver);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Modo Conductor Activado')),
                        );
                        Navigator.pushNamedAndRemoveUntil(context, '/driver_home', (route) => false);
                      },
                      icon: const Icon(Icons.swap_horiz, size: 14),
                      label: const Text('Conductor', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.borderDark,
                        foregroundColor: AppTheme.textWhite,
                        minimumSize: const Size(90, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Active Order Alert Overlay
        if (appState.activeOrder != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 160,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ClientTrackingScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Pedido Activo en Curso',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Estado: ${appState.activeOrder!.statusText}',
                              style: const TextStyle(color: Color(0xFFE1F5FE), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Bottom Sheet Order Panel Overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: AppTheme.borderDark),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handlebar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Panel Title & Pulsing ETA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Servicio de Cisterna',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00FF66), // Pulsing green dot
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'LLEGA EN ~45 MIN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00FF66),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Tank Capacity Picker Title
                const Text(
                  'Capacidad del Tanque',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Liters Volume selection cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _tankOptions.map((opt) {
                    final isSelected = appState.selectedLiters == opt['liters'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          appState.selectLiters(opt['liters'], opt['basePrice'] + opt['shippingPrice']);
                        },
                        child: Container(
                          height: 84,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryBlue : const Color(0xFF111E2E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : AppTheme.borderDark,
                              width: 1.0,
                            ),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.water_drop_outlined,
                                      color: isSelected ? const Color(0xFF09121F) : AppTheme.textMuted,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      opt['label'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? const Color(0xFF09121F) : AppTheme.textWhite,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Popular Badge
                              if (opt['isPopular'])
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? const Color(0xFF0D1C2E).withOpacity(0.18) 
                                          : AppTheme.primaryBlue,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'POPULAR',
                                      style: TextStyle(
                                        fontSize: 7,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? const Color(0xFF09121F) : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                // Pricing Breakdown Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1724),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Column(
                    children: [
                      _buildCostRow('Costo base (${selectedOption['label']}):', '\$${basePrice.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      _buildCostRow('Tarifa de envío:', '\$${shippingPrice.toStringAsFixed(2)}'),
                      const Divider(height: 24, color: AppTheme.borderDark),
                      _buildCostRow(
                        'Total Estimado',
                        '\$${(basePrice + shippingPrice).toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Confirmation Button
                ElevatedButton(
                  onPressed: appState.activeOrder != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ClientTrackingScreen()),
                          );
                        }
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ClientConfirmScreen()),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3498DB), // Sky blue background
                    foregroundColor: const Color(0xFF09121F), // Dark navy text
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_shipping, size: 20, color: Color(0xFF09121F)),
                      const SizedBox(width: 10),
                      Text(
                        appState.activeOrder != null 
                            ? 'Ver Pedido en Curso' 
                            : 'Confirmar Pedido Premium',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF09121F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardDark.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.textWhite),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? AppTheme.textWhite : AppTheme.textMuted,
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? AppTheme.primaryBlue : AppTheme.textWhite,
            fontSize: isTotal ? 16 : 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
