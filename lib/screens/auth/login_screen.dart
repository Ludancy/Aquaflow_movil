import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../client/client_home_screen.dart';
import '../driver/driver_home_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool initialIsDriver;

  const LoginScreen({
    Key? key,
    this.initialIsDriver = true,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for Login & Register
  final _idController = TextEditingController();
  final _pinController = TextEditingController();
  final _otpController = TextEditingController();
  
  // Registration fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _licenseController = TextEditingController();
  final _truckBrandController = TextEditingController();
  final _truckModelController = TextEditingController();
  final _truckPlateController = TextEditingController();
  final _truckCapacityController = TextEditingController();

  bool _isDriver = true;
  bool _isRegisterMode = false; // false = Login, true = Register
  bool _rememberMe = true;
  bool _obscurePin = true;
  bool _isLoading = false;
  String? _devOtp;

  @override
  void initState() {
    super.initState();
    _isDriver = widget.initialIsDriver;
  }

  @override
  void dispose() {
    _idController.dispose();
    _pinController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _taxIdController.dispose();
    _licenseController.dispose();
    _truckBrandController.dispose();
    _truckModelController.dispose();
    _truckPlateController.dispose();
    _truckCapacityController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppState>();
    appState.setRole(_isDriver ? AppRole.driver : AppRole.client);

    if (_isRegisterMode) {
      _handleRegister(appState);
    } else {
      _handleLogin(appState);
    }
  }

  void _handleRegister(AppState appState) async {
    setState(() => _isLoading = true);

    final phone = _idController.text.trim();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final taxId = _taxIdController.text.trim();

    if (!_isDriver) {
      // Register Client
      if (appState.isBackendConnected) {
        final res = await ApiService.registerClient(
          nombre: name,
          telefono: phone,
          email: email.isNotEmpty ? email : 'cliente_$phone@aquaflow.com',
          identificacionFiscal: taxId.isNotEmpty ? taxId : 'J-$phone-0',
        );
        setState(() => _isLoading = false);

        if (res != null && res['data'] != null) {
          final data = res['data'];
          final usuario = data['usuario'];
          appState.setCurrentUser(usuario, 'cliente');
        } else {
          appState.userName = name;
          appState.userPhone = phone;
          appState.userEmail = email;
        }
      } else {
        setState(() => _isLoading = false);
        appState.userName = name;
        appState.userPhone = phone;
        appState.userEmail = email;
      }

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ClientHomeScreen()),
          (route) => false,
        );
      }
    } else {
      // Driver Onboarding
      final license = _licenseController.text.trim();
      final brand = _truckBrandController.text.trim();
      final model = _truckModelController.text.trim();
      final plate = _truckPlateController.text.trim();
      final capacity = double.tryParse(_truckCapacityController.text.trim()) ?? 10000.0;

      if (appState.isBackendConnected) {
        final res = await ApiService.driverOnboarding(
          nombre: name,
          telefono: phone,
          email: email.isNotEmpty ? email : 'cisternero_$phone@aquaflow.com',
          licenciaConducir: license.isNotEmpty ? license : 'L-$phone',
          rifPersonal: taxId.isNotEmpty ? taxId : 'V-$phone',
          vehiculo: {
            'marca': brand.isNotEmpty ? brand : 'Ford',
            'modelo': model.isNotEmpty ? model : 'F-350',
            'placa': plate.isNotEmpty ? plate : 'A12B34',
            'capacidad_tanque': capacity,
          },
        );
        setState(() => _isLoading = false);

        if (res != null && res['data'] != null) {
          final data = res['data'];
          final usuario = data['usuario'];
          appState.setCurrentUser(usuario, 'cisternero');
          appState.driverTruck = '$brand $model';
          appState.driverPlate = plate;
        } else {
          appState.driverName = name;
          appState.driverPhone = phone;
          appState.driverEmail = email;
          appState.driverTruck = '$brand $model';
          appState.driverPlate = plate;
        }
      } else {
        setState(() => _isLoading = false);
        appState.driverName = name;
        appState.driverPhone = phone;
        appState.driverEmail = email;
        appState.driverTruck = '$brand $model';
        appState.driverPlate = plate;
      }

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
          (route) => false,
        );
      }
    }
  }

  void _handleLogin(AppState appState) async {
    final inputId = _idController.text.trim();

    if (appState.isBackendConnected) {
      setState(() => _isLoading = true);
      final res = await ApiService.login(inputId);
      setState(() => _isLoading = false);

      if (res != null) {
        setState(() {
          _devOtp = res['otp_dev'];
        });
        if (context.mounted) {
          _showOtpModal(context, inputId, !_isDriver);
        }
      } else {
        _directLogin(appState);
      }
    } else {
      _directLogin(appState);
    }
  }

  void _directLogin(AppState appState) {
    if (!_isDriver) {
      appState.userPhone = _idController.text;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ClientHomeScreen()),
        (route) => false,
      );
    } else {
      appState.driverPhone = _idController.text;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
        (route) => false,
      );
    }
  }

  void _showOtpModal(BuildContext context, String phone, bool isClient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Verificación de Código OTP',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa el código enviado a $phone.',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              if (_devOtp != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '🔑 Código OTP Dev: $_devOtp',
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textWhite, fontSize: 20, letterSpacing: 4),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'Código OTP (6 dígitos)',
                  hintText: '123456',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final otpCode = _otpController.text.trim();
                  if (otpCode.isEmpty) return;

                  final res = await ApiService.verifyOtp(phone, otpCode);
                  if (res != null && res['data'] != null) {
                    final data = res['data'];
                    final usuario = data['usuario'];
                    final rol = data['rol'];
                    final appState = context.read<AppState>();
                    appState.setCurrentUser(usuario, rol);

                    if (ctx.mounted) Navigator.pop(ctx);

                    if (rol == 'cisternero' || _isDriver) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
                        (route) => false,
                      );
                    } else {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const ClientHomeScreen()),
                        (route) => false,
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código OTP inválido o expirado')),
                    );
                  }
                },
                child: const Text('Verificar e Iniciar Turno'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
            filled: true,
            fillColor: const Color(0xFF131F30),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF22354E)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF22354E)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3498DB)),
            ),
          ),
          validator: isRequired
              ? (val) {
                  if (val == null || val.isEmpty) return 'Campo requerido';
                  return null;
                }
              : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08101C), // Deep night dark navy
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Circular Glowing Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2137),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF3498DB), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3498DB).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.water_drop,
                      color: Color(0xFF3498DB),
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // App Title
                const Text(
                  'AquaFlow',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isRegisterMode ? 'REGISTRO DE USUARIO' : 'CISTERNA OPERATIONS',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B4D8),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                // Main Card Container with top cyan highlight
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1724),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1E2D42)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cyan highlight top border line
                        Container(
                          height: 3,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF00B4D8), Color(0xFF3498DB)],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Role Switcher (Cliente vs Empleado)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF162335),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF22354E)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() => _isDriver = false);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: !_isDriver ? const Color(0xFF0D1724) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                              border: !_isDriver ? Border.all(color: const Color(0xFF2E4360)) : null,
                                            ),
                                            child: Text(
                                              'Cliente',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: !_isDriver ? Colors.white : AppTheme.textMuted,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() => _isDriver = true);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              color: _isDriver ? const Color(0xFF08101C) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                              border: _isDriver ? Border.all(color: const Color(0xFF3498DB)) : null,
                                            ),
                                            child: Text(
                                              'Empleado',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: _isDriver ? Colors.white : AppTheme.textMuted,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Mode Selector: Ingresar vs Registrarse
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(() => _isRegisterMode = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: !_isRegisterMode ? const Color(0xFF3498DB) : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Iniciar Sesión',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: !_isRegisterMode ? const Color(0xFF3498DB) : AppTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    GestureDetector(
                                      onTap: () => setState(() => _isRegisterMode = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: _isRegisterMode ? const Color(0xFF3498DB) : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Registrarse',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _isRegisterMode ? const Color(0xFF3498DB) : AppTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // REGISTRATION EXTRA FIELDS
                                if (_isRegisterMode) ...[
                                  _buildTextField(
                                    controller: _nameController,
                                    label: 'Nombre Completo',
                                    hint: 'e.g. Juan Pérez',
                                    icon: Icons.person_outline,
                                  ),
                                  _buildTextField(
                                    controller: _emailController,
                                    label: 'Correo Electrónico',
                                    hint: 'e.g. juan@ejemplo.com',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    isRequired: false,
                                  ),
                                  _buildTextField(
                                    controller: _taxIdController,
                                    label: _isDriver ? 'RIF Personal / Cédula' : 'Identificación Fiscal / RIF',
                                    hint: _isDriver ? 'e.g. V-12345678' : 'e.g. J-12345678-0',
                                    icon: Icons.assignment_ind_outlined,
                                  ),

                                  if (_isDriver) ...[
                                    _buildTextField(
                                      controller: _licenseController,
                                      label: 'Licencia de Conducir',
                                      hint: 'e.g. L-87654321',
                                      icon: Icons.badge_outlined,
                                    ),
                                    const Divider(height: 24, color: Color(0xFF22354E)),
                                    const Text(
                                      'DATOS DE LA CISTERNA',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00B4D8),
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _truckBrandController,
                                            label: 'Marca',
                                            hint: 'Ford',
                                            icon: Icons.directions_bus_outlined,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _truckModelController,
                                            label: 'Modelo',
                                            hint: 'F-350',
                                            icon: Icons.local_shipping_outlined,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _truckPlateController,
                                            label: 'Placa',
                                            hint: 'A12B34',
                                            icon: Icons.subtitles_outlined,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _truckCapacityController,
                                            label: 'Capacidad (Lts)',
                                            hint: '10000',
                                            icon: Icons.opacity_outlined,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],

                                // PHONE / ID FIELD
                                _buildTextField(
                                  controller: _idController,
                                  label: _isDriver ? 'Teléfono de Contacto' : 'Número de Teléfono',
                                  hint: '04121234567',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),

                                // PIN / LOGIN PASSWORD FIELDS
                                if (!_isRegisterMode) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'PIN de Seguridad / Contraseña',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Contacte al administrador para restablecer su PIN.')),
                                          );
                                        },
                                        child: const Text(
                                          'Restablecer',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF3498DB),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _pinController,
                                    obscureText: _obscurePin,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: '••••••••',
                                      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 20),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePin ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                          color: AppTheme.textMuted,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() => _obscurePin = !_obscurePin);
                                        },
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF131F30),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF22354E)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF22354E)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF3498DB)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Checkbox: Mantener sesión iniciada
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: const Color(0xFF3498DB),
                                          onChanged: (val) {
                                            setState(() => _rememberMe = val ?? true);
                                          },
                                          side: const BorderSide(color: Color(0xFF22354E)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Mantener sesión iniciada',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 24),

                                // Main Action Button
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3498DB),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _isRegisterMode
                                                  ? 'Completar Registro e Iniciar'
                                                  : (_isDriver ? 'Iniciar Turno' : 'Ingresar al Sistema'),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              _isRegisterMode
                                                  ? Icons.person_add_outlined
                                                  : (_isDriver ? Icons.local_shipping_outlined : Icons.arrow_forward),
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                                const SizedBox(height: 18),

                                // Link to switch modes
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _isRegisterMode = !_isRegisterMode);
                                    },
                                    child: Text(
                                      _isRegisterMode
                                          ? '¿Ya tienes una cuenta? Iniciar Sesión'
                                          : '¿No tienes cuenta? Registrarse aquí',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3498DB),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Status Indicator
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF00FFC2), // Glowing cyan-green dot
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Sistemas Operativos',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Footer
                const Text(
                  '© 2024 AquaFlow Logística. Todos los derechos reservados.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131F30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF22354E)),
                  ),
                  child: Text(
                    _isDriver ? 'Versión 2.4.1 (Cisternero Build)' : 'Versión 2.4.1 (Cliente Build)',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF3498DB),
                      fontWeight: FontWeight.w600,
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
