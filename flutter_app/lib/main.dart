import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'core/services/auth_manager.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const FitbitHealthApp());
}

class FitbitHealthApp extends StatelessWidget {
  const FitbitHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}

// ==================== FIXED AUTH WRAPPER ====================
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    print("🔍 [AuthWrapper] Checking for saved token...");
    final token = await AuthManager().getToken();
    print("🔑 [AuthWrapper] Token found: ${token != null && token.isNotEmpty ? 'YES' : 'NO'}");

    if (mounted) {
      setState(() {
        _token = token;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_token != null && _token!.isNotEmpty) {
      print("🚀 [AuthWrapper] Showing Dashboard");
      return DashboardScreen(token: _token!);
    }

    print("🚀 [AuthWrapper] Showing WelcomeScreen");
    return const WelcomeScreen();
  }
}