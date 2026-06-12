import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/google_auth_service.dart';

import '../dashboard/dashboard_screen.dart';
import '../onboarding/profile_setup_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  Future<void> register() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    final result = await AuthService.register(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful. Please Login.")),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Registration Failed")),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    final googleUser = await GoogleAuthService.signIn();

    if (googleUser == null) {
      return;
    }

    final result = await AuthService.googleLogin(
      name: googleUser.displayName ?? "",
      email: googleUser.email ?? "",
      firebaseUid: googleUser.uid,
      photoUrl: googleUser.photoURL ?? "",
    );

    if (!mounted) return;

    if (result["success"]) {
      final String token = result["token"];
      final userData = result["user"];

      if (userData["profileCompleted"] == false) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(token: token),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(token: token),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Google Sign In Failed")),
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Matches your Mesh/Fluid Gradient Background
          _buildMeshBackground(context),

          // 2. Main Scroll Content
          SafeArea(
            child: Column(
              children: [
                _buildHeaderBar(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: _buildGlassRegisterCard(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Background Design Palette (Unified Canvas) ---
  Widget _buildMeshBackground(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.width,
      height: size.height,
      color: const Color(0xffe2eafc),
      child: Stack(
        children: [
          Positioned(
            top: -size.height * 0.2,
            left: -size.width * 0.1,
            child: Container(
              width: size.width * 0.6,
              height: size.height * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xff57ebd3).withOpacity(0.7),
                    const Color(0xff7bf1a8).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.1,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.7,
              height: size.height * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xffff7c54).withOpacity(0.65),
                    const Color(0xffffbe7b).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.2,
            right: -size.width * 0.1,
            child: Container(
              width: size.width * 0.7,
              height: size.height * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xffb57eff).withOpacity(0.75),
                    const Color(0xffded2f9).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.1,
            right: -size.width * 0.05,
            child: Container(
              width: size.width * 0.45,
              height: size.height * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xffffb26b).withOpacity(0.55),
                    const Color(0xfffff4e0).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Top App Header Back Row ---
  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            "Pulse AI",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // --- Glassmorphic Container Form ---
  Widget _buildGlassRegisterCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: 460,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xff1a1a1a),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Join Pulse AI to start monitoring your health intelligently.",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Full Name Field
              _buildInputField(
                controller: nameController,
                label: "Full Name",
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),

              // Email Field
              _buildInputField(
                controller: emailController,
                label: "Email Address",
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Phone Number Field
              _buildInputField(
                controller: phoneController,
                label: "Phone Number",
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Password Field
              _buildInputField(
                controller: passwordController,
                label: "Password",
                icon: Icons.lock_open_rounded,
                obscureText: true,
              ),
              const SizedBox(height: 28),

              // Register Button Action Block
              loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6.0),
                        child: CircularProgressIndicator(color: Color(0xff9f6eff)),
                      ),
                    )
                  : Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: const LinearGradient(
                          colors: [Color(0xff29ebd4), Color(0xff9f6eff)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff9f6eff).withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: const Text(
                          "Create Account",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),

              const SizedBox(height: 20),

              // Inline Layout Divider Line
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.black.withOpacity(0.1), thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "OR",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black.withOpacity(0.4),
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.black.withOpacity(0.1), thickness: 1)),
                ],
              ),

              const SizedBox(height: 20),

              // Google Social Integration
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff333333),
                    backgroundColor: Colors.white.withOpacity(0.2),
                    side: const BorderSide(color: Color(0xff29ebd4), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                        height: 20,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Continue with Google",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xff2c3e50)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Navigation Backwards Fallback Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Color(0xff9f6eff),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Shared Component Textfield Helper ---
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black.withOpacity(0.4), size: 22),
        labelText: label,
        labelStyle: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 14),
        floatingLabelStyle: const TextStyle(color: Color(0xff9f6eff), fontWeight: FontWeight.bold),
        filled: true,
        fillColor: Colors.white.withOpacity(0.35),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xff9f6eff), width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}