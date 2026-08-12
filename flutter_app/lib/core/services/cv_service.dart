import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'auth_manager.dart';

class CVService {
  final AuthManager _authManager =
      AuthManager();

  Future<String?> _token() async {
    return await _authManager.getToken();
  }

  Future<Map<String, String>>
      _headers() async {
    final token = await _token();

    return {
      'Authorization':
          'Bearer $token',
      'Content-Type':
          'application/json',
      'Accept':
          'application/json',
    };
  }

  // ===========================================================================
  // ANALYZE
  // ===========================================================================

  Future<Map<String, dynamic>>
      analyze({
    required Map<String, dynamic>
        features,
  }) async {
    final response =
        await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/cv/analyze',
      ),
      headers:
          await _headers(),
      body: jsonEncode(features),
    );

    return _decode(response);
  }

  // Convenience method used by the camera capture flow.
  // It sends only extracted CV data; the raw camera image is not uploaded.
  Future<Map<String, dynamic>> saveCapture({
    required Map<String, dynamic> features,
  }) async {
    return analyze(features: features);
  }

  // ===========================================================================
  // LATEST
  // ===========================================================================

  Future<Map<String, dynamic>>
      getLatest() async {
    final response =
        await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/cv/latest',
      ),
      headers:
          await _headers(),
    );

    return _decode(response);
  }

  // ===========================================================================
  // HISTORY
  // ===========================================================================

  Future<Map<String, dynamic>>
      getHistory({
    int limit = 30,
  }) async {
    final response =
        await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/cv/history?limit=$limit',
      ),
      headers:
          await _headers(),
    );

    return _decode(response);
  }

  // ===========================================================================
  // SUMMARY
  // ===========================================================================

  Future<Map<String, dynamic>>
      getSummary() async {
    final response =
        await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/cv/summary',
      ),
      headers:
          await _headers(),
    );

    return _decode(response);
  }

  // ===========================================================================
  // TRENDS
  // ===========================================================================

  Future<Map<String, dynamic>>
      getTrends({
    int limit = 30,
  }) async {
    final response =
        await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/cv/trends?limit=$limit',
      ),
      headers:
          await _headers(),
    );

    return _decode(response);
  }

  // ===========================================================================
  // SINGLE ANALYSIS
  // ===========================================================================

  Future<Map<String, dynamic>>
      getById(
    String id,
  ) async {
    final response =
        await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/cv/$id',
      ),
      headers:
          await _headers(),
    );

    return _decode(response);
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  Future<Map<String, dynamic>>
      delete(
    String id,
  ) async {
    final response =
        await http.delete(
      Uri.parse(
        '${ApiConstants.baseUrl}/cv/$id',
      ),
      headers:
          await _headers(),
    );

    return _decode(response);
  }

  // ===========================================================================
  // RESPONSE
  // ===========================================================================

  Map<String, dynamic>
      _decode(
    http.Response response,
  ) {
    final data =
        jsonDecode(response.body);

    if (response.statusCode >=
        200 &&
        response.statusCode < 300) {
      return Map<String, dynamic>
          .from(data);
    }

    throw Exception(
      data['message'] ??
          'CV request failed',
    );
  }
}