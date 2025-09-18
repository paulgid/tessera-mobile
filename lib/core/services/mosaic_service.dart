import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mosaic.dart';
import '../config/network_config.dart';

class MosaicService {
  final String baseUrl;
  final http.Client _client;

  MosaicService({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? NetworkConfig.apiBaseUrl,
      _client = client ?? http.Client();

  /// Fetch all mosaics from the backend
  Future<List<Mosaic>> getMosaics() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/mosaics'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Mosaic.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load mosaics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  /// Fetch a specific mosaic by ID
  Future<Mosaic> getMosaic(String mosaicId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/mosaics/$mosaicId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return Mosaic.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Mosaic not found');
      } else {
        throw Exception('Failed to load mosaic: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  /// Create a new mosaic
  Future<Mosaic> createMosaic({
    String? name,
    String? description,
    int gridSize = 50,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/mosaics'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'width': gridSize,
          'height': gridSize,
          'maxTeams': 4,
          'name': name,
          'description': description,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Backend returns creation info, not full mosaic
        final data = json.decode(response.body);
        final mosaicId = data['mosaicId'] as String;

        // Fetch the created mosaic
        return getMosaic(mosaicId);
      } else {
        throw Exception('Failed to create mosaic: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  /// Start a mosaic simulation
  Future<void> startSimulation(String mosaicId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/mosaics/$mosaicId/start'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to start simulation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  /// Stop a mosaic simulation
  Future<void> stopSimulation(String mosaicId) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/mosaics/$mosaicId/stop'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to stop simulation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  /// Get mosaic grid data
  Future<List<List<int>>> getMosaicGrid(String mosaicId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/mosaics/$mosaicId/grid'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> grid = data['grid'] ?? [];
        return grid.map((row) => List<int>.from(row)).toList();
      } else {
        throw Exception('Failed to load grid: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
