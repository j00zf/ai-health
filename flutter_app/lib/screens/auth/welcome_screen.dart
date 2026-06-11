import 'dart:ui';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Beautiful Mesh/Fluid Gradient Background
          _buildMeshBackground(context),

          // 2. Main Content Layer
          SafeArea(
            child: Column(
              children: [
                
                
                // Centered Glassmorphic UI Card
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                      child: _buildGlassCard(context),
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

  // --- Background Graphic Blocks ---
  Widget _buildMeshBackground(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.width,
      height: size.height,
      color: const Color(0xffe2eafc), // Fallback background color
      child: Stack(
        children: [
          // Soft Cyan top-left mesh element
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
          // Vibrant Orange wave mesh element
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
                    const Color(0xffffbe7bff).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Deep Pastel Purple bottom-right element
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
          // Additional Soft Warm Orange glow on the middle-right
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

  // --- Top Navigation Links ---
  Widget _buildNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Row(
        children: [
          _navLink("Features"),
          const SizedBox(width: 12),
          Text("|", style: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 16)),
          const SizedBox(width: 12),
          _navLink("Pricing"),
          const SizedBox(width: 12),
          Text("|", style: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 16)),
          const SizedBox(width: 12),
          _navLink("About"),
        ],
      ),
    );
  }

  Widget _navLink(String text) {
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // --- Central Frosted Glassmorphism Card ---
  Widget _buildGlassCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: 440,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.6),
              width: 1.5,
            ),
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
            children: [
              // Logo Painter Component
              SizedBox(
                width: 200,
                height: 160,
                child: CustomPaint(
                  painter: PulseAiLogoPainter(),
                ),
              ),
              const SizedBox(height: 24),

              // Title Display
              const Text(
                "Pulse AI",
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: Color(0xff1a1a1a),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Sub-Headline Text
              const Text(
                "Intelligent Health, Amplified.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff333333),
                ),
              ),
              const SizedBox(height: 36),

              // Action Callout Prompt
              Text(
                "Ready to optimise your wellness?",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 20),

              // Dynamic Buttons Layout Row
              Row(
                children: [
                  // Gradient Filled Login Button
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: const LinearGradient(
                          colors: [Color(0xff29ebd4), Color(0xff9f6eff)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff9f6eff).withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Styled Border Gradient Action Button
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.transparent,
                      ),
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xff444444),
                          side: const BorderSide(color: Color(0xff29ebd4), width: 1.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2c3e50),
                          ),
                        ),
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
}

// --- High Accuracy Multi-Layer Vector Logo Component ---
class PulseAiLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Left Heart Segment (Vibrant Cyan Core/Blue)
    final paintLeft = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xff0df5f3), Color(0xff4792f9), Color(0xffa166fe)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    var pathLeft = Path();
    pathLeft.moveTo(w * 0.5, h * 0.85);
    pathLeft.cubicTo(w * 0.32, h * 0.72, w * 0.18, h * 0.52, w * 0.18, h * 0.38);
    pathLeft.cubicTo(w * 0.18, h * 0.22, w * 0.28, h * 0.18, w * 0.38, h * 0.26);
    pathLeft.cubicTo(w * 0.44, h * 0.32, w * 0.48, h * 0.48, w * 0.5, h * 0.85);
    canvas.drawPath(pathLeft, paintLeft);

    // 2. Right Heart Segment (Neon Coral Rose Edge)
    final paintRight = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xffff3b53), Color(0xffe6358d), Color(0xffa153f4)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    var pathRight = Path();
    pathRight.moveTo(w * 0.5, h * 0.85);
    pathRight.cubicTo(w * 0.52, h * 0.48, w * 0.56, h * 0.32, w * 0.62, h * 0.26);
    pathRight.cubicTo(w * 0.72, h * 0.18, w * 0.82, h * 0.22, w * 0.82, h * 0.38);
    pathRight.cubicTo(w * 0.82, h * 0.52, w * 0.68, h * 0.72, w * 0.5, h * 0.85);
    canvas.drawPath(pathRight, paintRight);

    // 3. Central Overlay Segment (Deep Orange-Pink Flame Accent)
    final paintMiddle = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xffff9051), Color(0xffff5268), Color(0xffdf40a6)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    var pathMiddle = Path();
    pathMiddle.moveTo(w * 0.5, h * 0.85);
    pathMiddle.cubicTo(w * 0.36, h * 0.58, w * 0.36, h * 0.22, w * 0.5, h * 0.16);
    pathMiddle.cubicTo(w * 0.64, h * 0.22, w * 0.64, h * 0.58, w * 0.5, h * 0.85);
    canvas.drawPath(pathMiddle, paintMiddle);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}