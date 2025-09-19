import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/websocket_service.dart';

/// Provider for WebSocket service
final webSocketServiceProvider = Provider.autoDispose<WebSocketService>((ref) {
  final service = WebSocketService();

  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for WebSocket connection state
final webSocketConnectionProvider = StreamProvider.autoDispose<ConnectionState>(
  (ref) {
    final service = ref.watch(webSocketServiceProvider);
    return service.connectionState;
  },
);

/// Provider for real-time mosaic updates
final mosaicUpdatesProvider = StreamProvider.autoDispose<MosaicUpdate>((ref) {
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
    // Don't set up listeners in constructor to avoid StateNotifier exception
  }

  // Method removed - was unused and causing lint warning
  // Updates are now handled directly in the mosaic viewer

  void connectToMosaic(String mosaicId) {
    final service = ref.read(webSocketServiceProvider);
    service.connect(mosaicId: mosaicId);
    state = state.copyWith(currentMosaicId: mosaicId);
  }

  void disconnect() {
    try {
      final service = ref.read(webSocketServiceProvider);
      service.disconnect();
    } catch (_) {
      // Provider might already be disposed
    }
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

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// Provider for WebSocket state notifier
final webSocketNotifierProvider =
    StateNotifierProvider.autoDispose<WebSocketNotifier, WebSocketState>((ref) {
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
