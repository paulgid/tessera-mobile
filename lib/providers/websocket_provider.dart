import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/websocket_service.dart';
import 'mosaic_provider.dart';

/// Provider for WebSocket service
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();

  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for WebSocket connection state
final webSocketConnectionProvider = StreamProvider<ConnectionState>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.connectionState;
});

/// Provider for real-time mosaic updates
final mosaicUpdatesProvider = StreamProvider<MosaicUpdate>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.mosaicUpdates;
});

/// Connect to WebSocket for a specific mosaic
final connectToMosaicProvider = Provider.family<void, String>((ref, mosaicId) {
  final service = ref.watch(webSocketServiceProvider);
  service.connect(mosaicId: mosaicId);
});

/// Notifier for managing WebSocket connection
class WebSocketNotifier extends StateNotifier<WebSocketState> {
  final Ref ref;

  WebSocketNotifier(this.ref) : super(const WebSocketState()) {
    // Listen to connection state changes
    ref.listen(webSocketConnectionProvider, (previous, next) {
      next.whenData((connectionState) {
        state = state.copyWith(connectionState: connectionState);
      });
    });

    // Listen to mosaic updates and update local state
    ref.listen(mosaicUpdatesProvider, (previous, next) {
      next.whenData((update) {
        _handleMosaicUpdate(update);
      });
    });
  }

  void _handleMosaicUpdate(MosaicUpdate update) {
    // Update the mosaic list when we receive updates
    switch (update.type) {
      case UpdateType.statusUpdate:
        if (update.status != null) {
          // Invalidate mosaic provider to refetch
          ref.invalidate(mosaicsProvider);
        }
        break;
      case UpdateType.tileUpdate:
        // Handle tile updates for mosaic viewer
        state = state.copyWith(
          lastTileUpdate: update.tileUpdate,
          lastUpdateTime: DateTime.now(),
        );
        break;
      case UpdateType.phaseChange:
        // Handle phase changes
        state = state.copyWith(currentPhase: update.newPhase);
        // Invalidate to refetch
        ref.invalidate(mosaicsProvider);
        break;
      case UpdateType.gameEnd:
        // Handle game end
        state = state.copyWith(
          gameEnded: true,
          winningTeam: update.winningTeam,
        );
        break;
    }
  }

  void connectToMosaic(String mosaicId) {
    final service = ref.read(webSocketServiceProvider);
    service.connect(mosaicId: mosaicId);
    state = state.copyWith(currentMosaicId: mosaicId);
  }

  void disconnect() {
    final service = ref.read(webSocketServiceProvider);
    service.disconnect();
    state = const WebSocketState();
  }

  void subscribeTo(String mosaicId) {
    final service = ref.read(webSocketServiceProvider);
    service.subscribeTo(mosaicId);
    state = state.copyWith(currentMosaicId: mosaicId);
  }

  void unsubscribe() {
    final service = ref.read(webSocketServiceProvider);
    service.unsubscribe();
    state = state.copyWith(currentMosaicId: null);
  }
}

/// Provider for WebSocket state notifier
final webSocketNotifierProvider =
    StateNotifierProvider<WebSocketNotifier, WebSocketState>((ref) {
      return WebSocketNotifier(ref);
    });

/// State for WebSocket connection
class WebSocketState {
  final ConnectionState connectionState;
  final String? currentMosaicId;
  final TileUpdate? lastTileUpdate;
  final DateTime? lastUpdateTime;
  final int? currentPhase;
  final bool gameEnded;
  final int? winningTeam;

  const WebSocketState({
    this.connectionState = ConnectionState.disconnected,
    this.currentMosaicId,
    this.lastTileUpdate,
    this.lastUpdateTime,
    this.currentPhase,
    this.gameEnded = false,
    this.winningTeam,
  });

  WebSocketState copyWith({
    ConnectionState? connectionState,
    String? currentMosaicId,
    TileUpdate? lastTileUpdate,
    DateTime? lastUpdateTime,
    int? currentPhase,
    bool? gameEnded,
    int? winningTeam,
  }) {
    return WebSocketState(
      connectionState: connectionState ?? this.connectionState,
      currentMosaicId: currentMosaicId ?? this.currentMosaicId,
      lastTileUpdate: lastTileUpdate ?? this.lastTileUpdate,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      currentPhase: currentPhase ?? this.currentPhase,
      gameEnded: gameEnded ?? this.gameEnded,
      winningTeam: winningTeam ?? this.winningTeam,
    );
  }
}
