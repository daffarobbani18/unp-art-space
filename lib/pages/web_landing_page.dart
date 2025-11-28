import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

class WebLandingPage extends StatefulWidget {
  const WebLandingPage({super.key});

  @override
  State<WebLandingPage> createState() => _WebLandingPageState();
}

class _WebLandingPageState extends State<WebLandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  // URL placeholder untuk download APK
  final String _apkDownloadUrl =
      'https://vepmvxiddwmpetxfdwjn.supabase.co/storage/v1/object/public/downloads/app-release.apk';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _downloadAPK() async {
    try {
      final uri = Uri.parse(_apkDownloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka link download'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: Stack(
        children: [
          // Ambient Background Blobs
          _buildAmbientBackground(),

          // Scrollable Content
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // A. Header / Navbar
                _buildNavbar(context),

                // B. Hero Section
                _buildHeroSection(context),

                // C. Features Section
                _buildFeaturesSection(context),

                // D. CTA Section
                _buildCTASection(context),

                // E. Footer
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // AMBIENT BACKGROUND
  // ============================================
  Widget _buildAmbientBackground() {
    return Stack(
      children: [
        // Blob 1: Purple Top Right
        Positioned(
          top: -150,
          right: -150,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 20),
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 6.28,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6366F1).withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
            onEnd: () {
              if (mounted) setState(() {});
            },
          ),
        ),

        // Blob 2: Cyan Bottom Left
        Positioned(
          bottom: -200,
          left: -200,
          child: TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 25),
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: -value * 6.28,
                child: Container(
                  width: 600,
                  height: 600,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF06B6D4).withOpacity(0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
            onEnd: () {
              if (mounted) setState(() {});
            },
          ),
        ),

        // Blob 3: Orange Center
        Positioned(
          top: 300,
          right: 100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFF59E0B).withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // A. NAVBAR (STICKY HEADER)
  // ============================================
  Widget _buildNavbar(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C).withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo & Text
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.palette_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Campus Art Space',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              // Desktop Navigation Links (Center)
              if (isDesktop)
                Row(
                  children: [
                    _navLink('Beranda', () {}),
                    const SizedBox(width: 32),
                    _navLink('Fitur', () {}),
                    const SizedBox(width: 32),
                    _navLink('Tentang', () {}),
                  ],
                ),

              // Right Buttons
              Row(
                children: [
                  TextButton(
                    onPressed: _navigateToLogin,
                    child: Text(
                      'Masuk',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _downloadAPK,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ).copyWith(
                      backgroundColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Download App',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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

  Widget _navLink(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white.withOpacity(0.8),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================
  // B. HERO SECTION
  // ============================================
  Widget _buildHeroSection(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: isDesktop ? 120 : 80,
      ),
      child: FadeTransition(
        opacity: _animationController,
        child: isDesktop
            ? Row(
                children: [
                  // Left: Text Content
                  Expanded(
                    flex: 6,
                    child: _buildHeroContent(isDesktop),
                  ),

                  const SizedBox(width: 80),

                  // Right: Illustration/Mockup
                  Expanded(
                    flex: 5,
                    child: _buildHeroIllustration(),
                  ),
                ],
              )
            : Column(
                children: [
                  _buildHeroContent(isDesktop),
                  const SizedBox(height: 48),
                  _buildHeroIllustration(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeroContent(bool isDesktop) {
    return Column(
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        // Headline
        Text(
          'Galeri Seni Digital &\nManajemen Pameran Kampus',
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: isDesktop ? 56 : 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
            letterSpacing: -1,
          ),
        ),

        const SizedBox(height: 24),

        // Sub-headline
        Text(
          'Platform terintegrasi untuk mahasiswa seni, organizer event, dan penikmat karya. Terhubung via QR Code.',
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: isDesktop ? 18 : 16,
            color: Colors.white.withOpacity(0.7),
            height: 1.6,
          ),
        ),

        const SizedBox(height: 40),

        // Action Buttons
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment:
              isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            // Button 1: Download APK
            ElevatedButton.icon(
              onPressed: _downloadAPK,
              icon: const Icon(Icons.android_rounded, size: 24),
              label: Text(
                'Download .APK',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),

            // Button 2: Mulai di Web
            OutlinedButton.icon(
              onPressed: _navigateToLogin,
              icon: const Icon(Icons.language_rounded, size: 24),
              label: Text(
                'Mulai di Web',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroIllustration() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 60,
            spreadRadius: 20,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smartphone_rounded,
                    size: 120,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Mobile App',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Available on Android',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // C. FEATURES SECTION
  // ============================================
  Widget _buildFeaturesSection(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: isDesktop ? 100 : 60,
      ),
      color: Colors.black.withOpacity(0.2),
      child: Column(
        children: [
          // Section Title
          Text(
            'Fitur Unggulan',
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 48 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Platform lengkap untuk ekosistem seni kampus',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.white.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 64),

          // Features Grid
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 600
                      ? 2
                      : 1;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 32,
                mainAxisSpacing: 32,
                childAspectRatio: 1,
                children: [
                  _buildFeatureCard(
                    icon: Icons.photo_library_rounded,
                    title: 'Digital Gallery',
                    description:
                        'Upload dan pamerkan portofolio seni terbaikmu.',
                    gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  _buildFeatureCard(
                    icon: Icons.event_rounded,
                    title: 'Event Management',
                    description:
                        'Kelola pameran, Open Call, dan Kurasi secara digital.',
                    gradient: const [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  ),
                  _buildFeatureCard(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'QR Integration',
                    description:
                        'Jembatan fisik-digital. Scan karya di galeri nyata untuk info detail.',
                    gradient: const [Color(0xFFF59E0B), Color(0xFFEA580C)],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradient,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 40),
              ),

              const SizedBox(height: 24),

              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // D. CTA SECTION
  // ============================================
  Widget _buildCTASection(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: isDesktop ? 100 : 60,
      ),
      padding: EdgeInsets.all(isDesktop ? 80 : 40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 40,
            spreadRadius: 10,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Siap Berkarya atau Mengapresiasi?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 40 : 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Bergabunglah dengan komunitas seni UNP sekarang',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
            ),
          ),

          const SizedBox(height: 40),

          ElevatedButton.icon(
            onPressed: _downloadAPK,
            icon: const Icon(Icons.download_rounded, size: 28),
            label: Text(
              'Download Sekarang',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6366F1),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 32,
                vertical: isDesktop ? 24 : 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // E. FOOTER
  // ============================================
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Social Media Icons (Placeholder)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialIcon(Icons.facebook_rounded),
              const SizedBox(width: 16),
              _socialIcon(Icons.facebook_rounded), // Instagram placeholder
              const SizedBox(width: 16),
              _socialIcon(Icons.facebook_rounded), // Twitter placeholder
            ],
          ),

          const SizedBox(height: 24),

          // Copyright
          Text(
            '© 2025 Campus Art Space. All Rights Reserved.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Universitas Negeri Padang',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white.withOpacity(0.7),
        size: 20,
      ),
    );
  }
}
