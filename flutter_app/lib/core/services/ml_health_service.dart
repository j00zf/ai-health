import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

class MlHealthService {
MlHealthService._();

static final Dio _dio = Dio(
BaseOptions(
connectTimeout: const Duration(seconds: 20),
receiveTimeout: const Duration(seconds: 60),
sendTimeout: const Duration(seconds: 60),
headers: const {
'Accept': 'application/json',
'Content-Type': 'application/json',
},
),
);

// ===========================================================================
// REQUEST OPTIONS
// ===========================================================================

static Options _options(String token) {
return Options(
headers: {
'Authorization': 'Bearer $token',
'Accept': 'application/json',
'Content-Type': 'application/json',
},
);
}

// ===========================================================================
// RESPONSE NORMALIZATION
// ===========================================================================

static Map<String, dynamic> _asMap(dynamic value) {
if (value is Map<String, dynamic>) {
return value;
}


if (value is Map) {
  return Map<String, dynamic>.from(value);
}

return <String, dynamic>{};


}

// ===========================================================================
// ERROR HANDLING
// ===========================================================================

static String _errorMessage(
DioException error,
String fallback,
) {
final responseData = error.response?.data;


if (responseData is Map) {
  final data = Map<String, dynamic>.from(responseData);

  final message =
      data['message'] ??
      data['error'] ??
      data['detail'];

  if (message != null &&
      message.toString().trim().isNotEmpty) {
    return message.toString();
  }
}

if (responseData is String &&
    responseData.trim().isNotEmpty) {
  return responseData;
}

if (error.message != null &&
    error.message!.trim().isNotEmpty) {
  return error.message!;
}

return fallback;


}

// ===========================================================================
// GET LATEST SAVED HEALTH RECORD
//
// Backend is the source of truth.
// ===========================================================================

static Future<Map<String, dynamic>>
getLatestHealthRecord({
required String token,
}) async {
try {
final response = await _dio.get(
'${ApiConstants.baseUrl}/v1/ml-health/latest-record',
options: _options(token),
);


  return _asMap(response.data);
} on DioException catch (e) {
  return {
    'success': false,
    'message': _errorMessage(
      e,
      'Failed to retrieve the latest health record.',
    ),
  };
} catch (e) {
  return {
    'success': false,
    'message': e.toString(),
  };
}


}

// ===========================================================================
// RUN ML ANALYSIS
//
// The backend retrieves the latest health records from the database.
// Flutter only sends optional profile information.
// ===========================================================================

static Future<Map<String, dynamic>>
analyze({
required String token,
Map<String, dynamic> profile =
const <String, dynamic>{},
}) async {
try {
final response = await _dio.post(
'${ApiConstants.baseUrl}/v1/ml-health/analyze',
data: {
'profile': profile,
},
options: _options(token),
);


  return _asMap(response.data);
} on DioException catch (e) {
  return {
    'success': false,
    'message': _errorMessage(
      e,
      'Unable to complete ML health analysis.',
    ),
  };
} catch (e) {
  return {
    'success': false,
    'message': e.toString(),
  };
}


}

// ===========================================================================
// GET LATEST SAVED ML ANALYSIS
// ===========================================================================

static Future<Map<String, dynamic>>
getLatestAnalysis({
required String token,
}) async {
try {
final response = await _dio.get(
'${ApiConstants.baseUrl}/v1/ml-health/latest',
options: _options(token),
);


  return _asMap(response.data);
} on DioException catch (e) {
  return {
    'success': false,
    'message': _errorMessage(
      e,
      'Failed to load the latest ML analysis.',
    ),
  };
} catch (e) {
  return {
    'success': false,
    'message': e.toString(),
  };
}


}

// ===========================================================================
// GET ML DASHBOARD
// ===========================================================================

static Future<Map<String, dynamic>>
getDashboard({
required String token,
}) async {
try {
final response = await _dio.get(
'${ApiConstants.baseUrl}/v1/ml-health/dashboard',
options: _options(token),
);


  return _asMap(response.data);
} on DioException catch (e) {
  return {
    'success': false,
    'message': _errorMessage(
      e,
      'Failed to load ML health dashboard.',
    ),
  };
} catch (e) {
  return {
    'success': false,
    'message': e.toString(),
  };
}


}

// ===========================================================================
// GET ML ANALYSIS HISTORY
//
// Supports the existing history screen:
// MlHealthService.getHistory(
//   token: widget.token,
//   days: selectedDays,
// )
//
// Sends both days and limit for backward compatibility.
// ===========================================================================

static Future<Map<String, dynamic>>
getHistory({
required String token,
int days = 30,
int limit = 100,
}) async {
try {
final response = await _dio.get(
'${ApiConstants.baseUrl}/v1/ml-health/history',
queryParameters: {
'days': days,
'limit': limit,
},
options: _options(token),
);


  return _asMap(response.data);
} on DioException catch (e) {
  return {
    'success': false,
    'message': _errorMessage(
      e,
      'Failed to load ML health history.',
    ),
  };
} catch (e) {
  return {
    'success': false,
    'message': e.toString(),
  };
}


}

// ===========================================================================
// GET ML HEALTH IMPROVEMENT
// ===========================================================================

static Future<Map<String, dynamic>>
getImprovement({
required String token,
}) async {
try {
final response = await _dio.get(
'${ApiConstants.baseUrl}/v1/ml-health/improvement',
options: _options(token),
);


  return _asMap(response.data);
} on DioException catch (e) {
  return {
    'success': false,
    'message': _errorMessage(
      e,
      'Failed to load ML improvement data.',
    ),
  };
} catch (e) {
  return {
    'success': false,
    'message': e.toString(),
  };
}


}

// ===========================================================================
// GET WELLNESS SUMMARIES (1D, 7D, 30D)
// ===========================================================================

static Future<Map<String, dynamic>>
getWellnessSummaries({
required String token,
}) async {
try {
final response = await _dio.get(
'${ApiConstants.baseUrl}/v1/ml-health/summaries',
options: _options(token),
);

  return _asMap(response.data);
} on DioException catch (e) {
  return {
    'success': false,
    'message': _errorMessage(
      e,
      'Failed to load wellness summaries.',
    ),
  };
} catch (e) {
  return {
    'success': false,
    'message': e.toString(),
  };
}
}
}
