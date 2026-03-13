import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:epo_app/data/ble_service.dart';
import 'package:epo_app/repository/medication_repository.dart';
import 'package:epo_app/ui/app_state.dart';
import 'package:epo_app/ui/screens/dashboard_screen.dart';
import 'package:epo_app/ui/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      home: const DashboardScreen(),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
