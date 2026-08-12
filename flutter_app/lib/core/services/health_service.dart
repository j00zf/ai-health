import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

class HealthService {
  // ---------------------------------------------------------------------------
  // Google Health API scopes
  // ---------------------------------------------------------------------------

  static const String scopeActivity =
      'https://www.googleapis.com/auth/googlehealth.activity_and_fitness.readonly';

  static const String scopeMetrics =
      'https://www.googleapis.com/auth/googlehealth.health_metrics_and_measurements.readonly';

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      scopeActivity,
      scopeMetrics,
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
    if (_accessToken == null) {
      _log('Cannot fetch $dataType → not connected');
      return null;
    }

    final startIso = _iso(startDate ?? _startDate);
    final endIso = _iso(endDate ?? _endDate);

    final filterType = dataType.replaceAll('-', '_');

    String filter;

    if (dataType == 'steps' || dataType == 'active-zone-minutes') {
      filter = '$filterType.interval.start_time >= "$startIso" '
          'AND $filterType.interval.start_time < "$endIso"';
    } else {
      filter = '$filterType.sample_time.physical_time >= "$startIso" '
          'AND $filterType.sample_time.physical_time < "$endIso"';
    }

    final url = Uri.parse(
      'https://health.googleapis.com/v4/users/me/'
      'dataTypes/$dataType/dataPoints',
    ).replace(
      queryParameters: {
        'filter': filter,
      },
    );

    _log('GET list → $dataType ($startIso → $endIso)');

