import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/google_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool loading = false;

  Future<void> login() async {

    if (emailController.text.isEmpty ||
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
        await AuthService.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() {
      loading = false;
    });

    if (result["success"]) {

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/dashboard',
        );
      }

    } else {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            result["message"],
          ),
        ),
      );
    }
  }

  Future<void> signInWithGoogle() async {

    final user =
        await GoogleAuthService.signIn();

    if (user == null) return;

    print(
      "Google User: ${user.email}",
    );

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/dashboard',
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(20),

        child: SingleChildScrollView(
          child: Column(
            children: [

              TextField(
                controller:
                    emailController,
                keyboardType:
                    TextInputType.emailAddress,
                decoration:
                    const InputDecoration(
                  labelText: "Email",
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
                            login,
                        child:
                            const Text(
                          "Login",
                        ),
                      ),
                    ),

              const SizedBox(
                height: 20,
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

                  Navigator.pushNamed(
                    context,
                    "/register",
                  );

                },
                child: const Text(
                  "Create Account",
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}