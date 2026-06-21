class ApiConstants {
  // ==================== BASE URL ====================
  // Change this according to your environment

  static const String baseUrl = 'https://ai-health-da3t.onrender.com/api';     // For local development
  // static const String baseUrl = 'https://your-production-domain.com/api'; // For production

  // ==================== AUTH ENDPOINTS ====================
  static const String login = '/user/login';
  static const String register = '/user/register';
  static const String googleLogin = '/user/google-login';

  // ==================== PROFILE ENDPOINTS ====================
  static const String createProfile = '/profile/create';
  static const String getProfile = '/profile/me';
  static const String updateProfile = '/profile/update';

  // ==================== DASHBOARD ====================
  static const String dashboard = '/dashboard';

  // ==================== DEVICES / FITBIT ====================
  static const String fitbitConnect = '/devices/fitbit/connect';
  static const String fitbitSync = '/devices/fitbit/sync';
  static const String myDevices = '/devices/my-devices';

  // ==================== HEADERS ====================
  static Map<String, String> authHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==================== TIMEOUTS ====================
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}