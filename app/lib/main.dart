import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:epo_app/data/ble_service.dart';
import 'package:epo_app/repository/medication_repository.dart';
import 'package:epo_app/ui/app_state.dart';
import 'package:epo_app/ui/screens/login_screen.dart';
import 'package:epo_app/ui/screens/dashboard_screen.dart';
import 'package:epo_app/ui/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Note: Firebase.initializeApp() requires platform-specific configuration files.
  // This will fail until google-services.json/GoogleService-Info.plist are added.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  final bleService = BLEService();
  final medicationRepository = MedicationRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState(bleService, medicationRepository)),
      ],
      child: const EpoApp(),
    ),
  );
}

class EpoApp extends StatelessWidget {
  const EpoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ePO Smart Pill Box',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
