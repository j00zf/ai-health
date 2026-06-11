import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class AuthService {

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
    ),
  );

  static Future<Map<String, dynamic>>
      register(
    String name,
    String email,
    String phone,
    String password,
  ) async {

    try {

      final response =
          await dio.post(
        '/user/register',
        data: {
          "name": name,
          "email": email,
          "phone": phone,
          "password": password,
        },
      );

      return response.data;

    } catch (e) {

      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>>
      login(
    String email,
    String password,
  ) async {

    try {

      final response =
          await dio.post(
        '/user/login',
        data: {
          "email": email,
          "password": password,
        },
      );

      return response.data;

    } catch (e) {

      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

static Future<Map<String, dynamic>>
googleLogin({
  required String name,
  required String email,
  required String firebaseUid,
  required String photoUrl,
}) async {

  try {

    final response = await dio.post(
      "/user/google-login",
      data: {
        "name": name,
        "email": email,
        "firebaseUid": firebaseUid,
        "photoUrl": photoUrl,
      },
    );

    return response.data;

  } catch (e) {

    return {
      "success": false,
      "message": e.toString(),
    };

  }
}
}