import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/google_auth_service.dart';

import '../dashboard/dashboard_screen.dart';
import '../onboarding/profile_setup_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {

  final nameController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool loading = false;

  Future<void> register() async {

    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill all fields",
          ),
        ),
      );

      return;
    }

    setState(() {
      loading = true;
    });

    final result =
        await AuthService.register(
      nameController.text.trim(),
      emailController.text.trim(),
      phoneController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() {
      loading = false;
    });

    if (!mounted) return;

    if (result["success"]) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Registration Successful. Please Login.",
          ),
        ),
      );

      Navigator.pushReplacementNamed(
        context,
        '/login',
      );

    } else {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            result["message"] ??
                "Registration Failed",
          ),
        ),
      );

    }
  }

  Future<void> signInWithGoogle() async {

    final googleUser =
        await GoogleAuthService.signIn();

    if (googleUser == null) {
      return;
    }

    final result =
        await AuthService.googleLogin(
      name:
          googleUser.displayName ?? "",
      email:
          googleUser.email ?? "",
      firebaseUid:
          googleUser.uid,
      photoUrl:
          googleUser.photoURL ?? "",
    );

    if (!mounted) return;

    if (result["success"]) {

      final String token =
          result["token"];

      final userData =
          result["user"];

      if (userData["profileCompleted"] ==
          false) {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CompleteProfileScreen(
              token: token,
            ),
          ),
        );

      } else {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DashboardScreen(
              token: token,
            ),
          ),
        );

      }

    } else {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            result["message"] ??
                "Google Sign In Failed",
          ),
        ),
      );

    }
  }

  @override
  void dispose() {

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Register",
        ),
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(20),

        child: SingleChildScrollView(
          child: Column(
            children: [

              TextField(
                controller:
                    nameController,
                decoration:
                    const InputDecoration(
                  labelText:
                      "Full Name",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              TextField(
                controller:
                    emailController,
                keyboardType:
                    TextInputType
                        .emailAddress,
                decoration:
                    const InputDecoration(
                  labelText:
                      "Email",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              TextField(
                controller:
                    phoneController,
                keyboardType:
                    TextInputType.phone,
                decoration:
                    const InputDecoration(
                  labelText:
                      "Phone Number",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              TextField(
                controller:
                    passwordController,
                obscureText: true,
                decoration:
                    const InputDecoration(
                  labelText:
                      "Password",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width:
                          double.infinity,
                      child:
                          ElevatedButton(
                        onPressed:
                            register,
                        child:
                            const Text(
                          "Create Account",
                        ),
                      ),
                    ),

              const SizedBox(
                height: 25,
              ),

              const Text(
                "OR",
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    OutlinedButton.icon(
                  onPressed:
                      signInWithGoogle,
                  icon:
                      const Icon(
                    Icons.login,
                  ),
                  label:
                      const Text(
                    "Continue with Google",
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              TextButton(
                onPressed: () {

                  Navigator.pushReplacementNamed(
                    context,
                    '/login',
                  );

                },
                child: const Text(
                  "Already have an account? Login",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}