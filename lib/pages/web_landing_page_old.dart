import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

class WebLandingPage extends StatefulWidget {
  const WebLandingPage({super.key});

  @override
  State<WebLandingPage> createState() => _WebLandingPageState();
}

class _WebLandingPageState extends State<WebLandingPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  bool _isDownloading = false;
  
  // URL placeholder untuk download APK
  final String _apkDownloadUrl = 'https://vepmvxiddwmpetxfdwjn.supabase.co/storage/v1/object/public/downloads/app-release.apk';

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _downloadAPK() async {
    setState(() => _isDownloading = true);

    try {
      final uri = Uri.parse(_apkDownloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Download dimulai! Periksa folder Downloads Anda.',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw 'Tidak dapat membuka URL download';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gagal memulai download: $e',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 1024;

    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 24 : 48,
                  vertical: 32,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo Container
                        _buildLogo(isSmallScreen),
                        
                        SizedBox(height: isSmallScreen ? 32 : 48),

                        // Title
                        _buildTitle(isSmallScreen),

                        SizedBox(height: isSmallScreen ? 16 : 24),

                        // Description
                        _buildDescription(isSmallScreen, isMediumScreen),

                        SizedBox(height: isSmallScreen ? 40 : 56),

                        // Download Button
                        _buildDownloadButton(isSmallScreen),

                        SizedBox(height: isSmallScreen ? 24 : 32),

                        // Features
                        _buildFeatures(isSmallScreen, isMediumScreen),

                        SizedBox(height: isSmallScreen ? 48 : 64),

                        // Footer
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1E2C),
            Color(0xFF2D2D44),
            Color(0xFF1E1E2C),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Rotating Gradient Circles
          Positioned(
            top: -100,
            right: -100,
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 20),
              builder: (context, double value, child) {
                return Transform.rotate(
                  angle: value * 6.28,
                  child: Container(
                    width: 400,
                    height: 400,
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
                // Loop animation
                if (mounted) setState(() {});
              },
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 15),
              builder: (context, double value, child) {
                return Transform.rotate(
                  angle: -value * 6.28,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF8B5CF6).withOpacity(0.3),
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
        ],
      ),
    );
  }

  Widget _buildLogo(bool isSmallScreen) {
    return Container(
      width: isSmallScreen ? 120 : 160,
      height: isSmallScreen ? 120 : 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.5),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1000),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.palette_rounded,
              size: isSmallScreen ? 60 : 80,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(bool isSmallScreen) {
    return Text(
      'Campus Art Space',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: isSmallScreen ? 40 : 64,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
        letterSpacing: -1,
      ),
    );
  }

  Widget _buildDescription(bool isSmallScreen, bool isMediumScreen) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: isSmallScreen ? 400 : (isMediumScreen ? 600 : 700),
      ),
      child: Text(
        'Galeri Seni Digital & Manajemen Pameran\nUniversitas Negeri Padang',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: isSmallScreen ? 16 : 20,
          color: Colors.white.withOpacity(0.8),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildDownloadButton(bool isSmallScreen) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isDownloading ? null : _downloadAPK,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 32 : 48,
                vertical: isSmallScreen ? 18 : 24,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isDownloading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    const Icon(
                      Icons.android,
                      color: Colors.white,
                      size: 28,
                    ),
                  const SizedBox(width: 12),
                  Text(
                    _isDownloading ? 'Memulai Download...' : 'Download Aplikasi Android',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatures(bool isSmallScreen, bool isMediumScreen) {
    final features = [
      {
        'icon': Icons.art_track_rounded,
        'title': 'Galeri Digital',
        'desc': 'Jelajahi karya seni dari mahasiswa UNP',
      },
      {
        'icon': Icons.event_rounded,
        'title': 'Event Pameran',
        'desc': 'Ikuti pameran seni virtual & offline',
      },
      {
        'icon': Icons.people_rounded,
        'title': 'Komunitas',
        'desc': 'Terhubung dengan seniman lainnya',
      },
    ];

    return Container(
      constraints: BoxConstraints(maxWidth: isSmallScreen ? 500 : 1000),
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.center,
        children: features.map((feature) {
          return SizedBox(
            width: isSmallScreen ? double.infinity : (isMediumScreen ? 250 : 280),
            child: _buildFeatureCard(
              feature['icon'] as IconData,
              feature['title'] as String,
              feature['desc'] as String,
              isSmallScreen,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String desc, bool isSmallScreen) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.2),
                      const Color(0xFF8B5CF6).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF8B5CF6), size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
        const SizedBox(height: 16),
        Text(
          '© 2025 Campus Art Space. All rights reserved.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.5),
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
    );
  }
}
