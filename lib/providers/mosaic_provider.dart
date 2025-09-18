import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/mosaic.dart';
import '../core/services/mosaic_service.dart';

// Service provider
final mosaicServiceProvider = Provider<MosaicService>((ref) {
  return MosaicService();
});

// State for all mosaics
final mosaicsProvider = FutureProvider<List<Mosaic>>((ref) async {
  final service = ref.watch(mosaicServiceProvider);
  return service.getMosaics();
});

// State for filtered mosaics
final liveMosaicsProvider = Provider<List<Mosaic>>((ref) {
  final mosaicsAsync = ref.watch(mosaicsProvider);
  return mosaicsAsync.whenOrNull(
        data: (mosaics) => mosaics.where((m) => m.isLive).toList(),
      ) ??
      [];
});

final upcomingMosaicsProvider = Provider<List<Mosaic>>((ref) {
  final mosaicsAsync = ref.watch(mosaicsProvider);
  return mosaicsAsync.whenOrNull(
        data: (mosaics) => mosaics.where((m) => m.isUpcoming).toList(),
      ) ??
      [];
});

// State for a single mosaic
final singleMosaicProvider = FutureProvider.family<Mosaic, String>((
  ref,
  mosaicId,
) async {
  final service = ref.watch(mosaicServiceProvider);
  return service.getMosaic(mosaicId);
});

// State for mosaic grid
final mosaicGridProvider = FutureProvider.family<List<List<int>>, String>((
  ref,
  mosaicId,
) async {
  final service = ref.watch(mosaicServiceProvider);
  return service.getMosaicGrid(mosaicId);
});

// Notifier for managing mosaic actions
class MosaicActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final MosaicService _service;
  final Ref _ref;

  MosaicActionsNotifier(this._service, this._ref)
    : super(const AsyncValue.data(null));

  Future<void> createMosaic({
    String? name,
    String? description,
    int gridSize = 50,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.createMosaic(
        name: name,
        description: description,
        gridSize: gridSize,
      );
      // Refresh the mosaics list
      _ref.invalidate(mosaicsProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> startSimulation(String mosaicId) async {
    state = const AsyncValue.loading();
    try {
      await _service.startSimulation(mosaicId);
      // Refresh the specific mosaic
      _ref.invalidate(singleMosaicProvider(mosaicId));
      _ref.invalidate(mosaicsProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> stopSimulation(String mosaicId) async {
    state = const AsyncValue.loading();
    try {
      await _service.stopSimulation(mosaicId);
      // Refresh the specific mosaic
      _ref.invalidate(singleMosaicProvider(mosaicId));
      _ref.invalidate(mosaicsProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final mosaicActionsProvider =
    StateNotifierProvider<MosaicActionsNotifier, AsyncValue<void>>((ref) {
      final service = ref.watch(mosaicServiceProvider);
      return MosaicActionsNotifier(service, ref);
    });

// Flag to disable auto-refresh in tests
bool _enableAutoRefresh = true;

// Method to control auto-refresh for testing
void setAutoRefreshEnabled(bool enabled) {
  _enableAutoRefresh = enabled;
}

// Auto-refresh provider for real-time updates
final mosaicRefreshProvider = StreamProvider.autoDispose<void>((ref) async* {
  if (!_enableAutoRefresh) {
    // In test mode, return a single value and complete
    yield null;
    return;
  }

  while (true) {
    await Future.delayed(const Duration(seconds: 2));
    ref.invalidate(mosaicsProvider);
    yield null;
  }
});
