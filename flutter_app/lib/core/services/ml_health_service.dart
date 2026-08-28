import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

class MlHealthService {
  static final Dio _dio = Dio();

  /// Safely extracts server errors when response data is JSON, text, or empty.
  static String _errorMessage(DioException error, String fallback) {
    final data = error.response?.data;

    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    if (error.message != null && error.message!.trim().isNotEmpty) {
      return error.message!;
    }

    return fallback;
  }

  static Options _options(String token) {
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  // ============================================================
  // GET LATEST ML HEALTH ANALYSIS
  // ============================================================

  static Future<Map<String, dynamic>> getLatestAnalysis({
    required String token,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/v1/ml-health/latest',
        options: _options(token),
      );

      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }

      return {
        'success': false,
        'message': 'Invalid server response',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _errorMessage(e, 'Failed to load latest ML analysis'),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // ============================================================
  // GET ML HISTORY
  // ============================================================

  static Future<Map<String, dynamic>> getHistory({
    required String token,
    int days = 30,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/v1/ml-health/history',
        queryParameters: {
          'days': days,
        },
        options: _options(token),
      );

      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }

      return {
        'success': false,
        'message': 'Invalid server response',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _errorMessage(e, 'Failed to load ML history'),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // ============================================================
  // RUN NEW ANALYSIS
  // ============================================================

  static Future<Map<String, dynamic>> analyze({
    required String token,
    required Map<String, dynamic> profile,
    required List<Map<String, dynamic>> healthRecords,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/v1/ml-health/analyze',
        data: {
          'profile': profile,
          'health_records': healthRecords,
        },
        options: _options(token),
      );

      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }

      return {
        'success': false,
        'message': 'Invalid server response',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _errorMessage(e, 'ML analysis failed'),
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}