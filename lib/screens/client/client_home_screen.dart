import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../services/geocoding_service.dart';
import '../../services/location_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/mock_map.dart';
import 'client_confirm_screen.dart';
import 'client_history_screen.dart';
import 'client_profile_screen.dart';
import 'client_tracking_screen.dart';
import 'client_wallet_screen.dart';
import '../notifications_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _selectedIndex = 0;
  bool _isServicePanelExpanded = true;

  // Options matching user screenshot
  final List<Map<String, dynamic>> _tankOptions = [
    {
      'liters': 1000,
      'basePrice': 20.0,
      'shippingPrice': 2.0,
      'label': '1000L',
      'isPopular': false,
    },
    {
      'liters': 2000,
      'basePrice': 40.0,
      'shippingPrice': 2.0,
      'label': '2000L',
      'isPopular': true,
    },
    {
      'liters': 5000,
      'basePrice': 80.0,
      'shippingPrice': 2.0,
      'label': '5000L',
      'isPopular': false,
    },
  ];

  // Address search / autocomplete (Nominatim)
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<PlaceSuggestion> _searchResults = [];
  Timer? _searchDebounce;
  bool _isSearching = false;
  bool _isLocatingGps = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.deliveryCoords == null && appState.userAddresses.isEmpty) {
        _useCurrentGpsLocation(appState);
      }
    });
  }

  Future<void> _useCurrentGpsLocation(AppState appState) async {
    if (_isLocatingGps) return;
    setState(() => _isLocatingGps = true);
    try {
      final pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        final coords = LatLng(pos.latitude, pos.longitude);
        final addressStr = await GeocodingService.reverseGeocode(coords) ??
            '${coords.latitude.toStringAsFixed(5)}, ${coords.longitude.toStringAsFixed(5)}';
        appState.setDeliveryLocation(addressStr, coords);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ubicación actualizada: $addressStr'),
              backgroundColor: AppTheme.primaryBlue,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo obtener la ubicación GPS del dispositivo.'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error leyendo GPS: $e');
    } finally {
      if (mounted) {
        setState(() => _isLocatingGps = false);
      }
    }
  }

  void _onSearchFocusChange() {
    if (_searchFocusNode.hasFocus) {
      setState(() {
        _isServicePanelExpanded = false;
      });
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      final results = await GeocodingService.searchPlaces(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    });
  }

  void _selectPlace(PlaceSuggestion place) {
    context.read<AppState>().setDeliveryLocation(
      place.displayName,
      place.location,
    );
    setState(() {
      _searchResults = [];
      _searchController.text = place.displayName;
    });
    FocusScope.of(context).unfocus();
  }

  bool _isCurrentAddressFavorite(AppState appState) {
    return appState.userAddresses.any(
      (a) => a['direccion_exacta'] == _searchController.text,
    );
  }

  void _showSaveFavoriteDialog(BuildContext context, AppState appState) {
    final address = _searchController.text;
    final coords = appState.deliveryCoords;
    if (coords == null) return;

    final labelCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Guardar como favorita',
          style: TextStyle(color: AppTheme.textWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              address,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textWhite, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Etiqueta (ej. Casa, Oficina)',
                hintStyle: TextStyle(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (labelCtrl.text.trim().isEmpty) return;
              await appState.addNewAddress(
                labelCtrl.text.trim(),
                address,
                '${coords.latitude},${coords.longitude}',
              );
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dirección guardada en favoritos'),
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showFavoritesSheet(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        if (appState.userAddresses.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Aún no tienes direcciones favoritas guardadas.\nBusca una dirección y toca la estrella para guardarla.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted),
            ),
          );
        }
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: appState.userAddresses.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppTheme.borderDark),
            itemBuilder: (context, index) {
              final addr = appState.userAddresses[index];
              return ListTile(
                leading: const Icon(Icons.star, color: Colors.amber),
                title: Text(
                  addr['etiqueta'] ?? 'Dirección',
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  addr['direccion_exacta'] ?? '',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  final coordStr = (addr['coordenadas'] ?? '') as String;
                  final parts = coordStr.split(',');
                  if (parts.length == 2) {
                    final lat = double.tryParse(parts[0]);
                    final lng = double.tryParse(parts[1]);
                    if (lat != null && lng != null) {
                      appState.setDeliveryLocation(
                        addr['direccion_exacta'],
                        LatLng(lat, lng),
                      );
                    } else {
                      appState.setAddress(addr['direccion_exacta']);
                    }
                  } else {
                    appState.setAddress(addr['direccion_exacta']);
                  }
                  setState(() {
                    _searchController.text = addr['direccion_exacta'] ?? '';
                    _searchResults = [];
                  });
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        );
      },
    );
  }

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
        resizeToAvoidBottomInset: false,
        backgroundColor: AppTheme.backgroundDark,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppTheme.borderDark, width: 1),
            ),
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
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment),
                label: 'Pedidos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet),
                label: 'Billetera',
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
    // Current selected option values
    final selectedOption = _tankOptions.firstWhere(
      (opt) => opt['liters'] == appState.selectedLiters,
    );
    final double basePrice = selectedOption['basePrice'];
    final double shippingPrice = selectedOption['shippingPrice'];

    return Stack(
      children: [
        // Simulated map covers full background
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            behavior: HitTestBehavior.opaque,
            child: MockMapWidget(
              showRoute: false,
              clientLocation: appState.deliveryCoords ?? RealMapWidget.parseCoords(appState.deliveryAddress),
            ),
          ),
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
                colors: [
                  AppTheme.backgroundDark,
                  AppTheme.backgroundDark.withOpacity(0.0),
                ],
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
                    const Icon(
                      Icons.location_on,
                      color: AppTheme.primaryBlue,
                      size: 24,
                    ),
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
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: AppTheme.textWhite,
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Notification Icon
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.cardDark,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_none,
                              color: AppTheme.textWhite,
                              size: 20,
                            ),
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
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${appState.unreadNotificationsCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
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
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar nueva dirección...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 20,
                        color: AppTheme.textMuted,
                      ),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            )
                          : (_searchController.text.isNotEmpty
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (appState.deliveryCoords != null &&
                                          _searchResults.isEmpty)
                                        IconButton(
                                          icon: Icon(
                                            _isCurrentAddressFavorite(appState)
                                                ? Icons.star
                                                : Icons.star_border,
                                            size: 20,
                                            color:
                                                _isCurrentAddressFavorite(
                                                  appState,
                                                )
                                                ? Colors.amber
                                                : AppTheme.textMuted,
                                          ),
                                          tooltip: 'Guardar como favorita',
                                          onPressed:
                                              _isCurrentAddressFavorite(
                                                appState,
                                              )
                                              ? null
                                              : () => _showSaveFavoriteDialog(
                                                  context,
                                                  appState,
                                                ),
                                        ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.clear,
                                          size: 18,
                                          color: AppTheme.textMuted,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchResults = []);
                                          _searchFocusNode.unfocus();
                                        },
                                      ),
                                    ],
                                  )
                                : IconButton(
                                    icon: _isLocatingGps
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppTheme.primaryBlue,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.my_location,
                                            size: 20,
                                            color: AppTheme.primaryBlue,
                                          ),
                                    tooltip: 'Usar mi ubicación GPS actual',
                                    onPressed: () =>
                                        _useCurrentGpsLocation(appState),
                                  )),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),

                // Autocomplete results dropdown
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppTheme.borderDark),
                      itemBuilder: (context, index) {
                        final place = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: AppTheme.primaryBlue,
                            size: 20,
                          ),
                          title: Text(
                            place.displayName,
                            style: const TextStyle(
                              color: AppTheme.textWhite,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectPlace(place),
                        );
                      },
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
                      onTap: () => _showFavoritesSheet(context, appState),
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
                    MaterialPageRoute(
                      builder: (context) => const ClientTrackingScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Estado: ${appState.activeOrder!.statusText}',
                              style: const TextStyle(
                                color: Color(0xFFE1F5FE),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 14,
                      ),
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: AppTheme.borderDark),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handlebar & Header (tap to toggle collapse/expand)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _isServicePanelExpanded = !_isServicePanelExpanded;
                    });
                  },
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Servicio de Cisterna',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textWhite,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                _isServicePanelExpanded
                                    ? Icons.keyboard_arrow_down
                                    : Icons.keyboard_arrow_up,
                                color: AppTheme.primaryBlue,
                                size: 22,
                              ),
                            ],
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
                    ],
                  ),
                ),

                // Tank capacity picker, pricing breakdown, confirmation button inside AnimatedSize
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: !_isServicePanelExpanded
                      ? const SizedBox(width: double.infinity, height: 4)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                                final isSelected =
                                    appState.selectedLiters == opt['liters'];
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      appState.selectLiters(
                                        opt['liters'],
                                        opt['basePrice'] + opt['shippingPrice'],
                                      );
                                    },
                                    child: Container(
                                      height: 84,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primaryBlue
                                            : const Color(0xFF111E2E),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.transparent
                                              : AppTheme.borderDark,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.water_drop_outlined,
                                                  color: isSelected
                                                      ? const Color(0xFF09121F)
                                                      : AppTheme.textMuted,
                                                  size: 24,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  opt['label'],
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFF09121F,
                                                          )
                                                        : AppTheme.textWhite,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? const Color(
                                                          0xFF0D1C2E,
                                                        ).withOpacity(0.18)
                                                      : AppTheme.primaryBlue,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'POPULAR',
                                                  style: TextStyle(
                                                    fontSize: 7,
                                                    fontWeight: FontWeight.bold,
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFF09121F,
                                                          )
                                                        : Colors.white,
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
                                  _buildCostRow(
                                    'Costo base (${selectedOption['label']}):',
                                    '\$${basePrice.toStringAsFixed(2)}',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildCostRow(
                                    'Tarifa de envío:',
                                    '\$${shippingPrice.toStringAsFixed(2)}',
                                  ),
                                  const Divider(
                                    height: 24,
                                    color: AppTheme.borderDark,
                                  ),
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
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ClientTrackingScreen(),
                                        ),
                                      );
                                    }
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ClientConfirmScreen(),
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3498DB),
                                foregroundColor: const Color(0xFF09121F),
                                elevation: 0,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.local_shipping,
                                    size: 20,
                                    color: Color(0xFF09121F),
                                  ),
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
