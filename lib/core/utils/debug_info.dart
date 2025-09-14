import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/network_config.dart';
import '../services/platform_service.dart';
import '../services/connection_monitor.dart';
import '../services/battery_service.dart';

/// Debug information utility for Android emulator and development
class DebugInfo {
  
  /// Get comprehensive debug information for troubleshooting
  static Future<Map<String, dynamic>> getDebugInfo() async {
    final platformService = PlatformService.instance;
    final connectionMonitor = ConnectionMonitor.instance;
    final batteryService = BatteryService.instance;
    
    return {
      'platform': {
        'isAndroid': Platform.isAndroid,
        'isIOS': Platform.isIOS,
        'isDebugMode': kDebugMode,
        'isReleaseMode': kReleaseMode,
      },
      'device': {
        'isAndroidEmulator': NetworkConfig.isAndroidEmulator,
        'isIOSSimulator': NetworkConfig.isIOSSimulator,
        'platformInfo': platformService.deviceInfoString,
        'performanceTier': platformService.performanceTier.name,
        'estimatedRAM': '${platformService.estimatedRAMGB}GB',
        'supportsHardwareAccel': platformService.supportsHardwareAcceleration,
      },
      'network': {
        'baseUrl': NetworkConfig.getBaseUrl(),
        'webSocketUrl': NetworkConfig.getWebSocketUrl(),
        'connectionTimeout': NetworkConfig.getConnectionTimeout().inSeconds,
        'receiveTimeout': NetworkConfig.getReceiveTimeout().inSeconds,
        'pingInterval': NetworkConfig.getWebSocketPingInterval().inSeconds,
        'hasConnection': connectionMonitor.hasConnection,
        'connectionType': connectionMonitor.connectionDescription,
        'quality': connectionMonitor.quality.name,
        'averageLatency': connectionMonitor.averageLatency,
        'recommendedInterval': connectionMonitor.recommendedUpdateInterval.inMilliseconds,
      },
      'battery': {
        'level': batteryService.batteryLevel,
        'state': batteryService.batteryState.name,
        'profile': batteryService.currentProfile.name,
        'shouldUsePowerSaving': batteryService.shouldUsePowerSaving,
        'recommendedFrameRate': batteryService.recommendedFrameRate,
      },
      'app': {
        'version': platformService.appVersion,
        'buildNumber': platformService.buildNumber,
      },
    };
  }
  
  /// Print debug information to console
  static Future<void> printDebugInfo() async {
    if (!kDebugMode) return;
    
    final info = await getDebugInfo();
    
    debugPrint('=== TESSERA MOBILE DEBUG INFO ===');
    debugPrint('Platform: ${info['platform']}');
    debugPrint('Device: ${info['device']}');
    debugPrint('Network: ${info['network']}');
    debugPrint('Battery: ${info['battery']}');
    debugPrint('App: ${info['app']}');
    debugPrint('================================');
  }
  
  /// Get formatted debug string for UI display
  static Future<String> getDebugString() async {
    final info = await getDebugInfo();
    
    final buffer = StringBuffer();
    buffer.writeln('=== DEBUG INFO ===');
    buffer.writeln();
    
    // Platform info
    buffer.writeln('PLATFORM:');
    buffer.writeln('  OS: ${Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Other'}');
    buffer.writeln('  Mode: ${kDebugMode ? 'Debug' : 'Release'}');
    buffer.writeln('  Device: ${info['device']['platformInfo']}');
    buffer.writeln('  Emulator: ${info['device']['isAndroidEmulator'] || info['device']['isIOSSimulator']}');
    buffer.writeln();
    
    // Network info
    buffer.writeln('NETWORK:');
    buffer.writeln('  Base URL: ${info['network']['baseUrl']}');
    buffer.writeln('  WebSocket: ${info['network']['webSocketUrl']}');
    buffer.writeln('  Connection: ${info['network']['connectionType']}');
    buffer.writeln('  Quality: ${info['network']['quality']} (${info['network']['averageLatency']}ms)');
    buffer.writeln('  Timeout: ${info['network']['connectionTimeout']}s');
    buffer.writeln();
    
    // Performance info
    buffer.writeln('PERFORMANCE:');
    buffer.writeln('  Tier: ${info['device']['performanceTier']}');
    buffer.writeln('  RAM: ${info['device']['estimatedRAM']}');
    buffer.writeln('  Hardware Accel: ${info['device']['supportsHardwareAccel']}');
    buffer.writeln('  Battery Level: ${info['battery']['level']}%');
    buffer.writeln('  Power Profile: ${info['battery']['profile']}');
    buffer.writeln('  Target FPS: ${info['battery']['recommendedFrameRate']}');
    buffer.writeln();
    
    // App info
    buffer.writeln('APP:');
    buffer.writeln('  Version: ${info['app']['version']}');
    buffer.writeln('  Build: ${info['app']['buildNumber']}');
    
    return buffer.toString();
  }
  
  /// Test network connectivity to backend
  static Future<Map<String, dynamic>> testConnectivity() async {
    final results = <String, dynamic>{};
    
    try {
      // Test basic socket connectivity
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect('10.0.2.2', 8081, timeout: const Duration(seconds: 5));
      socket.destroy();
      stopwatch.stop();
      
      results['socketTest'] = {
        'success': true,
        'latency': stopwatch.elapsedMilliseconds,
      };
    } catch (e) {
      results['socketTest'] = {
        'success': false,
        'error': e.toString(),
      };
    }
    
    try {
      // Test HTTP connectivity
      final client = HttpClient();
      final stopwatch = Stopwatch()..start();
      final request = await client.getUrl(Uri.parse('http://10.0.2.2:8081/health'));
      request.headers.set('User-Agent', 'TesseraMobile/Debug');
      final response = await request.close();
      stopwatch.stop();
      
      results['httpTest'] = {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'latency': stopwatch.elapsedMilliseconds,
      };
      
      client.close();
    } catch (e) {
      results['httpTest'] = {
        'success': false,
        'error': e.toString(),
      };
    }
    
    return results;
  }
  
  /// Get Android emulator specific information
  static Map<String, String> getEmulatorInfo() {
    if (!NetworkConfig.isAndroidEmulator) {
      return {'status': 'Not running on Android emulator'};
    }
    
    return {
      'emulatorHost': '10.0.2.2',
      'backendUrl': NetworkConfig.getBaseUrl(),
      'webSocketUrl': NetworkConfig.getWebSocketUrl(),
      'cleartextAllowed': 'true',
      'networkSecurityConfig': 'configured',
      'internetPermission': 'granted',
      'note': 'Android emulator maps 10.0.2.2 to host machine localhost',
    };
  }
}

/// Debug panel widget for development builds
class DebugPanel {
  static bool _isVisible = false;
  
  static bool get isVisible => _isVisible && kDebugMode;
  
  static void toggle() {
    if (kDebugMode) {
      _isVisible = !_isVisible;
    }
  }
  
  static void show() {
    if (kDebugMode) {
      _isVisible = true;
    }
  }
  
  static void hide() {
    _isVisible = false;
  }
}