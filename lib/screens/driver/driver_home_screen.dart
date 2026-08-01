import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../services/location_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/mock_map.dart';
import 'driver_active_order_screen.dart';
import 'driver_earnings_screen.dart';
import 'driver_profile_screen.dart';
import '../notifications_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.activeOrder != null && 
          (appState.activeOrder!.status == OrderStatus.accepted || 
           appState.activeOrder!.status == OrderStatus.inTransit)) {
        if (!DriverActiveOrderScreen.isOpen) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DriverActiveOrderScreen()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Determine target body
    Widget body;
    if (_selectedIndex == 0) {
      body = _buildHomeTab(context, appState);
    } else if (_selectedIndex == 1) {
      body = const DriverEarningsScreen();
    } else {
      body = const DriverProfileScreen();
    }

    return Theme(
      data: AppTheme.driverTheme,
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
                icon: Icon(Icons.navigation_outlined),
                activeIcon: Icon(Icons.navigation),
                label: 'Servicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payments_outlined),
                activeIcon: Icon(Icons.payments),
                label: 'Ganancias',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        ),
        body: body,
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context, AppState appState) {
    final hasRequests = appState.pendingDriverRequests.isNotEmpty;
    final incomingRequest = hasRequests ? appState.pendingDriverRequests.first : null;
    final requestCoords = incomingRequest != null
        ? RealMapWidget.parseCoords(incomingRequest.coordinates ?? incomingRequest.address)
        : null;

    return Stack(
      children: [
        // Map Widget filling the screen
        Positioned.fill(
          child: MockMapWidget(
            showRoute: hasRequests,
            isDriverView: true,
            driverLocation: appState.driverCurrentCoords,
            clientLocation: requestCoords,
          ),
        ),

        // Availability switcher HUD
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Availability status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: appState.isDriverAvailable ? AppTheme.success : AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      appState.isDriverAvailable ? 'Disponible' : 'No disponible',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textWhite),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: appState.isDriverAvailable,
                      onChanged: (val) {
                        appState.toggleDriverAvailability();
                      },
                      activeThumbImage: null, // default
                      activeColor: AppTheme.success,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),

              // Notification bell
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark.withOpacity(0.92),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: const Icon(Icons.notifications_none, color: AppTheme.textWhite, size: 20),
                    ),
                    if (appState.unreadNotificationsCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppTheme.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '${appState.unreadNotificationsCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Driver GPS Location FAB
        Positioned(
          bottom: incomingRequest != null && appState.isDriverAvailable ? 340 : 80,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'driverHomeGpsFab',
            backgroundColor: AppTheme.cardDark,
            elevation: 4,
            shape: const CircleBorder(side: BorderSide(color: AppTheme.borderDark)),
            child: const Icon(Icons.my_location, color: Color(0xFF00FFC2), size: 20),
            onPressed: () async {
              final pos = await LocationService.getCurrentPosition();
              if (pos != null) {
                appState.driverCurrentCoords = LatLng(pos.latitude, pos.longitude);
                appState.notifyListeners();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ubicación de cisterna actualizada'),
                      backgroundColor: AppTheme.cardDark,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        ),

        // Incoming Request Card (Floating Sheet)
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: incomingRequest != null && appState.isDriverAvailable
                ? Container(
                    key: ValueKey(incomingRequest.id),
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.primaryBlue, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_active, color: AppTheme.primaryBlue),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                '¡Nueva Solicitud Recibida!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                            ),
                            Text(
                              '\$${incomingRequest.price.toInt()}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: AppTheme.borderDark),
                        
                        // Customer info
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 18, color: AppTheme.textMuted),
                            const SizedBox(width: 8),
                            const Text('Cliente: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                            Text(appState.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textWhite)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Volume info
                        Row(
                          children: [
                            const Icon(Icons.water_drop_outlined, size: 18, color: AppTheme.textMuted),
                            const SizedBox(width: 8),
                            const Text('Volumen: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                            Text('${incomingRequest.liters} Litros', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textWhite)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Delivery address
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.textMuted),
                            const SizedBox(width: 8),
                            const Text('Destino: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                            Expanded(
                              child: Text(
                                incomingRequest.address,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textWhite),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  appState.driverRejectOrder(incomingRequest);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.error,
                                  side: const BorderSide(color: AppTheme.error),
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Rechazar', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  appState.driverAcceptOrder(incomingRequest);
                                  if (!DriverActiveOrderScreen.isOpen) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const DriverActiveOrderScreen()),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : appState.activeOrder != null
                    ? Container(
                        key: const ValueKey('active_order_card'),
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.success.withOpacity(0.5), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.local_shipping_outlined, color: AppTheme.success),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Viaje en Curso',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textWhite,
                                    ),
                                  ),
                                ),
                                Text(
                                  '\$${appState.activeOrder!.price.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.success,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24, color: AppTheme.borderDark),
                            
                            // Customer info
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 18, color: AppTheme.textMuted),
                                const SizedBox(width: 8),
                                const Text('Cliente: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                Text(appState.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textWhite)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Volume info
                            Row(
                              children: [
                                const Icon(Icons.water_drop_outlined, size: 18, color: AppTheme.textMuted),
                                const SizedBox(width: 8),
                                const Text('Volumen: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                Text('${appState.activeOrder!.liters} Litros', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textWhite)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Delivery address
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.textMuted),
                                const SizedBox(width: 8),
                                const Text('Destino: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                Expanded(
                                  child: Text(
                                    appState.activeOrder!.address,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textWhite),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Action button to view route
                            ElevatedButton(
                              onPressed: () {
                                if (!DriverActiveOrderScreen.isOpen) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const DriverActiveOrderScreen()),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Ver Ruta de Entrega', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        key: const ValueKey('no_order_card'),
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderDark),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Esperando solicitudes de cisternas...',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
          ),
        ),
      ],
    );
  }
}
