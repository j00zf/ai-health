import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/google_auth_service.dart';
class RegisterScreen
    extends StatefulWidget {
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

Future<void> signInWithGoogle() async {
  final user =
      await GoogleAuthService.signIn();

  if (user != null) {

    print(user.displayName);
    print(user.email);

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/dashboard',
      );
    }
  }
}

  Future<void> register() async {
    setState(() {
      loading = true;
    });

    final result =
        await AuthService.register(
      nameController.text,
      emailController.text,
      phoneController.text,
      passwordController.text,
    );

    setState(() {
      loading = false;
    });

    if (result["success"]) {
      Navigator.pushReplacementNamed(
        context,
        '/login',
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(result["message"]),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [

              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(
                  labelText: "Name",
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller:
                    emailController,
                decoration:
                    const InputDecoration(
                  labelText: "Email",
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller:
                    phoneController,
                decoration:
                    const InputDecoration(
                  labelText: "Phone",
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller:
                    passwordController,
                obscureText: true,
                decoration:
                    const InputDecoration(
                  labelText: "Password",
                ),
              ),

             const SizedBox(height: 30),

              loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: register,
                      child: const Text(
                        "Create Account",
                      ),
                    ),

              const SizedBox(height: 20),

              const Text(
                "OR",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: signInWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text(
                  "Continue with Google",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}