import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'auth/register_screen.dart';
import 'auth/login_screen.dart';
import '../widgets/aquaflow_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 36),
                
                // AquaFlow Logo
                const Center(
                  child: AquaFlowLogo(size: 90),
                ),
                
                const SizedBox(height: 16),
                
                // Title & Subtitle
                const Center(
                  child: Text(
                    'AquaFlow',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textWhite,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'Agua a tu puerta',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Login Card Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Ingresa o regístrate',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Phone Input Field
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1724),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                'VE +58',
                                style: TextStyle(
                                  color: AppTheme.textWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: AppTheme.borderDark,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(color: AppTheme.textWhite),
                                decoration: const InputDecoration(
                                  hintText: '04121234567',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Continue Button (Navigates to Login OTP verification with backend)
                      ElevatedButton(
                        onPressed: () {
                          final phone = _phoneController.text.trim();
                          if (phone.isNotEmpty) {
                            appState.userPhone = phone;
                          }
                          appState.setRole(AppRole.client);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Ingresar con OTP'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Register Client Link
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            appState.setRole(AppRole.client);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(initialIsDriver: false),
                              ),
                            );
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: '¿Nuevo usuario? ',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              children: [
                                TextSpan(
                                  text: 'Regístrate como Cliente',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 14),
                      
                      // Transportista / Driver Link
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            appState.setRole(AppRole.driver);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(initialIsDriver: true),
                              ),
                            );
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: '¿Eres transportista de cisterna? ',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              children: [
                                TextSpan(
                                  text: 'Registro Cisternero',
                                  style: TextStyle(
                                    color: Color(0xFF00FFC2),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Bottom legal text
                const Text(
                  'AquaFlow System • Conexión Real API PostgreSQL',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
