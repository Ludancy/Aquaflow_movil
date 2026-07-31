import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../client/client_home_screen.dart';
import '../driver/driver_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final bool initialIsDriver;
  const RegisterScreen({Key? key, this.initialIsDriver = false}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _rifController = TextEditingController();

  // Driver fields
  final _licenseController = TextEditingController();
  final _truckBrandController = TextEditingController();
  final _truckModelController = TextEditingController();
  final _truckPlateController = TextEditingController();
  final _truckCapacityController = TextEditingController();

  late bool _isDriverTab;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isDriverTab = widget.initialIsDriver;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _rifController.dispose();
    _licenseController.dispose();
    _truckBrandController.dispose();
    _truckModelController.dispose();
    _truckPlateController.dispose();
    _truckCapacityController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppState>();
    setState(() => _isLoading = true);

    if (appState.isBackendConnected) {
      if (!_isDriverTab) {
        // Client registration
        final res = await ApiService.registerClient(
          nombre: _nameController.text.trim(),
          telefono: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          identificacionFiscal: _rifController.text.trim(),
        );

        setState(() => _isLoading = false);

        if (res != null && res['data'] != null) {
          appState.setCurrentUser(res['data'], 'cliente');
          if (_addressController.text.isNotEmpty) {
            await appState.addNewAddress(
              'Principal',
              _addressController.text.trim(),
              '10.48,-66.90',
            );
          }
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const ClientHomeScreen()),
              (route) => false,
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al registrar cliente (posible email duplicado)')),
            );
          }
        }
      } else {
        // Driver onboarding
        final res = await ApiService.driverOnboarding(
          nombre: _nameController.text.trim(),
          telefono: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          licenciaConducir: _licenseController.text.trim(),
          rifPersonal: _rifController.text.trim(),
          vehiculo: {
            'marca': _truckBrandController.text.trim(),
            'modelo': _truckModelController.text.trim(),
            'placa': _truckPlateController.text.trim(),
            'capacidad_tanque': double.tryParse(_truckCapacityController.text) ?? 5000.0,
          },
        );

        setState(() => _isLoading = false);

        if (res != null && res['data'] != null) {
          appState.setCurrentUser(res['data'], 'cisternero');
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
              (route) => false,
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al registrar conductor')),
            );
          }
        }
      }
    } else {
      // Offline direct simulation
      setState(() => _isLoading = false);
      appState.userName = _nameController.text;
      appState.userEmail = _emailController.text;
      appState.userPhone = _phoneController.text;
      appState.deliveryAddress = _addressController.text;

      if (!_isDriverTab) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ClientHomeScreen()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Registro AquaFlow',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textWhite),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Role switch tabs
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isDriverTab = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isDriverTab ? AppTheme.primaryBlue : AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Cliente',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isDriverTab ? AppTheme.textWhite : AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isDriverTab = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isDriverTab ? AppTheme.primaryBlue : AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Cisternero',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isDriverTab ? AppTheme.textWhite : AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  _isDriverTab ? 'Registro de Conductor' : 'Crear Cuenta Cliente',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isDriverTab
                      ? 'Ingresa tus datos y los de tu unidad cisterna.'
                      : 'Completa tus datos para comenzar a pedir agua.',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 24),

                // Basic fields
                _buildInputField(
                  label: 'Nombre Completo',
                  hint: 'Ej. Carlos Mendoza',
                  icon: Icons.person_outline,
                  controller: _nameController,
                  validator: (val) => val == null || val.isEmpty ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  label: 'Correo Electrónico',
                  hint: 'carlos@ejemplo.com',
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  validator: (val) => val == null || !val.contains('@') ? 'Correo inválido' : null,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  label: 'Número de Teléfono',
                  hint: '04141234567',
                  icon: Icons.phone_outlined,
                  controller: _phoneController,
                  validator: (val) => val == null || val.isEmpty ? 'Ingresa tu teléfono' : null,
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  label: 'RIF / Identificación Fiscal',
                  hint: 'J-12345678-0',
                  icon: Icons.badge_outlined,
                  controller: _rifController,
                  validator: (val) => val == null || val.isEmpty ? 'Ingresa tu RIF' : null,
                ),
                const SizedBox(height: 16),

                if (!_isDriverTab) ...[
                  _buildInputField(
                    label: 'Dirección de Entrega Principal',
                    hint: 'Av. Principal, Edif. Orinoco',
                    icon: Icons.location_on_outlined,
                    controller: _addressController,
                    validator: (val) => val == null || val.isEmpty ? 'Ingresa tu dirección' : null,
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  _buildInputField(
                    label: 'Licencia de Conducir',
                    hint: 'L-12345678',
                    icon: Icons.card_membership,
                    controller: _licenseController,
                    validator: (val) => val == null || val.isEmpty ? 'Ingresa tu licencia' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: 'Marca Camión',
                          hint: 'Ford',
                          icon: Icons.directions_car,
                          controller: _truckBrandController,
                          validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputField(
                          label: 'Modelo',
                          hint: 'F-350',
                          icon: Icons.local_shipping,
                          controller: _truckModelController,
                          validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          label: 'Placa Vehículo',
                          hint: 'A42K890',
                          icon: Icons.confirmation_number,
                          controller: _truckPlateController,
                          validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputField(
                          label: 'Tanque (Litros)',
                          hint: '5000',
                          icon: Icons.water_drop,
                          controller: _truckCapacityController,
                          validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(_isDriverTab ? 'Registrarme como Conductor' : 'Registrarme como Cliente'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
