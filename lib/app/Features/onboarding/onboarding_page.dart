import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Animation Controllers untuk floating effect
  late AnimationController _floatingController1;
  late AnimationController _floatingController2;
  late AnimationController _floatingController3;
  late AnimationController _rotateController;
  late AnimationController _scaleController;

  // Animations
  late Animation<double> _floatingAnimation1;
  late Animation<double> _floatingAnimation2;
  late Animation<double> _floatingAnimation3;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      image: 'assets/images/kuas.png',
      title: 'Jelajahi Ruang Seni',
      description: 'Temukan inspirasi visual tanpa batas dari ribuan karya mahasiswa.',
      gradientColors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    ),
    OnboardingContent(
      image: 'assets/images/star.png',
      title: 'Panggung Karyamu',
      description: 'Ikuti Open Call, lewati kurasi, dan pamerkan karyamu di event bergengsi.',
      gradientColors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
    ),
    OnboardingContent(
      image: 'assets/images/scan.png',
      title: 'Scan & Pahami',
      description: 'Gunakan Smart Scanner untuk melihat cerita di balik lukisan fisik.',
      gradientColors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Floating Animation 1 (Slow)
    _floatingController1 = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation1 = Tween<double>(begin: -20, end: 20).animate(
      CurvedAnimation(parent: _floatingController1, curve: Curves.easeInOut),
    );

    // Floating Animation 2 (Medium)
    _floatingController2 = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation2 = Tween<double>(begin: -15, end: 15).animate(
      CurvedAnimation(parent: _floatingController2, curve: Curves.easeInOut),
    );

    // Floating Animation 3 (Fast)
    _floatingController3 = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation3 = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatingController3, curve: Curves.easeInOut),
    );

    // Rotate Animation
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 20000),
      vsync: this,
    )..repeat();

    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    // Scale Animation (Breathing effect)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatingController1.dispose();
    _floatingController2.dispose();
    _floatingController3.dispose();
    _rotateController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _contents.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: Stack(
        children: [
          // Ambient Light Background Effects
          _buildAmbientLights(),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Skip Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: _buildSkipButton(),
                  ),
                ),

                // PageView Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _contents.length,
                    itemBuilder: (context, index) {
                      return _buildPageContent(_contents[index], index);
                    },
                  ),
                ),

                // Bottom Section: Indicators + Button
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      _buildPageIndicators(),
                      const SizedBox(height: 32),
                      _buildActionButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientLights() {
    return Stack(
      children: [
        // Top Left Ambient Light
        Positioned(
          top: -100,
          left: -100,
          child: AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF6366F1).withOpacity(0.15),
                        Color(0xFF8B5CF6).withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom Right Ambient Light
        Positioned(
          bottom: -150,
          right: -150,
          child: AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_rotateAnimation.value,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFFEC4899).withOpacity(0.15),
                        Color(0xFFF59E0B).withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Center Floating Ambient Light
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          right: -100,
          child: AnimatedBuilder(
            animation: _floatingAnimation1,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingAnimation1.value),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF06B6D4).withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkipButton() {
    return GestureDetector(
      onTap: _completeOnboarding,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Text(
          'Lewati',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(OnboardingContent content, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated 3D Image with Multiple Effects
          AnimatedBuilder(
            animation: Listenable.merge([
              _floatingAnimation1,
              _floatingAnimation2,
              _floatingAnimation3,
              _scaleAnimation,
            ]),
            builder: (context, child) {
              // Select different floating animation based on page
              double floatValue = index == 0
                  ? _floatingAnimation1.value
                  : index == 1
                      ? _floatingAnimation2.value
                      : _floatingAnimation3.value;

              return Transform.translate(
                offset: Offset(0, floatValue),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          content.gradientColors[0].withOpacity(0.2),
                          content.gradientColors[1].withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        content.image,
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 60),

          // Title with Gradient Text
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: content.gradientColors,
            ).createShader(bounds),
            child: Text(
              content.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Description with Glass Background
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Text(
                  content.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _contents.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: _currentPage == index
                ? LinearGradient(
                    colors: _contents[index].gradientColors,
                  )
                : null,
            color: _currentPage == index
                ? null
                : Colors.white.withOpacity(0.2),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final isLastPage = _currentPage == _contents.length - 1;

    return GestureDetector(
      onTap: _nextPage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isLastPage
              ? LinearGradient(
                  colors: _contents[_currentPage].gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          border: !isLastPage
              ? Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                )
              : null,
          boxShadow: isLastPage
              ? [
                  BoxShadow(
                    color: _contents[_currentPage].gradientColors[0]
                        .withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isLastPage ? 0 : 10,
              sigmaY: isLastPage ? 0 : 10,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isLastPage
                    ? null
                    : Colors.white.withOpacity(0.05),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastPage ? 'Mulai Sekarang' : 'Lanjut',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastPage
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingContent {
  final String image;
  final String title;
  final String description;
  final List<Color> gradientColors;

  OnboardingContent({
    required this.image,
    required this.title,
    required this.description,
    required this.gradientColors,
  });
}
