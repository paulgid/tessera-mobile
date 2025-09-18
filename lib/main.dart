import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/navigation/main_navigation.dart';
import 'core/services/platform_service.dart';
import 'core/services/battery_service.dart';
import 'core/services/connection_monitor.dart';
import 'core/utils/debug_info.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize platform-specific services
  await PlatformService.instance.initialize();

  // Initialize mobile services
  await _initializeMobileServices();

  // Lock orientation for mobile gaming experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: TesseraApp()));
}

/// Initialize mobile-specific services for Android and iOS
Future<void> _initializeMobileServices() async {
  try {
    // Initialize battery service for power management
    await BatteryService.instance.initialize();
    debugPrint('Battery service initialized');

    // Initialize connection monitor for network quality
    await ConnectionMonitor.instance.initialize();
    debugPrint('Connection monitor initialized');

    // Print debug info in debug mode
    if (kDebugMode) {
      await DebugInfo.printDebugInfo();
    }
  } catch (e) {
    debugPrint('Error initializing mobile services: $e');
  }
}

class TesseraApp extends StatelessWidget {
  const TesseraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tessera',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade900,
          elevation: 0,
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

// HomePage removed - using MainNavigation with bottom tabs instead
