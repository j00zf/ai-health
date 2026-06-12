import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
class FitbitService {
  static const String clientId = 'YOUR_FITBIT_CLIENT_ID_HERE';           // ← Replace with your Fitbit Client ID
  static const String clientSecret = 'YOUR_FITBIT_CLIENT_SECRET_HERE';   // ← Replace with your Client Secret

  // Important: Use a custom scheme for mobile deep linking
  static const String redirectUri = 'pulseai://fitbit-callback';
  static const String callbackUrlScheme = 'pulseai';

  static const _storage = FlutterSecureStorage();

  static const String _accessTokenKey = 'fitbit_access_token';
  static const String _refreshTokenKey = 'fitbit_refresh_token';
  static const String _fitbitUserIdKey = 'fitbit_user_id';

  // Check if Fitbit is connected
  static Future<bool> isConnected() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  // Connect to Fitbit (OAuth Flow)
  static Future<bool> connect(BuildContext context) async {
    try {
      final authUrl = Uri.https('www.fitbit.com', '/oauth2/authorize', {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': 'activity heartrate location nutrition profile settings sleep social weight',
        'expires_in': '2592000', // 30 days
      });

      print("🔗 Opening Fitbit Authorization: $authUrl");

      final result = await FlutterWebAuth.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: callbackUrlScheme,
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) {
        print("❌ No authorization code received");
        return false;
      }

      // Exchange code for access token
      final tokenResponse = await http.post(
        Uri.parse('https://api.fitbit.com/oauth2/token'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
        },
      );

      if (tokenResponse.statusCode == 200) {
        final data = jsonDecode(tokenResponse.body);

        // Save tokens securely
        await _storage.write(key: _accessTokenKey, value: data['access_token']);
        await _storage.write(key: _refreshTokenKey, value: data['refresh_token'] ?? '');
        await _storage.write(key: _fitbitUserIdKey, value: data['user_id'] ?? '');

        print("✅ Fitbit Connected Successfully");

        // TODO: Send token to your backend
        await _sendTokensToBackend(data);

        return true;
      } else {
        print("❌ Token exchange failed: ${tokenResponse.body}");
        return false;
      }
    } catch (e) {
      print("❌ Fitbit Connect Error: $e");
      return false;
    }
  }

  // Send tokens to your backend to store in database
  static Future<void> _sendTokensToBackend(Map<String, dynamic> tokenData) async {
    try {
      // Replace with your actual API endpoint
      final response = await http.post(
        Uri.parse(ApiConstants.fitbitConnect), // Change to your real URL
        headers: {
          'Content-Type': 'application/json',
          // Add your auth token if needed
        },
        body: jsonEncode({
          'accessToken': tokenData['access_token'],
          'refreshToken': tokenData['refresh_token'],
          'expiresIn': tokenData['expires_in'],
          'fitbitUserId': tokenData['user_id'],
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Tokens saved to backend successfully");
      }
    } catch (e) {
      print("⚠️ Failed to send tokens to backend: $e");
      // Still return true since local storage succeeded
    }
  }

  // Get stored access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // Disconnect Fitbit
  static Future<void> disconnect() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _fitbitUserIdKey);
    print("🚫 Fitbit Disconnected");
  }

  // Refresh token (optional, for later use)
  static Future<bool> refreshToken() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('https://api.fitbit.com/oauth2/token'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: _accessTokenKey, value: data['access_token']);
        if (data['refresh_token'] != null) {
          await _storage.write(key: _refreshTokenKey, value: data['refresh_token']);
        }
        return true;
      }
    } catch (e) {
      print("Refresh token failed: $e");
    }
    return false;
  }

  // ==================== DATA SYNCING ====================

  // Sync today's data
  static Future<bool> syncTodayData() async {
    final token = await getAccessToken();
    if (token == null) return false;

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      // Fetch Steps + Activity
      final activityRes = await http.get(
        Uri.parse('https://api.fitbit.com/1/user/-/activities/date/$today.json'),
        headers: {'Authorization': 'Bearer $token'},
      );

      // Fetch Sleep
      final sleepRes = await http.get(
        Uri.parse('https://api.fitbit.com/1.2/user/-/sleep/date/$today.json'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (activityRes.statusCode == 200) {
        final activity = jsonDecode(activityRes.body);
        final sleep = sleepRes.statusCode == 200 ? jsonDecode(sleepRes.body) : {};

        final data = {
          "date": today,
          "steps": activity['summary']['steps'] ?? 0,
          "caloriesOut": activity['summary']['caloriesOut'] ?? 0,
          "heartRate": {
            "resting": activity['summary']['restingHeartRate'],
          },
          "sleep": _parseSleepData(sleep),
        };

        // Send to your backend
        await _sendDataToBackend(data);
        print("✅ Fitbit data synced successfully");
        return true;
      }
    } catch (e) {
      print("❌ Sync failed: $e");
    }
    return false;
  }

  static Map<String, dynamic> _parseSleepData(dynamic sleepData) {
    if (sleepData.isEmpty || sleepData['summary'] == null) return {};
    final summary = sleepData['summary'];

    return {
      "duration": summary['totalTimeInBed'] ?? 0,
      "efficiency": summary['efficiency'],
      "deep": summary['stages']?['deep'],
      "light": summary['stages']?['light'],
      "rem": summary['stages']?['rem'],
      "awake": summary['stages']?['wake'],
    };
  }

  static Future<void> _sendDataToBackend(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.fitbitSync), // Update with your real endpoint
        headers: {
          'Content-Type': 'application/json',
          // Add Authorization header if needed
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print("✅ Data saved to backend");
      }
    } catch (e) {
      print("⚠️ Failed to save data to backend: $e");
    }
  }
}