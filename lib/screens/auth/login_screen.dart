import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import 'register_screen.dart';
import '../client/client_home_screen.dart';
import '../driver/driver_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _devOtp;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppState>();
    final isClient = appState.currentRole == AppRole.client;

    if (appState.isBackendConnected) {
      setState(() => _isLoading = true);
      final phone = _phoneController.text.trim();
      final res = await ApiService.login(phone);
      setState(() => _isLoading = false);

      if (res != null) {
        setState(() {
          _devOtp = res['otp_dev'];
        });
        if (context.mounted) {
          _showOtpModal(context, phone, isClient);
        }
      } else {
        // Fallback login
        _directLogin(appState, isClient);
      }
    } else {
      _directLogin(appState, isClient);
    }
  }

  void _directLogin(AppState appState, bool isClient) {
    if (isClient) {
      appState.userEmail = _emailController.text.isNotEmpty ? _emailController.text : 'cliente@test.com';
      appState.userPhone = _phoneController.text;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ClientHomeScreen()),
        (route) => false,
      );
    } else {
      appState.driverEmail = _emailController.text.isNotEmpty ? _emailController.text : 'cisternero@test.com';
      appState.driverPhone = _phoneController.text;
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                'Verificación OTP',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa el código enviado a $phone.',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
              if (_devOtp != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
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

                    if (rol == 'cisternero') {
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
                child: const Text('Verificar e Ingresar'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isClient = appState.currentRole == AppRole.client;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                
                // Header
                Text(
                  isClient ? '¡Hola de nuevo!' : 'Portal de Conductor',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isClient 
                      ? 'Ingresa tu teléfono para recibir tu código OTP.' 
                      : 'Inicia sesión con tu teléfono para comenzar a entregar.',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 32),

                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(
                    labelText: 'Número de Teléfono',
                    hintText: '04121234567',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu teléfono';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email Field (Optional)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textWhite),
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico (Opcional)',
                    hintText: 'ejemplo@correo.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 28),

                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Solicitar OTP e Iniciar Sesión'),
                ),
                
                // Register Link
                if (isClient) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '¿No tienes una cuenta? ',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Regístrate',
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
