import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Mobile-optimized connection quality monitor
class ConnectionMonitor {
  static ConnectionMonitor? _instance;
  static ConnectionMonitor get instance => _instance ??= ConnectionMonitor._();

  ConnectionMonitor._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  ConnectionQuality _quality = ConnectionQuality.poor;
  int _latency = 0;
  bool _isInitialized = false;

  // Quality monitoring
  Timer? _qualityTimer;
  final List<int> _latencyHistory = [];
  final int _maxLatencyHistory = 10;

  ConnectivityResult get connectionStatus => _connectionStatus;
  ConnectionQuality get quality => _quality;
  int get averageLatency => _latency;
  bool get isInitialized => _isInitialized;

  bool get hasConnection => _connectionStatus != ConnectivityResult.none;
  bool get hasWifi => _connectionStatus == ConnectivityResult.wifi;
  bool get hasMobile => _connectionStatus == ConnectivityResult.mobile;
  bool get hasEthernet => _connectionStatus == ConnectivityResult.ethernet;

  /// Initialize connection monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _connectionStatus = await _connectivity.checkConnectivity();
      await _measureInitialQuality();

      // Monitor connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        result,
      ) {
        _connectionStatus = result;
        _onConnectivityChanged(result);
      });

      // Start quality monitoring (every 30 seconds)
      _qualityTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _measureConnectionQuality();
      });

      _isInitialized = true;
      debugPrint(
        'Connection monitor initialized - Status: $_connectionStatus, Quality: $_quality',
      );
    } catch (e) {
      debugPrint('Failed to initialize connection monitor: $e');
    }
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    debugPrint('Connectivity changed: $result');

    // Immediate quality check on connectivity change
    Timer(const Duration(seconds: 2), () {
      _measureConnectionQuality();
    });
  }

  Future<void> _measureInitialQuality() async {
    await _measureConnectionQuality();
  }

  Future<void> _measureConnectionQuality() async {
    if (!hasConnection) {
      _quality = ConnectionQuality.none;
      _latency = 0;
      _latencyHistory.clear();
      return;
    }

    try {
      final latency = await _measureLatency();
      _latency = latency;

      // Track latency history for better quality assessment
      _latencyHistory.add(latency);
      if (_latencyHistory.length > _maxLatencyHistory) {
        _latencyHistory.removeAt(0);
      }

      _quality = _calculateQuality();
      debugPrint(
        'Connection quality measured - Latency: ${latency}ms, Quality: $_quality',
      );
    } catch (e) {
      debugPrint('Failed to measure connection quality: $e');
      _quality = ConnectionQuality.poor;
    }
  }

  Future<int> _measureLatency() async {
    final stopwatch = Stopwatch()..start();

    try {
      // Use different servers based on connection type for mobile optimization
      final host = hasWifi ? 'google.com' : '8.8.8.8';
      final socket = await Socket.connect(
        host,
        80,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      stopwatch.stop();

      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      stopwatch.stop();
      // Return high latency on connection failure
      return 5000;
    }
  }

  ConnectionQuality _calculateQuality() {
    if (_latencyHistory.isEmpty) return ConnectionQuality.poor;

    final avgLatency =
        _latencyHistory.reduce((a, b) => a + b) / _latencyHistory.length;

    // Mobile-optimized quality thresholds
    if (hasWifi) {
      // WiFi quality thresholds
      if (avgLatency < 50) return ConnectionQuality.excellent;
      if (avgLatency < 100) return ConnectionQuality.good;
      if (avgLatency < 200) return ConnectionQuality.fair;
      if (avgLatency < 500) return ConnectionQuality.poor;
      return ConnectionQuality.terrible;
    } else if (hasMobile) {
      // Mobile data quality thresholds (more lenient)
      if (avgLatency < 100) return ConnectionQuality.excellent;
      if (avgLatency < 200) return ConnectionQuality.good;
      if (avgLatency < 400) return ConnectionQuality.fair;
      if (avgLatency < 800) return ConnectionQuality.poor;
      return ConnectionQuality.terrible;
    } else {
      // Other connection types
      if (avgLatency < 30) return ConnectionQuality.excellent;
      if (avgLatency < 80) return ConnectionQuality.good;
      if (avgLatency < 150) return ConnectionQuality.fair;
      if (avgLatency < 300) return ConnectionQuality.poor;
      return ConnectionQuality.terrible;
    }
  }

  /// Get recommended update frequency based on connection quality
  Duration get recommendedUpdateInterval {
    switch (_quality) {
      case ConnectionQuality.excellent:
        return const Duration(milliseconds: 100);
      case ConnectionQuality.good:
        return const Duration(milliseconds: 200);
      case ConnectionQuality.fair:
        return const Duration(milliseconds: 500);
      case ConnectionQuality.poor:
        return const Duration(seconds: 1);
      case ConnectionQuality.terrible:
        return const Duration(seconds: 3);
      case ConnectionQuality.none:
        return const Duration(seconds: 10);
    }
  }

  /// Get recommended data compression settings
  bool get shouldCompressData {
    return _quality.index <= ConnectionQuality.fair.index || hasMobile;
  }

  /// Get recommended connection timeout
  Duration get recommendedTimeout {
    if (hasMobile) {
      switch (_quality) {
        case ConnectionQuality.excellent:
        case ConnectionQuality.good:
          return const Duration(seconds: 15);
        case ConnectionQuality.fair:
          return const Duration(seconds: 20);
        case ConnectionQuality.poor:
        case ConnectionQuality.terrible:
          return const Duration(seconds: 30);
        case ConnectionQuality.none:
          return const Duration(seconds: 60);
      }
    } else {
      switch (_quality) {
        case ConnectionQuality.excellent:
        case ConnectionQuality.good:
          return const Duration(seconds: 10);
        case ConnectionQuality.fair:
          return const Duration(seconds: 15);
        case ConnectionQuality.poor:
        case ConnectionQuality.terrible:
          return const Duration(seconds: 25);
        case ConnectionQuality.none:
          return const Duration(seconds: 60);
      }
    }
  }

  /// Check if connection is suitable for real-time gaming
  bool get isSuitableForRealTime {
    return _quality.index >= ConnectionQuality.fair.index && hasConnection;
  }

  /// Get connection type description
  String get connectionDescription {
    if (!hasConnection) return 'No connection';

    final types = <String>[];
    if (hasWifi) types.add('WiFi');
    if (hasMobile) types.add('Mobile');
    if (hasEthernet) types.add('Ethernet');

    final typeStr = types.join(' + ');
    return '$typeStr (${_quality.name}, ${averageLatency}ms)';
  }

  /// Dispose of resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _qualityTimer?.cancel();
    _isInitialized = false;
  }
}

enum ConnectionQuality {
  none,
  terrible, // >500ms WiFi, >800ms mobile
  poor, // 200-500ms WiFi, 400-800ms mobile
  fair, // 100-200ms WiFi, 200-400ms mobile
  good, // 50-100ms WiFi, 100-200ms mobile
  excellent, // <50ms WiFi, <100ms mobile
}

extension ConnectionQualityExtension on ConnectionQuality {
  String get name {
    switch (this) {
      case ConnectionQuality.none:
        return 'No Connection';
      case ConnectionQuality.terrible:
        return 'Terrible';
      case ConnectionQuality.poor:
        return 'Poor';
      case ConnectionQuality.fair:
        return 'Fair';
      case ConnectionQuality.good:
        return 'Good';
      case ConnectionQuality.excellent:
        return 'Excellent';
    }
  }

  /// Get quality as percentage (0-100)
  int get percentage {
    switch (this) {
      case ConnectionQuality.none:
        return 0;
      case ConnectionQuality.terrible:
        return 20;
      case ConnectionQuality.poor:
        return 40;
      case ConnectionQuality.fair:
        return 60;
      case ConnectionQuality.good:
        return 80;
      case ConnectionQuality.excellent:
        return 100;
    }
  }
}
