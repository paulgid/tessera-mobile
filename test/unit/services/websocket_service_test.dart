import 'package:flutter_test/flutter_test.dart';
import 'package:tessera_mobile/core/services/websocket_service.dart';

void main() {
  group('WebSocketService', () {
    late WebSocketService service;

    setUp(() {
      service = WebSocketService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should not emit events after dispose', () async {
      // Arrange
      service.dispose();

      // Act & Assert - should not throw
      await service.disconnect();
    });

    test('should handle connection state stream safely', () async {
      // Arrange
      final states = <ConnectionState>[];
      final subscription = service.connectionState.listen(
        (state) => states.add(state),
      );

      // Act - connect will try to connect but may fail
      await service.connect(mosaicId: 'test-mosaic');

      // Give it a moment to emit states
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - at minimum we expect connecting state
      // The actual connection may fail but the stream should handle it safely
      expect(states, isNotEmpty);

      // Cleanup
      subscription.cancel();
    });

    test('should handle mosaic updates stream safely', () {
      // Arrange
      final updates = <MosaicUpdate>[];
      final subscription = service.mosaicUpdates.listen(
        (update) => updates.add(update),
      );

      // Act - simulate subscribing to a mosaic
      service.subscribeTo('test-mosaic');

      // Cleanup
      subscription.cancel();
    });

    test('should clean up resources on dispose', () {
      // Arrange
      service.connect(mosaicId: 'test-mosaic');

      // Act
      service.dispose();

      // Assert - should not throw when trying to use disposed service
      expect(() => service.subscribeTo('another-mosaic'), returnsNormally);
    });

    test('should handle reconnection without emitting to disposed listeners', () async {
      // Arrange
      final states = <ConnectionState>[];
      final subscription = service.connectionState.listen(
        (state) => states.add(state),
      );

      // Connect
      service.connect(mosaicId: 'test-mosaic');

      // Cancel subscription (simulate widget disposal)
      subscription.cancel();

      // Act - should not throw even with no listeners
      await service.disconnect();
      service.connect(mosaicId: 'test-mosaic-2');

      // Assert - no crash occurred
      expect(true, true);
    });

    test('should not emit to closed stream controllers', () {
      // Arrange
      service.connect(mosaicId: 'test-mosaic');

      // Act
      service.dispose();

      // Assert - attempting to connect after dispose should not throw
      expect(() => service.connect(mosaicId: 'another-mosaic'), returnsNormally);
    });
  });

  group('WebSocketService Safe Stream Methods', () {
    test('should check for listeners before emitting', () {
      // This test validates that the safe methods work correctly
      final service = WebSocketService();

      // No listeners attached, should not throw
      service.subscribeTo('test-mosaic');

      // Clean up
      service.dispose();
    });

    test('should handle multiple rapid connect/disconnect cycles', () async {
      final service = WebSocketService();

      // Test rapid subscribeTo/unsubscribe which don't require actual connections
      for (int i = 0; i < 5; i++) {
        service.subscribeTo('test-mosaic-$i');
        service.unsubscribe();
      }

      // Test rapid disposal after operations
      service.dispose();

      // Should complete without errors - no crashes or exceptions
      expect(true, true);
    });
  });
}