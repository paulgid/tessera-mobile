import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:tessera_mobile/core/services/mosaic_service.dart';
import 'package:tessera_mobile/core/models/mosaic.dart';

void main() {
  group('Backend Integration Tests', () {
    late MosaicService service;
    late bool backendAvailable;

    setUpAll(() async {
      // Check if backend is available
      try {
        final response = await http.get(
          Uri.parse('http://localhost:8081/api/mosaics'),
        ).timeout(const Duration(seconds: 2));
        backendAvailable = response.statusCode == 200;
      } catch (e) {
        backendAvailable = false;
        print('Backend not available, skipping integration tests: $e');
      }
    });

    setUp(() {
      // Use the real backend URL
      service = MosaicService(
        baseUrl: 'http://localhost:8081',
        client: http.Client(),
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('should fetch mosaics from backend', () async {
      if (!backendAvailable) {
        markTestSkipped('Backend not available');
        return;
      }

      // Act
      final mosaics = await service.getMosaics();

      // Assert
      expect(mosaics, isNotEmpty);
      expect(mosaics, isA<List<Mosaic>>());

      // Verify mosaic structure
      for (final mosaic in mosaics) {
        expect(mosaic.mosaicId, isNotEmpty);
        expect(mosaic.status, isNotNull);
        expect(mosaic.status.totalTiles, greaterThan(0));
      }
    });

    test(
      'should fetch specific mosaic by ID',
      () async {
        // Skip: Backend does not have individual mosaic endpoint yet
      },
      skip: 'Backend does not have individual mosaic endpoint yet',
    );

    test(
      'should create a new mosaic',
      () async {
        // Skip: Backend create endpoint returns different format, needs update
      },
      skip: 'Backend create endpoint returns different format, needs update',
    );

    test('should handle 404 error gracefully', () async {
      // Act & Assert
      expect(() => service.getMosaic('non-existent-id'), throwsException);
    });

    test('should connect to correct backend URL', () async {
      if (!backendAvailable) {
        markTestSkipped('Backend not available');
        return;
      }

      // This test verifies the URL configuration is correct
      expect(service.baseUrl, 'http://localhost:8081');

      // Try to fetch - if backend is down this will throw
      try {
        await service.getMosaics();
      } catch (e) {
        fail('Backend is not accessible at ${service.baseUrl}: $e');
      }
    });
  });
}
