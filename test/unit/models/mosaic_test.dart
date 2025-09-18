import 'package:flutter_test/flutter_test.dart';
import 'package:tessera_mobile/core/models/mosaic.dart';

void main() {
  group('Mosaic Model Tests', () {
    test('should create Mosaic from JSON', () {
      // Arrange
      final json = {
        'mosaicId': 'test-123',
        'formation_mode': 1,
        'status': {
          'running': true,
          'phase': 1,
          'total_bots': 100,
          'active_bots': 80,
          'claimed_tiles': 1250,
          'total_tiles': 2500,
          'last_update': '2025-09-18T12:00:00Z',
        },
        'name': 'Test Mosaic',
        'description': 'A test mosaic',
      };

      // Act
      final mosaic = Mosaic.fromJson(json);

      // Assert
      expect(mosaic.mosaicId, 'test-123');
      expect(mosaic.formationMode, 1);
      expect(mosaic.name, 'Test Mosaic');
      expect(mosaic.description, 'A test mosaic');
      expect(mosaic.status.running, true);
      expect(mosaic.status.phase, 1);
      expect(mosaic.status.totalBots, 100);
      expect(mosaic.status.activeBots, 80);
      expect(mosaic.status.claimedTiles, 1250);
      expect(mosaic.status.totalTiles, 2500);
    });

    test('should calculate correct claim progress', () {
      // Arrange
      final status = MosaicStatus(
        running: true,
        phase: 1,
        totalBots: 100,
        activeBots: 80,
        claimedTiles: 1250,
        totalTiles: 2500,
        lastUpdate: DateTime.now(),
      );

      // Act & Assert
      expect(status.claimProgress, 0.5);
      expect(status.progressText, '50.0%');
    });

    test('should handle zero total tiles gracefully', () {
      // Arrange
      final status = MosaicStatus(
        running: true,
        phase: 1,
        totalBots: 0,
        activeBots: 0,
        claimedTiles: 0,
        totalTiles: 0,
        lastUpdate: DateTime.now(),
      );

      // Act & Assert
      expect(status.claimProgress, 0.0);
      expect(status.progressText, '0.0%');
    });

    test('should correctly identify mosaic states', () {
      // Test live mosaic
      final liveMosaic = Mosaic(
        mosaicId: 'live-123',
        formationMode: 0,
        status: MosaicStatus(
          running: true,
          phase: 2,
          totalBots: 100,
          activeBots: 80,
          claimedTiles: 1000,
          totalTiles: 2500,
          lastUpdate: DateTime.now(),
        ),
      );
      expect(liveMosaic.isLive, true);
      expect(liveMosaic.isUpcoming, false);
      expect(liveMosaic.isCompleted, false);

      // Test upcoming mosaic
      final upcomingMosaic = Mosaic(
        mosaicId: 'upcoming-123',
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
      );
      expect(upcomingMosaic.isLive, false);
      expect(upcomingMosaic.isUpcoming, true);
      expect(upcomingMosaic.isCompleted, false);

      // Test completed mosaic
      final completedMosaic = Mosaic(
        mosaicId: 'complete-123',
        formationMode: 0,
        status: MosaicStatus(
          running: false,
          phase: 3,
          totalBots: 100,
          activeBots: 0,
          claimedTiles: 2500,
          totalTiles: 2500,
          lastUpdate: DateTime.now(),
        ),
      );
      expect(completedMosaic.isLive, false);
      expect(completedMosaic.isUpcoming, false);
      expect(completedMosaic.isCompleted, true);
    });

    test('should generate correct phase text', () {
      // Arrange
      final phases = [
        (0, 'Waiting'),
        (1, 'Claim Phase'),
        (2, 'Assembly Phase'),
        (3, 'Complete'),
        (4, 'Unknown'),
      ];

      // Act & Assert
      for (final (phase, expectedText) in phases) {
        final mosaic = Mosaic(
          mosaicId: 'test',
          formationMode: 0,
          status: MosaicStatus(
            running: false,
            phase: phase,
            totalBots: 0,
            activeBots: 0,
            claimedTiles: 0,
            totalTiles: 0,
            lastUpdate: DateTime.now(),
          ),
        );
        expect(mosaic.phaseText, expectedText);
      }
    });

    test('should convert Mosaic to JSON correctly', () {
      // Arrange
      final mosaic = Mosaic(
        mosaicId: 'test-123',
        formationMode: 1,
        status: MosaicStatus(
          running: true,
          phase: 2,
          totalBots: 50,
          activeBots: 30,
          claimedTiles: 500,
          totalTiles: 1000,
          lastUpdate: DateTime.parse('2025-09-18T12:00:00Z'),
        ),
        name: 'Test Mosaic',
        description: 'Test Description',
      );

      // Act
      final json = mosaic.toJson();

      // Assert
      expect(json['mosaicId'], 'test-123');
      expect(json['formation_mode'], 1);
      expect(json['name'], 'Test Mosaic');
      expect(json['description'], 'Test Description');
      expect(json['status']['running'], true);
      expect(json['status']['phase'], 2);
      expect(json['status']['total_bots'], 50);
      expect(json['status']['active_bots'], 30);
      expect(json['status']['claimed_tiles'], 500);
      expect(json['status']['total_tiles'], 1000);
    });

    test('should use default display name when name is null', () {
      // Arrange
      final mosaic = Mosaic(
        mosaicId: 'f755bee7-d06c-45cd-a321-50d436cdb4a3',
        formationMode: 0,
        status: MosaicStatus(
          running: false,
          phase: 0,
          totalBots: 0,
          activeBots: 0,
          claimedTiles: 0,
          totalTiles: 0,
          lastUpdate: DateTime.now(),
        ),
      );

      // Act & Assert
      expect(mosaic.displayName, 'Mosaic f755bee7');
    });
  });
}
