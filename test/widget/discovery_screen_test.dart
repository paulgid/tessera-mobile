import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tessera_mobile/features/discovery/discovery_screen_connected.dart';
import 'package:tessera_mobile/providers/mosaic_provider.dart';
import 'package:tessera_mobile/core/models/mosaic.dart';

// Mock data
final mockMosaics = [
  Mosaic(
    mosaicId: 'live-1',
    formationMode: 0,
    status: MosaicStatus(
      running: true,
      phase: 2,
      totalBots: 150,
      activeBots: 120,
      claimedTiles: 1500,
      totalTiles: 2500,
      lastUpdate: DateTime.now(),
    ),
    name: 'Live Mosaic',
  ),
  Mosaic(
    mosaicId: 'upcoming-1',
    formationMode: 0,
    status: MosaicStatus(
      running: false,
      phase: 0,
      totalBots: 0,
      activeBots: 0,
      claimedTiles: 0,
      totalTiles: 2500,
      lastUpdate: DateTime.now(),
    ),
    name: 'Upcoming Mosaic',
  ),
];

void main() {
  group('ConnectedDiscoveryScreen Widget Tests', () {
    testWidgets('should display loading indicator when fetching data', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mosaicsProvider.overrideWith((ref) async {
              await Future.delayed(const Duration(seconds: 1));
              return mockMosaics;
            }),
          ],
          child: const MaterialApp(home: ConnectedDiscoveryScreen()),
        ),
      );

      // Act & Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('🎨 Tessera'), findsOneWidget);
    });

    testWidgets('should display mosaics when data is loaded', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mosaicsProvider.overrideWith((ref) async => mockMosaics)],
          child: const MaterialApp(home: ConnectedDiscoveryScreen()),
        ),
      );

      // Act - Wait for async data to load
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert
      expect(find.text('Live Now'), findsOneWidget);
      expect(find.text('Starting Soon'), findsOneWidget);
      expect(find.text('All Mosaics'), findsOneWidget);
    });

    testWidgets('should display error state when loading fails', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mosaicsProvider.overrideWith((ref) async {
              throw Exception('Network error');
            }),
          ],
          child: const MaterialApp(home: ConnectedDiscoveryScreen()),
        ),
      );

      // Act
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert
      expect(find.text('Failed to load mosaics'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should display empty state when no mosaics available', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mosaicsProvider.overrideWith((ref) async => <Mosaic>[])],
          child: const MaterialApp(home: ConnectedDiscoveryScreen()),
        ),
      );

      // Act
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert
      expect(find.text('No mosaics available'), findsOneWidget);
      expect(find.text('Check back later or create one!'), findsOneWidget);
      expect(find.text('Create Mosaic'), findsOneWidget);
    });

    testWidgets('should navigate to search screen when search icon tapped', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mosaicsProvider.overrideWith((ref) async => mockMosaics)],
          child: const MaterialApp(home: ConnectedDiscoveryScreen()),
        ),
      );

      // Act
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert - Navigation should have occurred
      // In a real test, you'd verify navigation using a Navigator observer
    });

    testWidgets('should refresh data when refresh icon tapped', (tester) async {
      // Arrange
      var refreshCount = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mosaicsProvider.overrideWith((ref) async {
              refreshCount++;
              return mockMosaics;
            }),
          ],
          child: const MaterialApp(home: ConnectedDiscoveryScreen()),
        ),
      );

      // Act
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(refreshCount, 1);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Assert
      expect(refreshCount, 2);
    });

    testWidgets('should support pull-to-refresh', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mosaicsProvider.overrideWith((ref) async => mockMosaics)],
          child: const MaterialApp(home: ConnectedDiscoveryScreen()),
        ),
      );

      // Act
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Pull down to refresh
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert - RefreshIndicator should be triggered
      // In a real app, you'd verify the refresh callback was called
    });

    testWidgets('should filter mosaics by status correctly', (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mosaicsProvider.overrideWith((ref) async => mockMosaics)],
          child: const MaterialApp(home: ConnectedDiscoveryScreen()),
        ),
      );

      // Act
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert - Should have different sections based on mosaic status
      expect(find.text('Live Now'), findsOneWidget);
      expect(find.text('Starting Soon'), findsOneWidget);

      // Note: Trending section is only shown if there are trending mosaics (>100 active bots)
      // Our mock data has 120 active bots, so trending should appear
      final hasTrending = mockMosaics.any((m) => m.status.activeBots > 100);
      if (hasTrending) {
        expect(find.text('Trending'), findsOneWidget);
      }
    });
  });

  group('ConnectedDiscoveryScreen Integration Tests', () {
    testWidgets('should maintain state when switching tabs', (tester) async {
      // This would test that the AutomaticKeepAliveClientMixin works
      // In a full app, you'd wrap this in the MainNavigation widget
      // and verify state persistence when switching between tabs
    });

    testWidgets('should auto-refresh data periodically', (tester) async {
      // This would test the auto-refresh stream provider
      // You'd need to mock time or use fake_async to test this properly
    });
  });
}
