import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/game_update.dart';
import '../core/models/tile.dart';
import '../core/models/team.dart';
import '../core/network/websocket_manager.dart';
import '../core/network/api_client.dart';

// Connection status provider
final connectionStatusProvider = StateProvider<ConnectionStatus>((ref) {
  return ConnectionStatus.disconnected;
});

// Game state model
class GameState {
  final String mosaicId;
  final Map<String, Tile> tiles;
  final List<Team> teams;
  final GamePhase phase;
  final GameMetrics? metrics;
  final ConnectionStatus connectionStatus;
  final int mosaicWidth;
  final int mosaicHeight;

  GameState({
    this.mosaicId = '',
    Map<String, Tile>? tiles,
    List<Team>? teams,
    this.phase = GamePhase.idle,
    this.metrics,
    this.connectionStatus = ConnectionStatus.disconnected,
    this.mosaicWidth = 100,
    this.mosaicHeight = 100,
  }) : tiles = tiles ?? {},
       teams = teams ?? [];

  GameState copyWith({
    String? mosaicId,
    Map<String, Tile>? tiles,
    List<Team>? teams,
    GamePhase? phase,
    GameMetrics? metrics,
    ConnectionStatus? connectionStatus,
    int? mosaicWidth,
    int? mosaicHeight,
  }) {
    return GameState(
      mosaicId: mosaicId ?? this.mosaicId,
      tiles: tiles ?? this.tiles,
      teams: teams ?? this.teams,
      phase: phase ?? this.phase,
      metrics: metrics ?? this.metrics,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      mosaicWidth: mosaicWidth ?? this.mosaicWidth,
      mosaicHeight: mosaicHeight ?? this.mosaicHeight,
    );
  }
}

// Helper function to get team color
Color _getTeamColor(int teamId) {
  switch (teamId) {
    case 1:
      return const Color(0xFFFF6B6B); // Red
    case 2:
      return const Color(0xFF4ECDC4); // Blue
    case 3:
      return const Color(0xFF95E77E); // Green
    case 4:
      return const Color(0xFFFFE66D); // Yellow
    default:
      return Colors.grey;
  }
}

// Game state notifier
class GameNotifier extends StateNotifier<GameState> {
  final WebSocketManager _wsManager;
  final ApiClient _apiClient;
  StreamSubscription<GameUpdate>? _updateSubscription;
  StreamSubscription<ConnectionStatus>? _statusSubscription;

  GameNotifier(this._wsManager, this._apiClient) : super(GameState()) {
    _setupListeners();
  }

  void _setupListeners() {
    _statusSubscription = _wsManager.status.listen((status) {
      state = state.copyWith(connectionStatus: status);
    });

    _updateSubscription = _wsManager.updates.listen((update) {
      _handleGameUpdate(update);
    });
  }

  void _handleGameUpdate(GameUpdate update) {
    switch (update.type) {
      case 'tile_update':
      case 'tiles':
        if (update.tiles != null) {
          final updatedTiles = Map<String, Tile>.from(state.tiles);
          for (final tile in update.tiles!) {
            updatedTiles['${tile.x},${tile.y}'] = tile;
          }
          state = state.copyWith(tiles: updatedTiles);
        }
        break;

      case 'phase_change':
        if (update.phase != null) {
          state = state.copyWith(phase: update.phase);
        }
        break;

      case 'metrics':
        if (update.metrics != null) {
          // Update teams from metrics
          final teams = update.metrics!.teamTiles.entries
              .map(
                (entry) => Team(
                  id: entry.key,
                  name: 'Team ${entry.key}',
                  color: _getTeamColor(entry.key),
                  tileCount: entry.value,
                  percentage:
                      (entry.value / (state.mosaicWidth * state.mosaicHeight)) *
                      100,
                ),
              )
              .toList();

          state = state.copyWith(metrics: update.metrics, teams: teams);
        }
        break;

      case 'game_complete':
        state = state.copyWith(
          phase: GamePhase.complete,
          metrics: update.metrics,
        );
        break;

      case 'full_state':
        // Handle full state update
        if (update.data != null) {
          _handleFullState(update.data as Map<String, dynamic>);
        }
        break;
    }
  }

  void _handleFullState(Map<String, dynamic> data) {
    final tiles = <String, Tile>{};

    if (data['tiles'] != null) {
      for (final tileData in data['tiles']) {
        final tile = Tile.fromJson(tileData);
        tiles['${tile.x},${tile.y}'] = tile;
      }
    }

    state = state.copyWith(
      tiles: tiles,
      mosaicWidth: data['width'] ?? 100,
      mosaicHeight: data['height'] ?? 100,
    );
  }

  Future<void> connectToMosaic(String mosaicId) async {
    state = state.copyWith(mosaicId: mosaicId);

    // Load initial mosaic data
    try {
      final mosaicData = await _apiClient.getMosaic(mosaicId);

      // Initialize tiles from mosaic data
      final tiles = <String, Tile>{};
      final width = mosaicData['width'] ?? 100;
      final height = mosaicData['height'] ?? 100;

      // Create empty tiles initially
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          tiles['$x,$y'] = Tile(x: x, y: y);
        }
      }

      state = state.copyWith(
        tiles: tiles,
        mosaicWidth: width,
        mosaicHeight: height,
      );
    } catch (e) {
      debugPrint('Error loading mosaic: $e');
    }

    // Connect WebSocket
    await _wsManager.connect(mosaicId);
  }

  void disconnect() {
    _wsManager.disconnect();
  }

  Future<void> claimTile(int x, int y, String userId) async {
    try {
      await _apiClient.claimTile(
        mosaicId: state.mosaicId,
        x: x,
        y: y,
        userId: userId,
      );
    } catch (e) {
      debugPrint('Error claiming tile: $e');
    }
  }

  Future<void> placeTile(int x, int y, int teamId) async {
    try {
      await _apiClient.placeTile(
        mosaicId: state.mosaicId,
        x: x,
        y: y,
        teamId: teamId,
      );
    } catch (e) {
      debugPrint('Error placing tile: $e');
    }
  }

  @override
  void dispose() {
    _updateSubscription?.cancel();
    _statusSubscription?.cancel();
    _wsManager.dispose();
    super.dispose();
  }
}

// Providers
final webSocketManagerProvider = Provider<WebSocketManager>((ref) {
  return WebSocketManager();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  final wsManager = ref.watch(webSocketManagerProvider);
  final apiClient = ref.watch(apiClientProvider);
  return GameNotifier(wsManager, apiClient);
});
