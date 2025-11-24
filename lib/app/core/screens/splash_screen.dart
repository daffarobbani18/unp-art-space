import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import '../navigation/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    // Rotation animation for background circles
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Pulse animation for logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Glow animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _timer = Timer(const Duration(seconds: 7), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AuthGate(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rotationController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027), // Deep Blue Dark
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background circles
            _buildAnimatedBackground(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animations
                  _buildAnimatedLogo(),

                  const SizedBox(height: 40),

                  // Animated text
                  _buildAnimatedText(),

                  const SizedBox(height: 60),

                  // Loading indicator
                  _buildLoadingIndicator(),
                ],
              ),
            ),

            // Floating particles
            ..._buildFloatingParticles(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Circle 1
            Positioned(
              top: -100,
              right: -100,
              child: Transform.rotate(
                angle: _rotationController.value * 2 * 3.14159,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF8B5CF6).withOpacity(0.3),
                        const Color(0xFF8B5CF6).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Circle 2
            Positioned(
              bottom: -150,
              left: -100,
              child: Transform.rotate(
                angle: -_rotationController.value * 2 * 3.14159,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.25),
                        const Color(0xFF3B82F6).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Circle 3
            Positioned(
              top: 200,
              left: -50,
              child: Transform.rotate(
                angle: _rotationController.value * 1.5 * 3.14159,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFEC4899).withOpacity(0.2),
                        const Color(0xFFEC4899).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _glowController]),
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.05);
        final glowOpacity = 0.3 + (_glowController.value * 0.4);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(glowOpacity),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(glowOpacity * 0.6),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(80),
                      child: Image.asset(
                        'assets/images/logo_app.png',
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 800.ms, curve: Curves.easeOut)
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                duration: 800.ms,
                curve: Curves.elasticOut,
              )
              .shimmer(
                delay: 800.ms,
                duration: 1500.ms,
                color: Colors.white.withOpacity(0.3),
              ),
        );
      },
    );
  }

  Widget _buildAnimatedText() {
    return Column(
      children: [
        // Main title with animated gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF8B5CF6),
              Color(0xFF3B82F6),
              Color(0xFFEC4899),
            ],
          ).createShader(bounds),
          child: AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                'UNP ART SPACE',
                textStyle: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
                speed: const Duration(milliseconds: 100),
              ),
            ],
            totalRepeatCount: 1,
            displayFullTextOnTap: true,
          ),
        )
            .animate()
            .fadeIn(delay: 600.ms, duration: 600.ms)
            .slideY(begin: 0.3, end: 0, delay: 600.ms, duration: 600.ms),

        const SizedBox(height: 12),

        // Subtitle
        AnimatedTextKit(
          animatedTexts: [
            FadeAnimatedText(
              'Discover Amazing Artworks',
              textStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
                letterSpacing: 1,
              ),
              duration: const Duration(milliseconds: 2000),
            ),
            FadeAnimatedText(
              'Showcase Your Creativity',
              textStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
                letterSpacing: 1,
              ),
              duration: const Duration(milliseconds: 2000),
            ),
          ],
          repeatForever: false,
          totalRepeatCount: 1,
        )
            .animate()
            .fadeIn(delay: 1200.ms, duration: 600.ms)
            .slideY(begin: 0.3, end: 0, delay: 1200.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        // Custom loading animation
        SizedBox(
          width: 200,
          child: Stack(
            children: [
              // Background track
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Animated progress bar
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    height: 4,
                    width: 200 * _pulseController.value,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF8B5CF6),
                          Color(0xFF3B82F6),
                          Color(0xFFEC4899),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
        ),

        const SizedBox(height: 16),

        // Loading text
        Text(
          'Loading...',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white60,
            letterSpacing: 2,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .fadeIn(duration: 800.ms)
            .fadeOut(delay: 800.ms, duration: 800.ms),
      ],
    )
        .animate()
        .fadeIn(delay: 1800.ms, duration: 600.ms)
        .slideY(begin: 0.3, end: 0, delay: 1800.ms, duration: 600.ms);
  }

  List<Widget> _buildFloatingParticles() {
    return List.generate(15, (index) {
      final random = index * 0.1;
      return Positioned(
        top: 100 + (index * 50.0),
        left: 30 + (index * 25.0),
        child: Container(
          width: 4 + (index % 3) * 2,
          height: 4 + (index % 3) * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.3),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .moveY(
              begin: 0,
              end: -50,
              duration: Duration(milliseconds: 2000 + (index * 100)),
              curve: Curves.easeInOut,
            )
            .fadeIn(duration: 500.ms)
            .fadeOut(delay: Duration(milliseconds: 1500 + (index * 100))),
      );
    });
  }
}
