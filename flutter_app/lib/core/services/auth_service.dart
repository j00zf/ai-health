import 'package:dio/dio.dart';

import '../constants/api_constants.dart';

class AuthService {
  // ===========================================================================
  // DIO CLIENT
  // ===========================================================================

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,

      connectTimeout:
          const Duration(seconds: 15),

      receiveTimeout:
          const Duration(seconds: 30),

      sendTimeout:
          const Duration(seconds: 15),

      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },

      validateStatus: (status) {
        return status != null &&
            status >= 200 &&
            status < 500;
      },
    ),
  );

  // ===========================================================================
  // REGISTER
  // ===========================================================================

  static Future<Map<String, dynamic>> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    try {
      print('');
      print('========================================');
      print('[AUTH] REGISTER');
      print('========================================');

      print(
        '[AUTH] URL: '
        '${ApiConstants.baseUrl}/user/register',
      );

      final response = await dio.post(
        '/user/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      print(
        '[AUTH] Register HTTP status: '
        '${response.statusCode}',
      );

      print(
        '[AUTH] Register response: '
        '${response.data}',
      );

      return _normalizeResponse(
        response.data,
      );
    } on DioException catch (e) {
      return _handleDioError(
        e,
        'Registration',
      );
    } catch (e) {
      print(
        '[AUTH] Registration exception: $e',
      );

      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // ===========================================================================
  // LOGIN
  // ===========================================================================

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      print('');
      print('========================================');
      print('[AUTH] LOGIN');
      print('========================================');

      print(
        '[AUTH] Base URL: '
        '${ApiConstants.baseUrl}',
      );

      print(
        '[AUTH] Endpoint: /user/login',
      );

      print(
        '[AUTH] Full URL: '
        '${ApiConstants.baseUrl}/user/login',
      );

      print(
        '[AUTH] Email: $email',
      );

      final response = await dio.post(
        '/user/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      print(
        '[AUTH] HTTP status: '
        '${response.statusCode}',
      );

      print(
        '[AUTH] Raw response: '
        '${response.data}',
      );

      final result = _normalizeResponse(
        response.data,
      );

      print(
        '[AUTH] Normalized response: '
        '$result',
      );

      print(
        '[AUTH] success: '
        '${result['success']}',
      );

      print(
        '[AUTH] token exists: '
        '${result['token'] != null}',
      );

      print(
        '[AUTH] user exists: '
        '${result['user'] != null}',
      );

      print('========================================');

      return result;
    } on DioException catch (e) {
      return _handleDioError(
        e,
        'Login',
      );
    } catch (e) {
      print(
        '[AUTH] Login exception: $e',
      );

      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // ===========================================================================
  // GOOGLE LOGIN
  // ===========================================================================

  static Future<Map<String, dynamic>> googleLogin({
    required String name,
    required String email,
    required String firebaseUid,
    required String photoUrl,
  }) async {
    try {
      print('');
      print('========================================');
      print('[AUTH] GOOGLE LOGIN');
      print('========================================');

      final response = await dio.post(
        '/user/google-login',
        data: {
          'name': name,
          'email': email,
          'firebaseUid': firebaseUid,
          'photoUrl': photoUrl,
        },
      );

      print(
        '[AUTH] Google HTTP status: '
        '${response.statusCode}',
      );

      print(
        '[AUTH] Google response: '
        '${response.data}',
      );

      return _normalizeResponse(
        response.data,
      );
    } on DioException catch (e) {
      return _handleDioError(
        e,
        'Google login',
      );
    } catch (e) {
      print(
        '[AUTH] Google login exception: $e',
      );

      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // ===========================================================================
  // NORMALIZE RESPONSE
  //
  // Supports:
  //
  // {
  //   "success": true,
  //   "token": "...",
  //   "user": {...}
  // }
  //
  // AND:
  //
  // {
  //   "success": true,
  //   "data": {
  //     "token": "...",
  //     "user": {...}
  //   }
  // }
  // ===========================================================================

  static Map<String, dynamic> _normalizeResponse(
    dynamic data,
  ) {
    if (data is! Map) {
      return {
        'success': false,
        'message': 'Invalid response received from server',
      };
    }

    final Map<String, dynamic> result =
        Map<String, dynamic>.from(data);

    // -------------------------------------------------------------------------
    // Nested data
    // -------------------------------------------------------------------------

    final nestedData = result['data'];

    if (nestedData is Map) {
      final nested =
          Map<String, dynamic>.from(
        nestedData,
      );

      if (result['token'] == null) {
        if (nested['token'] != null) {
          result['token'] =
              nested['token'];
        } else if (nested['access_token'] != null) {
          result['token'] =
              nested['access_token'];
        }
      }

      if (result['user'] == null &&
          nested['user'] != null) {
        result['user'] =
            nested['user'];
      }
    }

    // -------------------------------------------------------------------------
    // Top-level access_token
    // -------------------------------------------------------------------------

    if (result['token'] == null &&
        result['access_token'] != null) {
      result['token'] =
          result['access_token'];
    }

    // -------------------------------------------------------------------------
    // Normalize success
    // -------------------------------------------------------------------------

    final dynamic successValue =
        result['success'];

    if (successValue is bool) {
      result['success'] =
          successValue;
    } else if (successValue is num) {
      result['success'] =
          successValue != 0;
    } else if (successValue is String) {
      result['success'] =
          successValue
              .toLowerCase()
              .trim() ==
          'true';
    } else {
      result['success'] = false;
    }

    // -------------------------------------------------------------------------
    // Default message
    // -------------------------------------------------------------------------

    if (result['message'] == null) {
      result['message'] =
          result['success'] == true
              ? 'Success'
              : 'Request failed';
    }

    return result;
  }

  // ===========================================================================
  // DIO ERROR HANDLER
  // ===========================================================================

  static Map<String, dynamic> _handleDioError(
    DioException e,
    String operation,
  ) {
    print('');
    print('========================================');
    print('[AUTH] $operation ERROR');
    print('========================================');

    print(
      '[AUTH] Dio type: ${e.type}',
    );

    print(
      '[AUTH] Message: ${e.message}',
    );

    print(
      '[AUTH] Status: ${e.response?.statusCode}',
    );

    print(
      '[AUTH] Response: ${e.response?.data}',
    );

    print(
      '[AUTH] URL: ${e.requestOptions.uri}',
    );

    print('========================================');

    final responseData =
        e.response?.data;

    if (responseData is Map) {
      final data =
          Map<String, dynamic>.from(
        responseData,
      );

      final message =
          data['message']?.toString() ??
          data['error']?.toString() ??
          _statusMessage(
            e.response?.statusCode,
          );

      return {
        'success': false,
        'message': message,
        'statusCode':
            e.response?.statusCode,
      };
    }

    return {
      'success': false,
      'message': _statusMessage(
        e.response?.statusCode,
      ),
      'statusCode':
          e.response?.statusCode,
    };
  }

  // ===========================================================================
  // HTTP STATUS MESSAGE
  // ===========================================================================

  static String _statusMessage(
    int? statusCode,
  ) {
    switch (statusCode) {
      case 400:
        return 'Invalid request';

      case 401:
        return 'Invalid email or password';

      case 403:
        return 'Access denied';

      case 404:
        return 'Authentication endpoint not found';

      case 409:
        return 'Account already exists';

      case 422:
        return 'Invalid information provided';

      case 500:
        return 'Server error';

      case 502:
        return 'Bad gateway';

      case 503:
        return 'Server temporarily unavailable';

      default:
        return 'Unable to connect to authentication server';
    }
  }
}