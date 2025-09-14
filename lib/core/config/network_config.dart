import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkConfig {
  static const String _prodHost = 'tessera.app';
  static const String _localHost = 'localhost';
  static const String _androidEmulatorHost = '10.0.2.2';
  static const String _iosSimulatorHost = 'localhost';
  static const int _defaultPort = 8081;
  
  /// Get the appropriate base URL for the current platform and environment
  static String getBaseUrl({int port = _defaultPort, bool useHttps = false}) {
    final protocol = useHttps ? 'https' : 'http';
    final host = _getHost();
    
    return '$protocol://$host:$port';
  }
  
  /// Get the appropriate WebSocket URL for the current platform and environment
  static String getWebSocketUrl({int port = _defaultPort, bool useWss = false}) {
    final protocol = useWss ? 'wss' : 'ws';
    final host = _getHost();
    
    return '$protocol://$host:$port';
  }
  
  /// Determine the correct host based on platform and environment
  static String _getHost() {
    // In production, use the production host
    if (kReleaseMode) {
      return _prodHost;
    }
    
    // In debug mode, use platform-specific localhost handling
    if (kDebugMode) {
      if (Platform.isAndroid) {
        // Android emulator uses special IP to access host machine
        return _androidEmulatorHost;
      } else if (Platform.isIOS) {
        // iOS simulator can use localhost
        return _iosSimulatorHost;
      } else {
        // Desktop or web platforms
        return _localHost;
      }
    }
    
    // Fallback to localhost
    return _localHost;
  }
  
  /// Check if we're running on Android emulator
  static bool get isAndroidEmulator {
    return Platform.isAndroid && kDebugMode;
  }
  
  /// Check if we're running on iOS simulator
  static bool get isIOSSimulator {
    return Platform.isIOS && kDebugMode;
  }
  
  /// Get connection timeout for the current platform
  static Duration getConnectionTimeout() {
    if (isAndroidEmulator || isIOSSimulator) {
      // Longer timeout for emulators/simulators which can be slower
      return const Duration(seconds: 15);
    }
    return const Duration(seconds: 10);
  }
  
  /// Get receive timeout for the current platform
  static Duration getReceiveTimeout() {
    if (isAndroidEmulator || isIOSSimulator) {
      // Longer timeout for emulators/simulators
      return const Duration(seconds: 15);
    }
    return const Duration(seconds: 10);
  }
  
  /// Get WebSocket ping interval
  static Duration getWebSocketPingInterval() {
    if (isAndroidEmulator) {
      // More frequent pings on Android emulator to handle network transitions
      return const Duration(seconds: 20);
    }
    return const Duration(seconds: 30);
  }
  
  /// Get reconnection backoff settings for WebSocket
  static Duration getReconnectDelay(int attemptNumber) {
    final baseDelay = isAndroidEmulator || isIOSSimulator 
        ? const Duration(seconds: 2) // Faster reconnection for development
        : const Duration(seconds: 1);
        
    final exponentialDelay = Duration(
      seconds: baseDelay.inSeconds * (1 << attemptNumber),
    );
    
    // Cap at 30 seconds for production, 10 seconds for development
    final maxDelay = (isAndroidEmulator || isIOSSimulator) 
        ? const Duration(seconds: 10)
        : const Duration(seconds: 30);
        
    return exponentialDelay > maxDelay ? maxDelay : exponentialDelay;
  }
}