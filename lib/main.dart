import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/game/game_screen.dart';
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
  
  runApp(
    const ProviderScope(
      child: TesseraApp(),
    ),
  );
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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _mosaicIdController = TextEditingController();

  @override
  void dispose() {
    _mosaicIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tessera'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.grid_on,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Tessera',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Real-time Collaborative Mosaic Game',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _mosaicIdController,
                decoration: InputDecoration(
                  labelText: 'Mosaic ID',
                  hintText: 'Enter mosaic ID to join',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _joinMosaic,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Join Mosaic',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAction(
                    icon: Icons.add,
                    label: 'Create',
                    onTap: _createMosaic,
                  ),
                  _buildQuickAction(
                    icon: Icons.list,
                    label: 'Browse',
                    onTap: _browseMosaics,
                  ),
                  _buildQuickAction(
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: _openSettings,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  void _joinMosaic() {
    final mosaicId = _mosaicIdController.text.trim();
    if (mosaicId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a mosaic ID'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(mosaicId: mosaicId),
      ),
    );
  }

  void _createMosaic() {
    // TODO: Implement create mosaic screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create mosaic feature coming soon'),
      ),
    );
  }

  void _browseMosaics() {
    // TODO: Implement browse mosaics screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Browse mosaics feature coming soon'),
      ),
    );
  }

  void _openSettings() {
    // TODO: Implement settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings feature coming soon'),
      ),
    );
  }
}