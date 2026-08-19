import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';

class HealthService {
  // ---------------------------------------------------------------------------
  // Google Health API scopes
  // ---------------------------------------------------------------------------

  static const String scopeActivity =
      'https://www.googleapis.com/auth/googlehealth.activity_and_fitness.readonly';

  static const String scopeMetrics =
      'https://www.googleapis.com/auth/googlehealth.health_metrics_and_measurements.readonly';

  static const String scopeSleep =
      'https://www.googleapis.com/auth/googlehealth.sleep.readonly';

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      scopeActivity,
      scopeMetrics,
      scopeSleep,
    ],
    serverClientId:
        '594020358294-p8k9knp8e5l2ogpn2rkc391ktmlf8t46.apps.googleusercontent.com',
  );

  static String? _accessToken;
  static String? _currentPlatform;
  static String? _userEmail;
  static bool _initialized = false;
  static bool _isConnecting = false;

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
    debugPrint('[HealthService][$_platformName] $message');
  }

  // ---------------------------------------------------------------------------
  // Safe number conversion
  // ---------------------------------------------------------------------------

  static int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is double) return value.round();

    if (value is num) return value.toInt();

    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.round() ?? 0;
    }

    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is double) return value;

    if (value is int) return value.toDouble();

    if (value is num) return value.toDouble();

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  /// Tries a list of nested key-paths (each path is a list of keys) against
  /// [point] and returns the first non-null value found. Used because the
  /// exact field layout of a data point can vary slightly by data type.
  static dynamic _dig(Map<String, dynamic> point, List<List<String>> paths) {
    for (final path in paths) {
      dynamic current = point;
      for (final key in path) {
        if (current is Map<String, dynamic> && current.containsKey(key)) {
          current = current[key];
        } else {
          current = null;
          break;
        }
      }
      if (current != null) return current;
    }
    return null;
  }

  /// Extracts a `yyyy-MM-dd` date bucket key from a data point, trying
  /// several common timestamp field locations.
  static String? _dateKeyFromPoint(
    Map<String, dynamic> point,
    String typeKey,
  ) {
    final rawTimestamp = _dig(point, [
      [typeKey, 'interval', 'startTime'],
      [typeKey, 'sampleTime', 'physicalTime'],
      ['interval', 'startTime'],
      ['sampleTime', 'physicalTime'],
      ['startTime'],
      ['time'],
    ]);

    if (rawTimestamp is String && rawTimestamp.isNotEmpty) {
      final parsed = DateTime.tryParse(rawTimestamp);
      if (parsed != null) {
        return _formatDateKey(parsed.toUtc());
      }
    }

    return null;
  }

  static String _formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ---------------------------------------------------------------------------
  // Connect
  // ---------------------------------------------------------------------------

  /// Restores the previously selected Google Health account without showing
  /// the Google account picker again. Google Sign-In manages the underlying
  /// credential/session; the short-lived OAuth access token is refreshed when
  /// needed instead of storing an expired token permanently.
  static Future<bool> initialize() async {
    if (_initialized && _accessToken != null) return true;

    _currentPlatform = _platformName;
    _log('Trying silent Google Health sign-in...');

    try {
      final user = await _googleSignIn.signInSilently();
      if (user == null) {
        _initialized = true;
        _log('No previously authorized Google Health account found.');
        return false;
      }

      _userEmail = user.email;
      final auth = await user.authentication;
      _accessToken = auth.accessToken;
      _initialized = true;

      _log('Silently restored Google Health account: ${user.email}');
      _log('Fresh access token present: ${_accessToken != null}');
      return _accessToken != null;
    } catch (e, stack) {
      _initialized = true;
      _log('Silent Google Health sign-in failed: $e');
      _log('Stack: $stack');
      return false;
    }
  }

  static Future<bool> connect() async {
    if (_isConnecting) return _accessToken != null;

    _isConnecting = true;
    _currentPlatform = _platformName;
    _log('Starting Google Health Sign-In...');

    try {
      // First try to restore the existing account. This avoids asking the user
      // to select/sign in again after app restarts.
      final restored = await initialize();
      if (restored) return true;

      final user = await _googleSignIn.signIn();

      if (user == null) {
        _log('User cancelled sign-in');
        return false;
      }

      _userEmail = user.email;
      _initialized = true;

      _log('Signed in as: ${user.email}');
      _log('Display name: ${user.displayName}');

      final auth = await user.authentication;

      _accessToken = auth.accessToken;

      final idToken = auth.idToken;

      _log('Access Token present: ${_accessToken != null}');

      _log('ID Token present: ${idToken != null}');

      if (_accessToken == null) {
        _log('ERROR: No access token received.');

        return false;
      }

      _log('Google Health Cloud authentication successful.');

      return true;
    } catch (e, stack) {
      _log('Google Health Auth Error: $e');
      _log('Stack: $stack');

      return false;
    } finally {
      _isConnecting = false;
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
    _initialized = false;

    _log('Disconnected');
  }

  // ---------------------------------------------------------------------------
  // Connection status
  // ---------------------------------------------------------------------------

  static bool get isConnected => _accessToken != null;

  static Map<String, dynamic> get connectionInfo => {
        'connected': isConnected,
        'platform': _currentPlatform ?? _platformName,
        'email': _userEmail,
        'hasAccessToken': _accessToken != null,
      };

  // ---------------------------------------------------------------------------
  // Date range (last 30 days — used by the dashboard "today" view)
  // ---------------------------------------------------------------------------

  static DateTime get _startDate {
    final now = DateTime.now().toUtc();

    return now.subtract(const Duration(days: 30));
  }

  static DateTime get _endDate {
    return DateTime.now().toUtc();
  }

  static String _iso(DateTime date) {
    return '${date.toIso8601String().split('.').first}Z';
  }

  /// Makes sure a fresh OAuth access token exists. If the current token has
  /// expired, Google Sign-In silently restores the same account.
  static Future<bool> _ensureAuthenticated() async {
    try {
      var user = _googleSignIn.currentUser;
      user ??= await _googleSignIn.signInSilently();
      if (user == null) return false;

      _userEmail = user.email;
      final auth = await user.authentication;
      if (auth.accessToken != null) {
        _accessToken = auth.accessToken;
        _initialized = true;
        return true;
      }
    } catch (e) {
      _log('Unable to refresh Google Health access token: $e');
    }
    return initialize();
  }

  // ---------------------------------------------------------------------------
  // Daily Rollup
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>?> _fetchDailyRollup(
    String dataType, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_accessToken == null) {
      _log('Cannot fetch $dataType → not connected');
      return null;
    }

    final start = startDate ?? _startDate;
    final end = endDate ?? _endDate;

    final url = Uri.parse(
      'https://health.googleapis.com/v4/users/me/'
      'dataTypes/$dataType/dataPoints:dailyRollUp',
    );

    final body = {
      'range': {
        'start': {
          'date': {
            'year': start.year,
            'month': start.month,
            'day': start.day,
          },
          'time': {
            'hours': 0,
            'minutes': 0,
            'seconds': 0,
            'nanos': 0,
          },
        },
        'end': {
          'date': {
            'year': end.year,
            'month': end.month,
            'day': end.day,
          },
          'time': {
            'hours': end.hour,
            'minutes': end.minute,
            'seconds': end.second,
            'nanos': 0,
          },
        },
      },
      'windowSizeDays': 1,
    };

    _log('POST dailyRollUp → $dataType (${_iso(start)} → ${_iso(end)})');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      _log('dailyRollUp $dataType → ${response.statusCode}');

      if (response.statusCode != 200) {
        _log('dailyRollUp ERROR: ${response.body}');

        return null;
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      _log('dailyRollUp exception for $dataType: $e');

      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Chunked Daily Rollup
  // ---------------------------------------------------------------------------

  /// The dailyRollUp endpoint rejects any request where
  /// `windowSizeDays * pageSize` exceeds 90 days (Google returns
  /// INVALID_ROLLUP_QUERY_DURATION for e.g. a 5-year range). This wrapper
  /// transparently splits a wide date range into <=90-day windows, fires
  /// one request per window, and merges all `rollupDataPoints` back into a
  /// single result — callers don't need to know about the limit.
  static Future<Map<String, dynamic>?> _fetchDailyRollupChunked(
    String dataType, {
    required DateTime startDate,
    required DateTime endDate,
    int maxChunkDays = 89, // stay just under Google's 90-day ceiling
  }) async {
    if (_accessToken == null) {
      _log('Cannot fetch $dataType → not connected');
      return null;
    }

    final List<dynamic> mergedPoints = [];
    DateTime chunkStart = startDate;

    while (chunkStart.isBefore(endDate)) {
      final proposedEnd = chunkStart.add(Duration(days: maxChunkDays));
      final chunkEnd = proposedEnd.isAfter(endDate) ? endDate : proposedEnd;

      final result = await _fetchDailyRollup(
        dataType,
        startDate: chunkStart,
        endDate: chunkEnd,
      );

      final points = result?['rollupDataPoints'];
      if (points is List) {
        mergedPoints.addAll(points);
      }

      chunkStart = chunkEnd;
    }

    _log('$dataType chunked rollup → ${mergedPoints.length} total rows');

    return {'rollupDataPoints': mergedPoints};
  }

  // ---------------------------------------------------------------------------
  // Normal Data Points
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>?> _fetchDataPoints(
    String dataType, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!await _ensureAuthenticated()) {
      _log('Cannot fetch $dataType → not authenticated');
      return null;
    }

    final start = startDate ?? _startDate;
    final end = endDate ?? _endDate;
    final startIso = _iso(start);
    final endIso = _iso(end);
    final filterType = dataType.replaceAll('-', '_');

    String filter;
    if (dataType == 'daily-resting-heart-rate' ||
        dataType == 'daily-heart-rate-variability' ||
        dataType == 'daily-oxygen-saturation' ||
        dataType == 'daily-respiratory-rate' ||
        dataType == 'daily-vo2-max') {
      final startDateKey = _formatDateKey(start);
      final endDateKey = _formatDateKey(end);
      filter = '$filterType.date >= "$startDateKey" '
          'AND $filterType.date < "$endDateKey"';
    } else if (dataType == 'steps' ||
        dataType == 'active-zone-minutes' ||
        dataType == 'distance' ||
        dataType == 'total-calories' ||
        dataType == 'active-energy-burned' ||
        dataType == 'active-minutes' ||
        dataType == 'floors' ||
        dataType == 'sleep') {
      filter = '$filterType.interval.start_time >= "$startIso" '
          'AND $filterType.interval.start_time < "$endIso"';
    } else if (dataType == 'core-body-temperature') {
      filter = '$filterType.sample_time.physical_time >= "$startIso" '
          'AND $filterType.sample_time.physical_time < "$endIso"';
    } else {
      filter = '$filterType.sample_time.physical_time >= "$startIso" '
          'AND $filterType.sample_time.physical_time < "$endIso"';
    }

    final List<dynamic> allPoints = [];
    String? pageToken;

    try {
      do {
        final query = <String, String>{
          'filter': filter,
          'page_size': '1000',
        };
        if (pageToken != null && pageToken.isNotEmpty) {
          query['page_token'] = pageToken;
        }

        final url = Uri.parse(
          'https://health.googleapis.com/v4/users/me/'
          'dataTypes/$dataType/dataPoints',
        ).replace(queryParameters: query);

        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $_accessToken',
            'Accept': 'application/json',
          },
        );

        _log('list $dataType → ${response.statusCode}');

        if (response.statusCode != 200) {
          _log('API ERROR $dataType: ${response.body}');
          return null;
        }

        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final points = decoded['dataPoints'];
        if (points is List) {
          allPoints.addAll(points);
        }
        pageToken = decoded['nextPageToken']?.toString();
      } while (pageToken != null && pageToken!.isNotEmpty);

      _log('$dataType returned ${allPoints.length} data points across all pages');
      return {'dataPoints': allPoints};
    } catch (e) {
      _log('Exception fetching $dataType: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Get Health Data (last 30 days, aggregated total — dashboard view)
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getTodayHealthData() async {
    final history = await getAllHealthHistory(daysBack: 30);
    final records = history['records'];
    if (records is List && records.isNotEmpty) {
      return Map<String, dynamic>.from(records.first as Map);
    }
    return {
      'source': history['source'] ?? 'Disconnected',
      'platform': _platformName,
    };
  }

  // ---------------------------------------------------------------------------
  // LOCAL APP CACHE + SYNC-POINT ENGINE
  // ---------------------------------------------------------------------------

  static const String _localHistoryKey = 'pulse_ai_health_history_v2';
  static const String _localSyncPointsKey = 'pulse_ai_health_sync_points_v2';

  static Future<List<Map<String, dynamic>>> getLocalHealthHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localHistoryKey);
      if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      _log('Local health cache read error: $e');
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> _saveLocalHealthHistory(
    List<Map<String, dynamic>> records,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localHistoryKey, jsonEncode(records));
    } catch (e) {
      _log('Local health cache write error: $e');
    }
  }

  static Future<Map<String, dynamic>> getLocalSyncPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localSyncPointsKey);
      if (raw == null || raw.isEmpty) return <String, dynamic>{};
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (e) {
      _log('Local sync point read error: $e');
      return <String, dynamic>{};
    }
  }

  static Future<void> _saveLocalSyncPoints(Map<String, dynamic> points) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localSyncPointsKey, jsonEncode(points));
    } catch (e) {
      _log('Local sync point write error: $e');
    }
  }

  static Future<Map<String, dynamic>> loadStoredHealthHistory(String jwt) async {
    final local = await getLocalHealthHistory();
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/health-connect/snapshot'),
        headers: {'Authorization': 'Bearer $jwt', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final raw = body['data'];
        final records = raw is List
            ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : local;
        final points = body['syncPoints'] is Map
            ? Map<String, dynamic>.from(body['syncPoints'])
            : await getLocalSyncPoints();
        await _saveLocalHealthHistory(records);
        await _saveLocalSyncPoints(points);
        return {
          'records': records,
          'syncPoints': points,
          'source': 'Pulse AI MongoDB cache',
          'rangeStart': records.isEmpty ? null : records.last['date'],
          'rangeEnd': records.isEmpty ? null : records.first['date'],
        };
      }
    } catch (e) {
      _log('MongoDB health snapshot unavailable: $e');
    }

    final points = await getLocalSyncPoints();
    local.sort((a, b) =>
        (b['date'] ?? '').toString().compareTo((a['date'] ?? '').toString()));
    return {
      'records': local,
      'syncPoints': points,
      'source': 'Pulse AI local app cache',
      'rangeStart': local.isEmpty ? null : local.last['date'],
      'rangeEnd': local.isEmpty ? null : local.first['date'],
    };
  }

  static bool _isDue(dynamic value, Duration age) {
    if (value == null) return true;
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return true;
    return DateTime.now().toUtc().difference(parsed.toUtc()) >= age;
  }

  static bool _sameRecord(Map<String, dynamic> a, Map<String, dynamic> b) {
    const fields = [
      'date', 'steps', 'distanceWalked', 'calories', 'activeHours', 'floors',
      'activeZoneMinutes', 'heartRate', 'restingHeartRate', 'sleepHours',
      'bloodOxygen', 'bodyTemperature', 'weight',
    ];
    for (final field in fields) {
      final av = a[field] is num ? (a[field] as num).toDouble() : a[field];
      final bv = b[field] is num ? (b[field] as num).toDouble() : b[field];
      if (av != bv) return false;
    }
    return true;
  }

  static Future<bool> isHealthSyncDue(String jwt) async {
    final snapshot = await loadStoredHealthHistory(jwt);
    final points = snapshot['syncPoints'] is Map
        ? Map<String, dynamic>.from(snapshot['syncPoints'])
        : <String, dynamic>{};
    if (points['lastFullSyncAt'] == null) return true;
    return _isDue(points['lastDailySyncAt'], const Duration(days: 1)) ||
        _isDue(points['lastWeeklySyncAt'], const Duration(days: 7)) ||
        _isDue(points['lastMonthlySyncAt'], const Duration(days: 30));
  }

  /// Performs only the sync window required by the daily/weekly/monthly
  /// sync points. The first sync is a complete history import.
  static Future<Map<String, dynamic>> smartSyncHealth(String jwt, {bool force = false}) async {
    if (!await _ensureAuthenticated()) {
      throw Exception('Google Health is not connected.');
    }

    final snapshot = await loadStoredHealthHistory(jwt);
    final serverPoints = snapshot['syncPoints'] is Map
        ? Map<String, dynamic>.from(snapshot['syncPoints'])
        : <String, dynamic>{};
    final localRecords = snapshot['records'] is List
        ? snapshot['records'].whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    final hasFull = serverPoints['lastFullSyncAt'] != null;
    final dailyDue = force || _isDue(serverPoints['lastDailySyncAt'], const Duration(days: 1));
    final weeklyDue = force || _isDue(serverPoints['lastWeeklySyncAt'], const Duration(days: 7));
    final monthlyDue = force || _isDue(serverPoints['lastMonthlySyncAt'], const Duration(days: 30));

    if (!force && hasFull && !dailyDue && !weeklyDue && !monthlyDue) {
      return {
        'changed': false,
        'newRecords': 0,
        'updatedRecords': 0,
        'records': localRecords,
        'syncPoints': serverPoints,
        'skipped': true,
      };
    }

    int daysBack;
    if (!hasFull) {
      daysBack = 3650;
    } else if (monthlyDue) {
      daysBack = 90;
    } else if (weeklyDue) {
      daysBack = 14;
    } else {
      daysBack = 3;
    }

    final google = await getAllHealthHistory(daysBack: daysBack);
    final raw = google['records'];
    final googleRecords = raw is List
        ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    final byDate = <String, Map<String, dynamic>>{
      for (final record in localRecords)
        if ((record['date'] ?? '').toString().isNotEmpty) record['date'].toString(): record,
    };
    int newRecords = 0;
    int updatedRecords = 0;
    final changedRecords = <Map<String, dynamic>>[];

    for (final record in googleRecords) {
      final date = record['date']?.toString();
      if (date == null || date.isEmpty) continue;
      final old = byDate[date];
      if (old == null) {
        newRecords++;
        byDate[date] = record;
        changedRecords.add(record);
      } else if (!_sameRecord(old, record)) {
        updatedRecords++;
        byDate[date] = record;
        changedRecords.add(record);
      }
    }

    final merged = byDate.values.toList()
      ..sort((a, b) =>
          (b['date'] ?? '').toString().compareTo((a['date'] ?? '').toString()));

    final now = DateTime.now().toUtc().toIso8601String();
    final points = <String, dynamic>{...serverPoints};
    points['lastDailySyncAt'] = now;
    if (!hasFull) points['lastFullSyncAt'] = now;
    if (weeklyDue || !hasFull) points['lastWeeklySyncAt'] = now;
    if (monthlyDue || !hasFull) points['lastMonthlySyncAt'] = now;
    points['lastSyncAt'] = now;
    points['lastSyncRangeDays'] = daysBack;

    // MongoDB is the authoritative server cache. Only changed/new rows are sent.
    if (changedRecords.isNotEmpty || !hasFull) {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/health-connect/sync-incremental'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'records': changedRecords,
          'syncPoints': points,
          'source': 'Google Health Cloud API',
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Incremental health sync failed: ${response.body}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['syncPoints'] is Map) {
        points
          ..clear()
          ..addAll(Map<String, dynamic>.from(body['syncPoints']));
      }
    } else {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/health-connect/sync-points'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'syncPoints': points}),
      );
      if (response.statusCode != 200) {
        throw Exception('Sync point update failed: ${response.body}');
      }
    }

    await _saveLocalHealthHistory(merged);
    await _saveLocalSyncPoints(points);

    return {
      'changed': newRecords > 0 || updatedRecords > 0,
      'newRecords': newRecords,
      'updatedRecords': updatedRecords,
      'records': merged,
      'syncPoints': points,
      'daysBack': daysBack,
      'skipped': false,
    };
  }

  static Future<void> clearLocalHealthCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localHistoryKey);
    await prefs.remove(_localSyncPointsKey);
  }

  // ---------------------------------------------------------------------------
  // Get ALL-TIME Health History (day-by-day records)
  // ---------------------------------------------------------------------------

  /// Fetches every available data point going back [daysBack] days (defaults
  /// to ~5 years, which is effectively "all time" for this API) and buckets
  /// it into one record per calendar day.
  ///
  /// Returns:
  /// {
  ///   'records': [
  ///     {
  ///       'date': '2026-08-11',
  ///       'steps': 8123,
  ///       'heartRate': 74,       // last reading of the day
  ///       'floors': 9,
  ///       'bloodOxygen': 97.8,   // last reading of the day
  ///       'activeZoneMinutes': 22,
  ///       'weight': 71.2,        // last reading of the day
  ///     },
  ///     ...
  ///   ], // sorted newest → oldest
  ///   'source': 'Google Health Cloud API',
  ///   'rangeStart': '...',
  ///   'rangeEnd': '...',
  ///   'totalDaysWithData': 42,
  /// }
  static Future<Map<String, dynamic>> getAllHealthHistory({
    int daysBack = 3650, // ~10 years; API returns only data actually available
  }) async {
    if (!await _ensureAuthenticated()) {
      return {
        'records': <Map<String, dynamic>>[],
        'source': 'Disconnected',
        'platform': _platformName,
      };
    }

    final start = DateTime.now().toUtc().subtract(Duration(days: daysBack));
    final end = DateTime.now().toUtc();

    _log('Fetching complete available health history (${_iso(start)} → ${_iso(end)})');

    final results = await Future.wait([
      _fetchDataPoints('steps', startDate: start, endDate: end),
      _fetchDataPoints('distance', startDate: start, endDate: end),
      _fetchDataPoints('total-calories', startDate: start, endDate: end),
      _fetchDataPoints('active-minutes', startDate: start, endDate: end),
      _fetchDailyRollupChunked('floors', startDate: start, endDate: end),
      _fetchDataPoints('heart-rate', startDate: start, endDate: end),
      _fetchDataPoints('daily-resting-heart-rate', startDate: start, endDate: end),
      _fetchDataPoints('sleep', startDate: start, endDate: end),
      _fetchDataPoints('oxygen-saturation', startDate: start, endDate: end),
      _fetchDataPoints('active-zone-minutes', startDate: start, endDate: end),
      _fetchDataPoints('weight', startDate: start, endDate: end),
      _fetchDataPoints('core-body-temperature', startDate: start, endDate: end),
    ]);

    final Map<String, Map<String, dynamic>> byDate = {};

    Map<String, dynamic> bucket(String dateKey) {
      return byDate.putIfAbsent(dateKey, () => {
        'date': dateKey,
        'steps': 0,
        'distanceWalked': 0.0,
        'calories': 0.0,
        'activeHours': 0.0,
        'heartRate': 0,
        'restingHeartRate': 0,
        'floors': 0,
        'sleepHours': 0.0,
        'bloodOxygen': 0.0,
        'activeZoneMinutes': 0,
        'weight': 0.0,
        'bodyTemperature': 0.0,
      });
    }

    void setLatest(String dateKey, String key, num value) {
      if (value > 0) bucket(dateKey)[key] = value;
    }

    // Steps — sum per day.
    final stepPoints = results[0]?['dataPoints'];
    if (stepPoints is List) {
      for (final raw in stepPoints) {
        if (raw is! Map<String, dynamic>) continue;
        final dateKey = _dateKeyFromPoint(raw, 'steps');
        if (dateKey == null) continue;
        bucket(dateKey)['steps'] =
            _toInt(bucket(dateKey)['steps']) + _toInt(raw['steps']?['count']);
      }
    }

    // Distance — sum meters and expose km.
    final distancePoints = results[1]?['dataPoints'];
    if (distancePoints is List) {
      for (final raw in distancePoints) {
        if (raw is! Map<String, dynamic>) continue;
        final dateKey = _dateKeyFromPoint(raw, 'distance');
        if (dateKey == null) continue;
        final meters = _toDouble(
          raw['distance']?['distanceMeters'] ??
              raw['distance']?['meters'] ??
              raw['distance']?['value'],
        );
        if (meters > 0) {
          bucket(dateKey)['distanceWalked'] =
              _toDouble(bucket(dateKey)['distanceWalked']) + meters / 1000.0;
        }
      }
    }

    // Total calories — sum kcal per day.
    final caloriePoints = results[2]?['dataPoints'];
    if (caloriePoints is List) {
      for (final raw in caloriePoints) {
        if (raw is! Map<String, dynamic>) continue;
        final dateKey = _dateKeyFromPoint(raw, 'totalCalories');
        if (dateKey == null) continue;
        final kcal = _toDouble(
          raw['totalCalories']?['kcal'] ??
              raw['totalCalories']?['calories'] ??
              raw['totalCalories']?['kilocalories'],
        );
        if (kcal > 0) {
          bucket(dateKey)['calories'] =
              _toDouble(bucket(dateKey)['calories']) + kcal;
        }
      }
    }

    // Active minutes — sum and convert to hours.
    final activePoints = results[3]?['dataPoints'];
    if (activePoints is List) {
      for (final raw in activePoints) {
        if (raw is! Map<String, dynamic>) continue;
        final dateKey = _dateKeyFromPoint(raw, 'activeMinutes');
        if (dateKey == null) continue;
        final minutes = _toDouble(
          raw['activeMinutes']?['minutes'] ??
              raw['activeMinutes']?['activeMinutes'] ??
              raw['activeMinutes']?['durationMinutes'],
        );
        if (minutes > 0) {
          bucket(dateKey)['activeHours'] =
              _toDouble(bucket(dateKey)['activeHours']) + minutes / 60.0;
        }
      }
    }

    // Floors — daily rollup.
    final floorRows = results[4]?['rollupDataPoints'];
    if (floorRows is List) {
      for (final raw in floorRows) {
        if (raw is! Map<String, dynamic>) continue;
        String? dateKey = _dateKeyFromPoint(raw, 'floors');
        if (dateKey == null) {
          final dateObj = _dig(raw, [
            ['civilStartTime', 'date'],
            ['range', 'startTime', 'date'],
            ['date'],
            ['floors', 'date'],
          ]);
          if (dateObj is Map<String, dynamic>) {
            final y = _toInt(dateObj['year']);
            final m = _toInt(dateObj['month']);
            final d = _toInt(dateObj['day']);
            if (y > 0 && m > 0 && d > 0) {
              dateKey = _formatDateKey(DateTime.utc(y, m, d));
            }
          }
        }
        if (dateKey == null) continue;
        final value =
            raw['floors']?['count_sum'] ?? raw['floors']?['countSum'];
        bucket(dateKey)['floors'] =
            _toInt(bucket(dateKey)['floors']) + _toInt(value);
      }
    }

    // Heart rate — average the day's samples, rather than keeping only the last
    // sample. This makes weekly/monthly averages statistically useful.
    final hrSums = <String, double>{};
    final hrCounts = <String, int>{};
    final hrPoints = results[5]?['dataPoints'];
    if (hrPoints is List) {
      for (final raw in hrPoints) {
        if (raw is! Map<String, dynamic>) continue;
        final dateKey = _dateKeyFromPoint(raw, 'heartRate');
        if (dateKey == null) continue;
        final value = _toDouble(raw['heartRate']?['beatsPerMinute']);
        if (value <= 0) continue;
        hrSums[dateKey] = (hrSums[dateKey] ?? 0) + value;
        hrCounts[dateKey] = (hrCounts[dateKey] ?? 0) + 1;
      }
    }
    for (final entry in hrSums.entries) {
      bucket(entry.key)['heartRate'] = entry.value / (hrCounts[entry.key] ?? 1);
    }

    // Resting BPM — one daily computed value.
    final restingPoints = results[6]?['dataPoints'];
    if (restingPoints is List) {
      for (final raw in restingPoints) {
        if (raw is! Map<String, dynamic>) continue;
        final dateObj = raw['dailyRestingHeartRate']?['date'] ??
            raw['dailyRestingHeartRate']?['civilDate'] ??
            raw['date'];
        String? dateKey;
        if (dateObj is Map<String, dynamic>) {
          final y = _toInt(dateObj['year']);
          final m = _toInt(dateObj['month']);
          final d = _toInt(dateObj['day']);
          if (y > 0 && m > 0 && d > 0) {
            dateKey = _formatDateKey(DateTime.utc(y, m, d));
          }
        }
        dateKey ??= _dateKeyFromPoint(raw, 'dailyRestingHeartRate');
        if (dateKey == null) continue;
        final value = _toInt(
          raw['dailyRestingHeartRate']?['beatsPerMinute'] ??
              raw['daily_resting_heart_rate']?['beatsPerMinute'],
        );
        setLatest(dateKey, 'restingHeartRate', value);
      }
    }

    // Sleep — sum sleep minutes for the calendar date of the sleep session.
    final sleepPoints = results[7]?['dataPoints'];
    if (sleepPoints is List) {
      for (final raw in sleepPoints) {
        if (raw is! Map<String, dynamic>) continue;
        final interval = raw['sleep']?['interval'];
        final startTime = interval?['startTime'];
        if (startTime is! String) continue;
        final parsed = DateTime.tryParse(startTime);
        if (parsed == null) continue;
        final dateKey = _formatDateKey(parsed.toUtc());
        double hours = 0;
        final minutesAsleep =
            _toDouble(raw['sleep']?['summary']?['minutesAsleep']);
        if (minutesAsleep > 0) {
          hours = minutesAsleep / 60.0;
        } else {
          final endTime = interval?['endTime'];
          final endParsed = endTime is String ? DateTime.tryParse(endTime) : null;
          if (endParsed != null) {
            hours = endParsed.difference(parsed).inMinutes / 60.0;
          }
        }
        if (hours > 0) {
          bucket(dateKey)['sleepHours'] =
              _toDouble(bucket(dateKey)['sleepHours']) + hours;
        }
      }
    }

    // SpO2 — average daily samples.
    final spo2Sums = <String, double>{};
    final spo2Counts = <String, int>{};
    final spo2Points = results[8]?['dataPoints'];
    if (spo2Points is List) {
      for (final raw in spo2Points) {
        if (raw is! Map<String, dynamic>) continue;
        final dateKey = _dateKeyFromPoint(raw, 'oxygenSaturation');
        if (dateKey == null) continue;
        final value = _toDouble(raw['oxygenSaturation']?['percentage']);
        if (value <= 0) continue;
        spo2Sums[dateKey] = (spo2Sums[dateKey] ?? 0) + value;
        spo2Counts[dateKey] = (spo2Counts[dateKey] ?? 0) + 1;
      }
    }
    for (final entry in spo2Sums.entries) {
      bucket(entry.key)['bloodOxygen'] =
          entry.value / (spo2Counts[entry.key] ?? 1);
    }

    // Active Zone Minutes — sum per day.
    final azmPoints = results[9]?['dataPoints'];
    if (azmPoints is List) {
      for (final raw in azmPoints) {
        if (raw is! Map<String, dynamic>) continue;
        final dateKey = _dateKeyFromPoint(raw, 'activeZoneMinutes');
        if (dateKey == null) continue;
        final value =
            _toInt(raw['activeZoneMinutes']?['activeZoneMinutes']);
        bucket(dateKey)['activeZoneMinutes'] =
            _toInt(bucket(dateKey)['activeZoneMinutes']) + value;
      }
    }

    // Weight — latest reading per day.
    final weightPoints = results[10]?['dataPoints'];
    if (weightPoints is List) {
      for (final raw in weightPoints) {
        if (raw is! Map<String, dynamic>) continue;
        final dateKey = _dateKeyFromPoint(raw, 'weight');
        if (dateKey == null) continue;
        setLatest(
          dateKey,
          'weight',
          _toDouble(raw['weight']?['weightKg']),
        );
      }
    }

    // Core temperature — latest reading per day, accepting common API key shapes.
    final temperaturePoints = results[11]?['dataPoints'];
    if (temperaturePoints is List) {
      for (final raw in temperaturePoints) {
        if (raw is! Map<String, dynamic>) continue;
        final dateKey = _dateKeyFromPoint(raw, 'coreBodyTemperature');
        if (dateKey == null) continue;
        final value = _toDouble(
          raw['coreBodyTemperature']?['temperatureCelsius'] ??
              raw['coreBodyTemperature']?['degreesCelsius'] ??
              raw['coreBodyTemperature']?['celsius'],
        );
        setLatest(dateKey, 'bodyTemperature', value);
      }
    }

    final records = byDate.values.toList()
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

    return {
      'records': records,
      'source': 'Google Health Cloud API',
      'platform': _currentPlatform ?? _platformName,
      'email': _userEmail,
      'rangeStart': records.isEmpty
          ? null
          : records.last['date'],
      'rangeEnd': records.isEmpty
          ? null
          : records.first['date'],
      'totalDaysWithData': records.length,
      'fetchedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Persists the complete Google Health history to MongoDB.
  /// The backend upserts by (user, date), so re-syncing is safe.
  static Future<bool> syncHistoryToBackend(
    String jwt,
    List<Map<String, dynamic>> records,
  ) async {
    if (records.isEmpty) return true;
    try {
      const chunkSize = 250;
      for (var i = 0; i < records.length; i += chunkSize) {
        final chunk = records.sublist(
          i,
          (i + chunkSize).clamp(0, records.length),
        );
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/health-connect/sync-bulk'),
          headers: {
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'records': chunk,
            'source': 'Google Health Cloud API',
          }),
        );
        if (response.statusCode != 200) {
          _log('Bulk history sync failed: ${response.statusCode}');
          return false;
        }
      }
      return true;
    } catch (e) {
      _log('Bulk history sync error: $e');
      return false;
    }
  }

  /// Saves the newest daily record to the application backend. The backend
  /// should upsert by (user, date), so refreshing the same day never creates
  /// duplicate rows.
  static Future<bool> syncLatestRecordToBackend(
    String jwt,
    Map<String, dynamic> record,
  ) async {
    try {
      final payload = {
        ...record,
        'source': 'Google Health Cloud API',
        'email': _userEmail,
        'syncedAt': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/health-connect/sync'),
        headers: {
          'Authorization': 'Bearer $jwt',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      _log('Latest daily record sync → ${response.statusCode}');
      if (response.statusCode != 200) {
        _log('Latest record backend error: ${response.body}');
      }
      return response.statusCode == 200;
    } catch (e) {
      _log('Latest record sync error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Sync to Backend
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