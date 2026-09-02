import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'auth_manager.dart';

class CVService {
  final AuthManager _authManager = AuthManager();

  Future<String?> _token() async {
    return await _authManager.getToken();
  }

  Future<Map<String, String>> _jsonHeaders() async {
    final token = await _token();

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _token();

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  // Existing JSON-only endpoint.
  Future<Map<String, dynamic>> analyze({
    required Map<String, dynamic> features,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/cv/analyze'),
      headers: await _jsonHeaders(),
      body: jsonEncode(features),
    );

    return _decode(response);
  }

  // New multipart endpoint.
  // Sends the exact camera JPEG used for server-side stress inference,
  // together with the locally extracted ML Kit feature payload.
  Future<Map<String, dynamic>> analyzeWithImage({
    required Map<String, dynamic> features,
    required String imagePath,
  }) async {
    final file = File(imagePath);

    if (!await file.exists()) {
      throw Exception('Captured image file was not found.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/cv/analyze-image'),
    );

    request.headers.addAll(await _authHeaders());
    request.fields['features'] = jsonEncode(features);
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imagePath,
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    return _decode(response);
  }

  Future<Map<String, dynamic>> getLatest() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/cv/latest'),
      headers: await _jsonHeaders(),
    );

    return _decode(response);
  }

  // This is the payload you can feed into the AI chatbot as supporting context.
  Future<Map<String, dynamic>> getLatestChatContext() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/cv/latest/chat-context'),
      headers: await _jsonHeaders(),
    );

    return _decode(response);
  }

  Future<Map<String, dynamic>> getHistory({
    int limit = 30,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/cv/history?limit=$limit'),
      headers: await _jsonHeaders(),
    );

    return _decode(response);
  }

  Future<Map<String, dynamic>> getSummary() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/cv/summary'),
      headers: await _jsonHeaders(),
    );

    return _decode(response);
  }

  Future<Map<String, dynamic>> getTrends({
    int limit = 30,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/cv/trends?limit=$limit'),
      headers: await _jsonHeaders(),
    );

    return _decode(response);
  }

  Future<Map<String, dynamic>> getById(String id) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/cv/$id'),
      headers: await _jsonHeaders(),
    );

    return _decode(response);
  }

  Future<Map<String, dynamic>> delete(String id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/cv/$id'),
      headers: await _jsonHeaders(),
    );

    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
        'CV request failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{'data': decoded};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data['message'] ?? data['detail'] ?? 'CV request failed',
    );
  }
}
