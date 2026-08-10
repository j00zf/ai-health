
//flutter_app/lib/core/services/health_service.dart
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class HealthService {
  // ---------------------------------------------------------------------------
  // Scopes
  // ---------------------------------------------------------------------------
  static const String scopeActivity =
      'https://www.googleapis.com/auth/googlehealth.activity_and_fitness.readonly';
  static const String scopeMetrics =
      'https://www.googleapis.com/auth/googlehealth.health_metrics_and_measurements.readonly';

  // ---------------------------------------------------------------------------
  // Google Sign-In configuration
  // ---------------------------------------------------------------------------
  // IMPORTANT:
  // - serverClientId  → must be the WEB client ID
  // - Android client  → is configured in Google Cloud Console
  //                    (package name + SHA-1). You do NOT put the Android
  //                    client ID in code.
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [scopeActivity, scopeMetrics],
    serverClientId:
        '594020358294-p8k9knp8e5l2ogpn2rkc391ktmlf8t46.apps.googleusercontent.com',
  );

  static String? _accessToken;
  static String? _currentPlatform;
  static String? _userEmail;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  static String get _platformName {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }

  static void _log(String message) {
    debugPrint('[HealthService][${_platformName}] $message');
  }

  // ---------------------------------------------------------------------------
  // Connect
  // ---------------------------------------------------------------------------
  static Future<bool> connect() async {
    _currentPlatform = _platformName;
    _log('Starting Google Sign-In...');

    try {
      // Sign out first so the account picker always appears (good for testing)
      await _googleSignIn.signOut();

      final user = await _googleSignIn.signIn();
      if (user == null) {
        _log('User cancelled sign-in');
        return false;
      }

      _userEmail = user.email;
      _log('Signed in as: ${user.email}');
      _log('Display name: ${user.displayName}');

      final auth = await user.authentication;

      _accessToken = auth.accessToken;
      final idToken = auth.idToken;

      _log('Access Token present: ${_accessToken != null}');
      _log('ID Token present: ${idToken != null}');

      if (_accessToken == null) {
        _log('ERROR → No access token received. Check serverClientId (must be WEB client).');
        return false;
      }

      // Show a short preview of the token (safe for debugging)
      final tokenPreview = _accessToken!.length > 20
          ? '${_accessToken!.substring(0, 20)}...'
          : _accessToken;
      _log('Access Token preview: $tokenPreview');

      _log('Google Health Cloud authenticated successfully on $_currentPlatform');
      return true;
    } catch (e, stack) {
      _log('Google Health Auth Error: $e');
      _log('Stack: $stack');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Disconnect
  // ---------------------------------------------------------------------------
  static Future<void> disconnect() async {
    _log('Disconnecting...');
    await _googleSignIn.signOut();
    _accessToken = null;
    _userEmail = null;
    _log('Disconnected');
  }

  // ---------------------------------------------------------------------------
  // Connection status (useful for UI)
  // ---------------------------------------------------------------------------
  static bool get isConnected => _accessToken != null;

  static Map<String, dynamic> get connectionInfo => {
        'connected': isConnected,
        'platform': _currentPlatform ?? _platformName,
        'email': _userEmail,
        'hasAccessToken': _accessToken != null,
      };

  // ---------------------------------------------------------------------------
  // Core fetch helper
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>?> _fetchDataPoints(String dataType) async {
    if (_accessToken == null) {
      _log('Cannot fetch $dataType → not connected');
      return null;
    }

    final now = DateTime.now().toUtc();
    final startOfDay = DateTime.utc(now.year, now.month, now.day);
    final startIso = '${startOfDay.toIso8601String().split('.').first}Z';
    final endIso = '${now.toIso8601String().split('.').first}Z';

    final filterSnake = dataType.replaceAll('-', '_');

    try {
      // ---------- dailyRollUp (floors / total-calories) ----------
      if (dataType == 'floors' || dataType == 'total-calories') {
        final url = Uri.parse(
          'https://health.googleapis.com/v4/users/me/dataTypes/$dataType/dataPoints:dailyRollUp',
        );

        _log('POST dailyRollUp → $dataType');

        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            "range": {
              "startTime": startIso,
              "endTime": endIso,
            }
          }),
        );

        _log('dailyRollUp $dataType → ${response.statusCode}');
        if (response.statusCode != 200) {
          _log('Error body: ${response.body}');
        }

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        return null;
      }

      // ---------- normal list endpoint ----------
      String filter;
      if (dataType == 'steps' || dataType == 'active-zone-minutes') {
        filter =
            '$filterSnake.interval.start_time >= "$startIso" AND $filterSnake.interval.start_time < "$endIso"';
      } else {
        // heart-rate, oxygen-saturation, weight, etc.
        filter =
            '$filterSnake.sample_time.physical_time >= "$startIso" AND $filterSnake.sample_time.physical_time < "$endIso"';
      }

      final url = Uri.parse(
        'https://health.googleapis.com/v4/users/me/dataTypes/$dataType/dataPoints'
        '?filter=${Uri.encodeQueryComponent(filter)}',
      );

      _log('GET list → $dataType');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      );

      _log('list $dataType → ${response.statusCode}');
      if (response.statusCode != 200) {
        _log('Error body: ${response.body}');
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      _log('Exception fetching $dataType: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // High-level method used by the dashboard
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>> getTodayHealthData() async {
    if (_accessToken == null) {
      _log('getTodayHealthData called while disconnected');
      return {
        'source': 'Disconnected',
        'platform': _platformName,
      };
    }

    _log('Fetching today\'s health data...');

    final results = await Future.wait([
      _fetchDataPoints('steps'),
      _fetchDataPoints('heart-rate'),
      _fetchDataPoints('floors'),
      _fetchDataPoints('oxygen-saturation'),
      _fetchDataPoints('active-zone-minutes'),
      _fetchDataPoints('weight'),
    ]);

    final stepsBody = results[0];
    final hrBody = results[1];
    final floorsBody = results[2];
    final spo2Body = results[3];
    final azmBody = results[4];
    final weightBody = results[5];

    // ---- STEPS ----
    int totalSteps = 0;
    if (stepsBody?['dataPoints'] != null) {
      for (final p in stepsBody!['dataPoints']) {
        final count = p['steps']?['count'] ?? 0;
        totalSteps += (count is num) ? count.toInt() : 0;
      }
    }

    // ---- HEART RATE (latest) ----
    int latestHr = 0;
    if (hrBody?['dataPoints'] != null &&
        (hrBody!['dataPoints'] as List).isNotEmpty) {
      final last = (hrBody['dataPoints'] as List).last;
      final bpm = last['heartRate']?['bpm'] ?? last['heart_rate']?['bpm'];
      latestHr = (bpm is num) ? bpm.round() : 0;
    }

    // ---- FLOORS (daily roll-up) ----
    int floors = 0;
    if (floorsBody?['rollupDataPoints'] != null &&
        (floorsBody!['rollupDataPoints'] as List).isNotEmpty) {
      final row = floorsBody['rollupDataPoints'][0];
      floors = (row['floors']?['count_sum'] ??
              row['floors']?['countSum'] ??
              0)
          .toInt();
    }

    // ---- SpO2 (latest) ----
    double spo2 = 0;
    if (spo2Body?['dataPoints'] != null &&
        (spo2Body!['dataPoints'] as List).isNotEmpty) {
      final last = (spo2Body['dataPoints'] as List).last;
      final pct = last['oxygenSaturation']?['percentage'] ??
          last['oxygen_saturation']?['percentage'];
      spo2 = (pct is num) ? pct.toDouble() : 0;
    }

    // ---- ACTIVE ZONE MINUTES ----
    int azm = 0;
    if (azmBody?['dataPoints'] != null) {
      for (final p in azmBody!['dataPoints']) {
        final mins = p['activeZoneMinutes']?['activeZoneMinutes'] ??
            p['active_zone_minutes']?['activeZoneMinutes'] ??
            0;
        azm += (mins is num) ? mins.toInt() : 0;
      }
    }

    // ---- WEIGHT (latest) ----
    double weightKg = 0;
    if (weightBody?['dataPoints'] != null &&
        (weightBody!['dataPoints'] as List).isNotEmpty) {
      final last = (weightBody['dataPoints'] as List).last;
      final w = last['weight']?['weightKg'] ?? last['weight']?['weight_kg'];
      weightKg = (w is num) ? w.toDouble() : 0;
    }

    final result = {
      'steps': totalSteps,
      'heartRate': latestHr,
      'restingHeartRate': 0,
      'calories': 0,
      'floors': floors,
      'bloodOxygen': spo2,
      'activeZoneMinutes': azm,
      'weight': weightKg,
      'distanceWalked': 0.0,
      'sleepHours': 0.0,
      'source': 'Google Health Cloud API',
      'platform': _currentPlatform ?? _platformName,
      'email': _userEmail,
      'syncedAt': DateTime.now().toUtc().toIso8601String(),
    };

    _log('Fetch complete → steps=$totalSteps, hr=$latestHr, floors=$floors');
    return result;
  }

  // ---------------------------------------------------------------------------
  // Push data to your Node backend
  // ---------------------------------------------------------------------------
  static Future<bool> syncToBackend(String jwt) async {
    try {
      final data = await getTodayHealthData();
      _log('Syncing to backend...');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/health-connect/sync'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      _log('Backend sync → ${response.statusCode}');
      if (response.statusCode != 200) {
        _log('Backend error: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      _log('Sync Error: $e');
      return false;
    }
  }
}