import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/network_config.dart';

class ApiClient {
  late final Dio _dio;
  final String baseUrl;

  ApiClient({String? baseUrl})
    : baseUrl = baseUrl ?? NetworkConfig.getBaseUrl() {
    _dio = Dio(
      BaseOptions(
        baseUrl: this.baseUrl,
        connectTimeout: NetworkConfig.getConnectionTimeout(),
        receiveTimeout: NetworkConfig.getReceiveTimeout(),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  // Mosaic endpoints
  Future<Map<String, dynamic>> createMosaic({
    required String name,
    int width = 100,
    int height = 100,
  }) async {
    try {
      final response = await _dio.post(
        '/api/mosaics',
        data: {'name': name, 'width': width, 'height': height},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMosaic(String mosaicId) async {
    try {
      final response = await _dio.get('/api/mosaics/$mosaicId');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMosaicData(String mosaicId) async {
    try {
      // Fetch the actual mosaic tile data
      final response = await _dio.get('/api/mosaics/$mosaicId/mosaic');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> listMosaics() async {
    try {
      final response = await _dio.get('/api/mosaics');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Action endpoints
  Future<Map<String, dynamic>> claimTile({
    required String mosaicId,
    required int x,
    required int y,
    required String userId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/mosaics/$mosaicId/claim',
        data: {'x': x, 'y': y, 'user_id': userId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> placeTile({
    required String mosaicId,
    required int x,
    required int y,
    required int teamId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/mosaics/$mosaicId/actions',
        data: {'x': x, 'y': y, 'team_id': teamId},
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Simulation control
  Future<void> startSimulation(String mosaicId) async {
    try {
      await _dio.post('/api/mosaics/$mosaicId/simulation/start');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> stopSimulation(String mosaicId) async {
    try {
      await _dio.post('/api/mosaics/$mosaicId/simulation/stop');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> resetSimulation(String mosaicId) async {
    try {
      await _dio.post('/api/mosaics/$mosaicId/simulation/reset');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Teams and images
  Future<void> uploadTeamImage({
    required String mosaicId,
    required int teamId,
    required Uint8List imageData,
  }) async {
    try {
      final formData = FormData.fromMap({
        'team_id': teamId,
        'image': MultipartFile.fromBytes(
          imageData,
          filename: 'team_$teamId.png',
        ),
      });

      await _dio.post(
        '/api/mosaics/$mosaicId/images',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getTeams(String mosaicId) async {
    try {
      final response = await _dio.get('/api/mosaics/$mosaicId/teams');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Health check
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final message = error.response!.data['error'] ?? 'Unknown error';

      switch (statusCode) {
        case 400:
          return BadRequestException(message);
        case 401:
          return UnauthorizedException(message);
        case 404:
          return NotFoundException(message);
        case 500:
          return ServerException(message);
        default:
          return ApiException('Error $statusCode: $message');
      }
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return ApiException('Connection timeout');
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return ApiException('Receive timeout');
    } else {
      return ApiException('Network error: ${error.message}');
    }
  }
}

// Custom exceptions
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class BadRequestException extends ApiException {
  BadRequestException(super.message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

class ServerException extends ApiException {
  ServerException(super.message);
}