    try {
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

      _log(
        '$dataType returned '
        '${points is List ? points.length : 0} data points',
      );

      return decoded;
    } catch (e) {
      _log('Exception fetching $dataType: $e');

      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Get Health Data (last 30 days, aggregated total — dashboard view)
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> getTodayHealthData() async {
    if (!await _ensureAuthenticated()) {
      _log('getTodayHealthData called while disconnected');

      return {
        'source': 'Disconnected',
        'platform': _platformName,
      };
    }

    _log('Fetching health data for last 30 days...');

    final results = await Future.wait([
      _fetchDataPoints('steps'),
      _fetchDataPoints('heart-rate'),
      _fetchDailyRollupChunked('floors', startDate: _startDate, endDate: _endDate),
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

    int totalSteps = 0;

    final stepPoints = stepsBody?['dataPoints'];

    if (stepPoints is List) {
      for (final point in stepPoints) {
        final count = point['steps']?['count'];

        totalSteps += _toInt(count);
      }
    }

    int latestHr = 0;

    final hrPoints = hrBody?['dataPoints'];

    if (hrPoints is List && hrPoints.isNotEmpty) {
      for (final point in hrPoints) {
        final bpm = point['heartRate']?['beatsPerMinute'];

        final value = _toInt(bpm);

        if (value > 0) {
          latestHr = value;
        }
      }
    }

    int floors = 0;

    final rollups = floorsBody?['rollupDataPoints'];

    if (rollups is List) {
      for (final row in rollups) {
        final value =
            row['floors']?['count_sum'] ?? row['floors']?['countSum'];

        floors += _toInt(value);
      }
    }

    double spo2 = 0;

    final spo2Points = spo2Body?['dataPoints'];

    if (spo2Points is List && spo2Points.isNotEmpty) {
      for (final point in spo2Points) {
        final value = point['oxygenSaturation']?['percentage'];

        final parsed = _toDouble(value);

        if (parsed > 0) {
          spo2 = parsed;
        }
      }
    }

    int azm = 0;

    final azmPoints = azmBody?['dataPoints'];

    if (azmPoints is List) {
      for (final point in azmPoints) {
        final value = point['activeZoneMinutes']?['activeZoneMinutes'];

        azm += _toInt(value);
      }
    }

    double weightKg = 0;

    final weightPoints = weightBody?['dataPoints'];

    if (weightPoints is List && weightPoints.isNotEmpty) {
      for (final point in weightPoints) {
        final value = point['weight']?['weightKg'];

        final parsed = _toDouble(value);

        if (parsed > 0) {
          weightKg = parsed;
        }
      }
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

    _log(
      'Fetch complete → '
      'steps=$totalSteps, '
      'hr=$latestHr, '
      'floors=$floors, '
      'spo2=$spo2, '
      'azm=$azm, '
      'weight=$weightKg',
    );

    return result;
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
    int daysBack = 1825, // ~5 years
  }) async {
    if (!await _ensureAuthenticated()) {
      _log('getAllHealthHistory called while disconnected');

      return {
        'records': <Map<String, dynamic>>[],
        'source': 'Disconnected',
        'platform': _platformName,
      };
    }

    final start = DateTime.now().toUtc().subtract(Duration(days: daysBack));
    final end = DateTime.now().toUtc();

    _log('Fetching ALL-TIME health history (${_iso(start)} → ${_iso(end)})');

    final results = await Future.wait([
      _fetchDataPoints('steps', startDate: start, endDate: end),
      _fetchDataPoints('heart-rate', startDate: start, endDate: end),
      _fetchDailyRollupChunked('floors', startDate: start, endDate: end),
      _fetchDataPoints('oxygen-saturation', startDate: start, endDate: end),
      _fetchDataPoints('active-zone-minutes',
          startDate: start, endDate: end),
      _fetchDataPoints('weight', startDate: start, endDate: end),
    ]);

    final stepsBody = results[0];
    final hrBody = results[1];
    final floorsBody = results[2];
    final spo2Body = results[3];
    final azmBody = results[4];
    final weightBody = results[5];

    // date key -> partial record
    final Map<String, Map<String, dynamic>> byDate = {};

    Map<String, dynamic> bucket(String dateKey) {
      return byDate.putIfAbsent(
        dateKey,
        () => {
          'date': dateKey,
          'steps': 0,
          'heartRate': 0,
          'floors': 0,
          'bloodOxygen': 0.0,
          'activeZoneMinutes': 0,
          'weight': 0.0,
        },
      );
    }

    // STEPS — sum per day
    final stepPoints = stepsBody?['dataPoints'];
    if (stepPoints is List) {
      for (final raw in stepPoints) {
        if (raw is! Map<String, dynamic>) continue;
        final dateKey = _dateKeyFromPoint(raw, 'steps');
        if (dateKey == null) continue;
        final count = _toInt(raw['steps']?['count']);
        final record = bucket(dateKey);
        record['steps'] = (_toInt(record['steps']) + count);
      }
    }

    // HEART RATE — latest reading per day
    final hrPoints = hrBody?['dataPoints'];
    if (hrPoints is List) {
      for (final raw in hrPoints) {
        if (raw is! Map<String, dynamic>) continue;
        final dateKey = _dateKeyFromPoint(raw, 'heartRate');
        if (dateKey == null) continue;
        final value = _toInt(raw['heartRate']?['beatsPerMinute']);
        if (value <= 0) continue;
        bucket(dateKey)['heartRate'] = value;
      }
    }

    // FLOORS — daily rollup already gives one row per day
    final rollups = floorsBody?['rollupDataPoints'];
    if (rollups is List) {
      for (final raw in rollups) {
        if (raw is! Map<String, dynamic>) continue;

        String? dateKey = _dateKeyFromPoint(raw, 'floors');

        // Daily rollups don't carry a plain timestamp — Google returns the
        // bucket date as a y/m/d object, typically under
        // `civilStartTime.date` or `range.startTime.date` (confirmed against
        // a known-working reference implementation). Try every shape we've
        // seen before giving up on this row.
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

        if (dateKey == null) {
          _log('floors rollup row skipped — no recognizable date field: $raw');
          continue;
        }

        final value =
            raw['floors']?['count_sum'] ?? raw['floors']?['countSum'];
        final record = bucket(dateKey);
        record['floors'] = _toInt(record['floors']) + _toInt(value);
      }
    }

    // SpO2 — latest reading per day
    final spo2Points = spo2Body?['dataPoints'];
    if (spo2Points is List) {
      for (final raw in spo2Points) {
        if (raw is! Map<String, dynamic>) continue;
        final dateKey = _dateKeyFromPoint(raw, 'oxygenSaturation');
        if (dateKey == null) continue;
        final value = _toDouble(raw['oxygenSaturation']?['percentage']);
        if (value <= 0) continue;
        bucket(dateKey)['bloodOxygen'] = value;
      }
    }

    // ACTIVE ZONE MINUTES — sum per day
    final azmPoints = azmBody?['dataPoints'];
    if (azmPoints is List) {
      for (final raw in azmPoints) {
        if (raw is! Map<String, dynamic>) continue;
        final dateKey = _dateKeyFromPoint(raw, 'activeZoneMinutes');
        if (dateKey == null) continue;
        final value =
            _toInt(raw['activeZoneMinutes']?['activeZoneMinutes']);
        final record = bucket(dateKey);
        record['activeZoneMinutes'] =
            _toInt(record['activeZoneMinutes']) + value;
      }
    }

    // WEIGHT — latest reading per day
    final weightPoints = weightBody?['dataPoints'];
    if (weightPoints is List) {
      for (final raw in weightPoints) {
        if (raw is! Map<String, dynamic>) continue;
        final dateKey = _dateKeyFromPoint(raw, 'weight');
        if (dateKey == null) continue;
        final value = _toDouble(raw['weight']?['weightKg']);
        if (value <= 0) continue;
        bucket(dateKey)['weight'] = value;
      }
    }

    final records = byDate.values.toList()
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

    _log('All-time history parsed → ${records.length} days with data');

    return {
      'records': records,
      'source': 'Google Health Cloud API',
      'platform': _currentPlatform ?? _platformName,
      'email': _userEmail,
      'rangeStart': _formatDateKey(start),
      'rangeEnd': _formatDateKey(end),
      'totalDaysWithData': records.length,
      'fetchedAt': DateTime.now().toUtc().toIso8601String(),
    };
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