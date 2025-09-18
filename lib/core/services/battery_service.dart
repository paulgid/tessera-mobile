import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:battery_plus/battery_plus.dart';
import '../network/websocket_manager.dart';

/// Battery-aware service for mobile performance optimization
class BatteryService {
  static BatteryService? _instance;
  static BatteryService get instance => _instance ??= BatteryService._();

  BatteryService._();

  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _batteryStateSubscription;

  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.full;
  bool _isInitialized = false;

  // Performance settings based on battery level
  late PerformanceProfile _currentProfile;

  int get batteryLevel => _batteryLevel;
  BatteryState get batteryState => _batteryState;
  PerformanceProfile get currentProfile => _currentProfile;
  bool get isInitialized => _isInitialized;

  /// Initialize battery monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _batteryLevel = await _battery.batteryLevel;
      _batteryState = await _battery.batteryState;
      _updatePerformanceProfile();

      // Monitor battery state changes
      _batteryStateSubscription = _battery.onBatteryStateChanged.listen((
        state,
      ) {
        _batteryState = state;
        _onBatteryStateChanged(state);
      });

      // Monitor battery level changes (check every 30 seconds)
      Timer.periodic(const Duration(seconds: 30), (_) async {
        final newLevel = await _battery.batteryLevel;
        if (newLevel != _batteryLevel) {
          _batteryLevel = newLevel;
          _onBatteryLevelChanged(newLevel);
        }
      });

      _isInitialized = true;
      debugPrint(
        'Battery service initialized - Level: $_batteryLevel%, State: $_batteryState',
      );
    } catch (e) {
      debugPrint('Failed to initialize battery service: $e');
    }
  }

  void _onBatteryStateChanged(BatteryState state) {
    debugPrint('Battery state changed: $state');
    _updatePerformanceProfile();
  }

  void _onBatteryLevelChanged(int level) {
    debugPrint('Battery level changed: $level%');
    _updatePerformanceProfile();
  }

  void _updatePerformanceProfile() {
    final oldProfile = _currentProfile;

    if (_batteryLevel < 15 || _batteryState == BatteryState.unknown) {
      _currentProfile = PerformanceProfile.battery();
    } else if (_batteryLevel < 30) {
      _currentProfile = PerformanceProfile.power();
    } else if (_batteryLevel < 50) {
      _currentProfile = PerformanceProfile.balanced();
    } else {
      _currentProfile = PerformanceProfile.performance();
    }

    if (_isInitialized && oldProfile != _currentProfile) {
      debugPrint('Performance profile changed: ${_currentProfile.name}');
      _applyPerformanceProfile();
    }
  }

  void _applyPerformanceProfile() {
    // Apply network optimizations based on battery level
    // This would be integrated with WebSocketManager and other services
    debugPrint('Applying performance profile: ${_currentProfile.name}');
    debugPrint(
      '  - Update interval: ${_currentProfile.updateInterval.inMilliseconds}ms',
    );
    debugPrint('  - Render quality: ${_currentProfile.renderQuality}');
    debugPrint('  - Animations enabled: ${_currentProfile.animationsEnabled}');
  }

  /// Configure WebSocket manager based on current battery state
  void configureWebSocket(WebSocketManager webSocketManager) {
    webSocketManager.configureForBatteryLevel(_batteryLevel);
  }

  /// Check if we should enable aggressive power saving
  bool get shouldUsePowerSaving {
    return _batteryLevel < 20 || _batteryState == BatteryState.unknown;
  }

  /// Check if we should reduce animations
  bool get shouldReduceAnimations {
    return _batteryLevel < 30;
  }

  /// Check if we should reduce network frequency
  bool get shouldReduceNetworkFrequency {
    return _batteryLevel < 40;
  }

  /// Get recommended frame rate based on battery level
  int get recommendedFrameRate {
    if (_batteryLevel < 15) return 15; // Very low battery
    if (_batteryLevel < 30) return 30; // Low battery
    if (_batteryLevel < 50) return 45; // Medium battery
    return 60; // Good battery
  }

  /// Dispose of resources
  void dispose() {
    _batteryStateSubscription?.cancel();
    _isInitialized = false;
  }
}

/// Performance profile based on battery state
class PerformanceProfile {
  final String name;
  final Duration updateInterval;
  final String renderQuality;
  final bool animationsEnabled;
  final bool particleEffectsEnabled;
  final int maxSimultaneousConnections;
  final Duration networkTimeout;

  const PerformanceProfile._({
    required this.name,
    required this.updateInterval,
    required this.renderQuality,
    required this.animationsEnabled,
    required this.particleEffectsEnabled,
    required this.maxSimultaneousConnections,
    required this.networkTimeout,
  });

  /// High performance profile for good battery levels (50%+)
  factory PerformanceProfile.performance() {
    return const PerformanceProfile._(
      name: 'Performance',
      updateInterval: Duration(milliseconds: 100),
      renderQuality: 'high',
      animationsEnabled: true,
      particleEffectsEnabled: true,
      maxSimultaneousConnections: 5,
      networkTimeout: Duration(seconds: 10),
    );
  }

  /// Balanced profile for moderate battery levels (30-50%)
  factory PerformanceProfile.balanced() {
    return const PerformanceProfile._(
      name: 'Balanced',
      updateInterval: Duration(milliseconds: 200),
      renderQuality: 'medium',
      animationsEnabled: true,
      particleEffectsEnabled: false,
      maxSimultaneousConnections: 3,
      networkTimeout: Duration(seconds: 15),
    );
  }

  /// Power saving profile for low battery levels (15-30%)
  factory PerformanceProfile.power() {
    return const PerformanceProfile._(
      name: 'Power Saving',
      updateInterval: Duration(milliseconds: 500),
      renderQuality: 'low',
      animationsEnabled: false,
      particleEffectsEnabled: false,
      maxSimultaneousConnections: 2,
      networkTimeout: Duration(seconds: 20),
    );
  }

  /// Ultra battery saving profile for critical battery levels (<15%)
  factory PerformanceProfile.battery() {
    return const PerformanceProfile._(
      name: 'Battery Saver',
      updateInterval: Duration(seconds: 2),
      renderQuality: 'minimal',
      animationsEnabled: false,
      particleEffectsEnabled: false,
      maxSimultaneousConnections: 1,
      networkTimeout: Duration(seconds: 30),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PerformanceProfile && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
