import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/client/client_home_screen.dart';
import 'screens/driver/driver_home_screen.dart';

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        if (appState.isSessionRestoring) {
          return const Scaffold(
            backgroundColor: Color(0xFF08101C),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF3498DB))),
          );
        }
        if (appState.currentUserId != null) {
          return appState.currentRole == AppRole.driver
              ? const DriverHomeScreen()
              : const ClientHomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const AquaFlowApp(),
    ),
  );
}

class AquaFlowApp extends StatelessWidget {
  const AquaFlowApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.clientTheme,
      home: const _AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/client_home': (context) => const ClientHomeScreen(),
        '/driver_home': (context) => const DriverHomeScreen(),
      },
    );
  }
}
