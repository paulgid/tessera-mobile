import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/game_update.dart';
import '../config/network_config.dart';

class WebSocketManager {
  WebSocketChannel? _channel;
  final StreamController<GameUpdate> _updateController =
      StreamController.broadcast();
  final StreamController<ConnectionStatus> _statusController =
      StreamController.broadcast();

  String _mosaicId = '';
  String _baseWebSocketUrl = NetworkConfig.getWebSocketUrl();
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  bool _isDisposed = false;
  bool _intentionalDisconnect = false;

  // Adaptive settings
  Duration _updateInterval = const Duration(milliseconds: 500);
  bool _compressionEnabled = false;
  bool _reducedQuality = false;

  // Connectivity monitoring
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  Stream<GameUpdate> get updates => _updateController.stream;
  Stream<ConnectionStatus> get status => _statusController.stream;
  bool get isConnected => _channel != null;

  WebSocketManager() {
    _initConnectivityMonitoring();
  }

  void _initConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      if (result == ConnectivityResult.none) {
        _handleDisconnect();
      } else if (!isConnected && !_intentionalDisconnect) {
        _reconnect();
      }
    });
  }

  Future<void> connect(String mosaicId, {String? baseWebSocketUrl}) async {
    _mosaicId = mosaicId;
    _baseWebSocketUrl = baseWebSocketUrl ?? NetworkConfig.getWebSocketUrl();
    _intentionalDisconnect = false;

    await _establishConnection();
  }

  Future<void> _establishConnection() async {
    if (_isDisposed) return;

    try {
      _statusController.add(ConnectionStatus.connecting);

      final uri = Uri.parse('$_baseWebSocketUrl/ws?mosaic_id=$_mosaicId');
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;

      _statusController.add(ConnectionStatus.connected);
      _reconnectAttempts = 0;

      _startPingTimer();

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      debugPrint(
        'WebSocket connected to $_baseWebSocketUrl for mosaic $_mosaicId',
      );
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _handleError(e);
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = jsonDecode(message.toString());
      final update = GameUpdate.fromJson(data);
      _updateController.add(update);
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('WebSocket error: $error');
    _statusController.add(ConnectionStatus.error);
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    debugPrint('WebSocket disconnected');
    _channel = null;
    _pingTimer?.cancel();

    if (!_intentionalDisconnect && !_isDisposed) {
      _statusController.add(ConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed || _intentionalDisconnect) return;

    _reconnectTimer?.cancel();

    // Platform-aware exponential backoff with max delay
    final delay = NetworkConfig.getReconnectDelay(_reconnectAttempts);

    _reconnectAttempts++;
    debugPrint(
      'Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s',
    );

    _reconnectTimer = Timer(delay, _reconnect);
  }

  Future<void> _reconnect() async {
    if (_isDisposed || _intentionalDisconnect || isConnected) return;

    debugPrint('Attempting to reconnect...');
    await _establishConnection();
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    final pingInterval = NetworkConfig.getWebSocketPingInterval();
    _pingTimer = Timer.periodic(pingInterval, (_) {
      if (isConnected) {
        sendMessage({'type': 'ping'});
      }
    });
  }

  void sendMessage(Map<String, dynamic> message) {
    if (!isConnected) {
      debugPrint('Cannot send message: WebSocket not connected');
      return;
    }

    try {
      final encoded = jsonEncode(message);
      _channel!.sink.add(encoded);
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  void sendAction(String action, {Map<String, dynamic>? data}) {
    sendMessage({'type': 'action', 'action': action, 'data': data ?? {}});
  }

  void configureForBatteryLevel(int batteryLevel) {
    if (batteryLevel < 20) {
      // Low battery mode
      _updateInterval = const Duration(seconds: 5);
      _compressionEnabled = true;
      _reducedQuality = true;
    } else if (batteryLevel < 50) {
      // Power saving mode
      _updateInterval = const Duration(seconds: 2);
      _compressionEnabled = true;
      _reducedQuality = false;
    } else {
      // Normal mode
      _updateInterval = const Duration(milliseconds: 500);
      _compressionEnabled = false;
      _reducedQuality = false;
    }

    debugPrint(
      'Configured for battery level $batteryLevel%: '
      'interval=${_updateInterval.inMilliseconds}ms, '
      'compression=$_compressionEnabled, '
      'reduced=$_reducedQuality',
    );
  }

  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _statusController.add(ConnectionStatus.disconnected);
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _connectivitySubscription.cancel();
    _updateController.close();
    _statusController.close();
  }
}

enum ConnectionStatus { connecting, connected, disconnected, error }
