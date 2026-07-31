import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'auth/register_screen.dart';
import 'auth/login_screen.dart';
import 'client/client_home_screen.dart';
import 'driver/driver_home_screen.dart';

import '../widgets/aquaflow_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _phoneController = TextEditingController();
  String _selectedVerificationMethod = 'SMS'; // 'SMS' or 'WhatsApp'

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                
                // AquaFlow Logo (Wave icon)
                const Center(
                  child: AquaFlowLogo(size: 95),
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
                
                const SizedBox(height: 40),
                
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
                            // Country code picker
                            GestureDetector(
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Row(
                                  children: [
                                    const Text(
                                      'VE +58',
                                      style: TextStyle(
                                        color: AppTheme.textWhite,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade400, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 24,
                              color: AppTheme.borderDark,
                            ),
                            // Number Field
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(color: AppTheme.textWhite),
                                decoration: const InputDecoration(
                                  hintText: 'Número de teléfono',
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
                      
                      const Text(
                        'Recibir código de verificación vía:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Verification options (SMS / WhatsApp)
                      Row(
                        children: [
                          Expanded(
                            child: _buildVerificationButton(
                              label: 'SMS',
                              icon: Icons.chat_bubble_outline,
                              isSelected: _selectedVerificationMethod == 'SMS',
                              onTap: () {
                                setState(() {
                                  _selectedVerificationMethod = 'SMS';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildVerificationButton(
                              label: 'WhatsApp',
                              icon: Icons.forum_outlined, // Fallback for whatsapp icon
                              isSelected: _selectedVerificationMethod == 'WhatsApp',
                              onTap: () {
                                setState(() {
                                  _selectedVerificationMethod = 'WhatsApp';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Continue Button
                      ElevatedButton(
                        onPressed: () {
                          // Validation & Direct login flow
                          if (_phoneController.text.isNotEmpty) {
                            appState.setRole(AppRole.client);
                            appState.userPhone = '+58 ${_phoneController.text}';
                            
                            // Mock transition directly to Home for seamless testing
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const ClientHomeScreen()),
                            );
                          } else {
                            // If empty, redirect to full registration screen for presentation
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Continuar'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Inicia Sesión Link
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            appState.setRole(AppRole.client);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: '¿Ya tienes una cuenta? ',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                              children: [
                                TextSpan(
                                  text: 'Inicia sesión',
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
                      
                      const SizedBox(height: 12),
                      
                      // Transportista / Driver Link
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            // Switch role to driver and open driver portal
                            appState.setRole(AppRole.driver);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
                            );
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: '¿Eres transportista? ',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                              children: [
                                TextSpan(
                                  text: 'Regístrate aquí',
                                  style: TextStyle(
                                    color: Color(0xFF00FFC2), // Light cyan
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
                  'Al continuar, aceptas nuestros Términos y Condiciones y Política de Privacidad.',
                  style: TextStyle(
                    fontSize: 10,
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

  Widget _buildVerificationButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.borderDark,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
