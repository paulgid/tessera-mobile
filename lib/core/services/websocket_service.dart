import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../config/network_config.dart';
import '../models/mosaic.dart';

/// Service for managing WebSocket connection to backend
class WebSocketService {
  WebSocketChannel? _channel;
  final _mosaicStreamController = StreamController<MosaicUpdate>.broadcast();
  final _connectionStateController =
      StreamController<ConnectionState>.broadcast();

  Timer? _reconnectTimer;
  Timer? _pingTimer;

  String? _currentMosaicId;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Streams
  Stream<MosaicUpdate> get mosaicUpdates => _mosaicStreamController.stream;
  Stream<ConnectionState> get connectionState =>
      _connectionStateController.stream;

  /// Connect to WebSocket server
  Future<void> connect({String? mosaicId}) async {
    _currentMosaicId = mosaicId;
    _reconnectAttempts = 0;
    await _connectInternal();
  }

  Future<void> _connectInternal() async {
    try {
      // Close existing connection if any
      await disconnect();

      // Build WebSocket URL
      final wsUrl = NetworkConfig.wsUrl;
      final uri = Uri.parse(wsUrl);

      // Emit connecting state
      _connectionStateController.add(ConnectionState.connecting);

      // Create WebSocket channel
      _channel = WebSocketChannel.connect(uri);

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
        cancelOnError: false,
      );

      // Send initial subscription if mosaic ID provided
      if (_currentMosaicId != null) {
        subscribeTo(_currentMosaicId!);
      }

      // Start ping timer to keep connection alive
      _startPingTimer();

      // Emit connected state
      _connectionStateController.add(ConnectionState.connected);
      _reconnectAttempts = 0;
    } catch (e) {
      print('WebSocket connection error: $e');
      _connectionStateController.add(ConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  /// Subscribe to a specific mosaic
  void subscribeTo(String mosaicId) {
    _currentMosaicId = mosaicId;
    if (_channel != null) {
      final message = json.encode({'type': 'subscribe', 'mosaicId': mosaicId});
      _channel!.sink.add(message);
    }
  }

  /// Unsubscribe from current mosaic
  void unsubscribe() {
    if (_channel != null && _currentMosaicId != null) {
      final message = json.encode({
        'type': 'unsubscribe',
        'mosaicId': _currentMosaicId,
      });
      _channel!.sink.add(message);
      _currentMosaicId = null;
    }
  }

  /// Send action to server
  void sendAction(Map<String, dynamic> action) {
    if (_channel != null) {
      final message = json.encode({'type': 'action', 'data': action});
      _channel!.sink.add(message);
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message);

      switch (data['type']) {
        case 'update':
          _handleMosaicUpdate(data);
          break;
        case 'tile_update':
          _handleTileUpdate(data);
          break;
        case 'phase_change':
          _handlePhaseChange(data);
          break;
        case 'game_end':
          _handleGameEnd(data);
          break;
        case 'error':
          print('WebSocket error: ${data['message']}');
          break;
        case 'pong':
          // Pong received, connection is alive
          break;
        default:
          print('Unknown message type: ${data['type']}');
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  void _handleMosaicUpdate(Map<String, dynamic> data) {
    _mosaicStreamController.add(
      MosaicUpdate(
        type: UpdateType.statusUpdate,
        mosaicId: data['mosaicId'],
        status: MosaicStatus.fromJson(data['status']),
      ),
    );
  }

  void _handleTileUpdate(Map<String, dynamic> data) {
    _mosaicStreamController.add(
      MosaicUpdate(
        type: UpdateType.tileUpdate,
        mosaicId: data['mosaicId'],
        tileUpdate: TileUpdate(
          x: data['x'],
          y: data['y'],
          teamId: data['teamId'],
          isClaimed: data['is_claimed'] ?? false,
          claimIntensity: (data['claim_intensity'] ?? 0.0).toDouble(),
        ),
      ),
    );
  }

  void _handlePhaseChange(Map<String, dynamic> data) {
    _mosaicStreamController.add(
      MosaicUpdate(
        type: UpdateType.phaseChange,
        mosaicId: data['mosaicId'],
        newPhase: data['phase'],
      ),
    );
  }

  void _handleGameEnd(Map<String, dynamic> data) {
    _mosaicStreamController.add(
      MosaicUpdate(
        type: UpdateType.gameEnd,
        mosaicId: data['mosaicId'],
        winningTeam: data['winner'],
      ),
    );
  }

  void _handleError(error) {
    print('WebSocket error: $error');
    _connectionStateController.add(ConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _handleDone() {
    print('WebSocket connection closed');
    _connectionStateController.add(ConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnection attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    final delay = NetworkConfig.getReconnectDelay(_reconnectAttempts);
    _reconnectAttempts++;

    print(
      'Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s',
    );
    _reconnectTimer = Timer(delay, () {
      _connectInternal();
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    final pingInterval = NetworkConfig.getWebSocketPingInterval();

    _pingTimer = Timer.periodic(pingInterval, (_) {
      if (_channel != null) {
        _channel!.sink.add(json.encode({'type': 'ping'}));
      }
    });
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();

    if (_channel != null) {
      await _channel!.sink.close(status.normalClosure);
      _channel = null;
    }

    _connectionStateController.add(ConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _mosaicStreamController.close();
    _connectionStateController.close();
  }
}

/// Connection states
enum ConnectionState { disconnected, connecting, connected }

/// Types of updates
enum UpdateType { statusUpdate, tileUpdate, phaseChange, gameEnd }

/// Mosaic update event
class MosaicUpdate {
  final UpdateType type;
  final String mosaicId;
  final MosaicStatus? status;
  final TileUpdate? tileUpdate;
  final int? newPhase;
  final int? winningTeam;

  MosaicUpdate({
    required this.type,
    required this.mosaicId,
    this.status,
    this.tileUpdate,
    this.newPhase,
    this.winningTeam,
  });
}

/// Tile update data
class TileUpdate {
  final int x;
  final int y;
  final int teamId;
  final bool isClaimed;
  final double claimIntensity;

  TileUpdate({
    required this.x,
    required this.y,
    required this.teamId,
    required this.isClaimed,
    required this.claimIntensity,
  });
}
