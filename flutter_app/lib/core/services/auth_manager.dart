import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthManager {
  static final AuthManager _instance = AuthManager._internal();

  factory AuthManager() => _instance;

  AuthManager._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // ===========================================================================
  // TOKEN
  // ===========================================================================

  Future<void> saveToken(String token) async {
    final cleanToken = token.trim();

    if (cleanToken.isEmpty) {
      throw Exception('Cannot save an empty authentication token');
    }

    await _storage.write(
      key: _tokenKey,
      value: cleanToken,
    );

    print(
      '[AuthManager] Token saved. Length: ${cleanToken.length}',
    );
  }

  Future<String?> getToken() async {
    try {
      final token = await _storage.read(
        key: _tokenKey,
      );

      if (token == null || token.trim().isEmpty) {
        print('[AuthManager] No saved token');
        return null;
      }

      print(
        '[AuthManager] Saved token found. Length: ${token.length}',
      );

      return token;
    } catch (e) {
      print(
        '[AuthManager] Error reading token: $e',
      );

      return null;
    }
  }

  Future<bool> hasToken() async {
    final token = await getToken();

    return token != null &&
        token.trim().isNotEmpty;
  }

  Future<void> deleteToken() async {
    await _storage.delete(
      key: _tokenKey,
    );

    print('[AuthManager] Token deleted');
  }

  // ===========================================================================
  // USER
  // ===========================================================================

  Future<void> saveUser(
    Map<String, dynamic> user,
  ) async {
    await _storage.write(
      key: _userKey,
      value: jsonEncode(user),
    );

    print('[AuthManager] User data saved');
  }

  Future<Map<String, dynamic>?> getUser() async {
    try {
      final data = await _storage.read(
        key: _userKey,
      );

      if (data == null || data.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(data);

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }

      return null;
    } catch (e) {
      print(
        '[AuthManager] Error reading user: $e',
      );

      return null;
    }
  }

  Future<void> deleteUser() async {
    await _storage.delete(
      key: _userKey,
    );

    print('[AuthManager] User data deleted');
  }

  // ===========================================================================
  // CLEAR SESSION
  // ===========================================================================

  Future<void> clearToken() async {
    await _storage.delete(
      key: _tokenKey,
    );

    await _storage.delete(
      key: _userKey,
    );

    print('[AuthManager] Session cleared');
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();

    print('[AuthManager] Secure storage completely cleared');
  }
}