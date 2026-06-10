import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 100,
              ),

              const SizedBox(height: 20),

              const Text(
                "Fitbit Health",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 50),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/login',
                  );
                },
                child: const Text("Login"),
              ),

              const SizedBox(height: 15),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/register',
                  );
                },
                child: const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}