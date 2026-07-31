import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/client/client_home_screen.dart';
import 'screens/driver/driver_home_screen.dart';

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
      theme: AppTheme.clientTheme, // Default theme is client, dynamically switches if needed
      home: const WelcomeScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/client_home': (context) => const ClientHomeScreen(),
        '/driver_home': (context) => const DriverHomeScreen(),
      },
    );
  }
}
