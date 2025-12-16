import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

/// Dialog yang muncul otomatis di web untuk memberi tahu user
/// bahwa aplikasi ini dioptimalkan untuk mobile
class MobileOnlyDialog {
  static bool _hasShown = false;

  /// Tampilkan dialog jika di web dan belum pernah ditampilkan
  static void showIfWeb(BuildContext context) {
    if (kIsWeb && !_hasShown) {
      _hasShown = true;

      // Delay sedikit agar UI sudah ter-render
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const _MobileOnlyDialogWidget(),
          );
        }
      });
    }
  }

  /// Reset flag untuk testing
  static void reset() {
    _hasShown = false;
  }
}

class _MobileOnlyDialogWidget extends StatelessWidget {
  const _MobileOnlyDialogWidget();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 380;

    // Responsive values
    final horizontalPadding = isMobile ? 16.0 : 24.0;
    final verticalPadding = isMobile ? 16.0 : 24.0;
    final iconSize = isSmallMobile ? 40.0 : (isMobile ? 44.0 : 48.0);
    final titleSize = isSmallMobile ? 20.0 : (isMobile ? 22.0 : 24.0);
    final bodySize = isSmallMobile ? 13.0 : (isMobile ? 14.0 : 15.0);
    final buttonPadding = isMobile ? 12.0 : 14.0;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : 40.0,
          vertical: isMobile ? 24.0 : 40.0,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? screenWidth - 32 : 500,
            maxHeight: screenHeight - (isMobile ? 48 : 80),
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            ),
            borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9333EA).withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header dengan icon
                Container(
                  padding: EdgeInsets.all(verticalPadding),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF9333EA).withOpacity(0.2),
                        const Color(0xFF3B82F6).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isMobile ? 20 : 24),
                      topRight: Radius.circular(isMobile ? 20 : 24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Icon smartphone dengan efek glow
                      Container(
                        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF9333EA).withOpacity(0.3),
                              const Color(0xFF3B82F6).withOpacity(0.3),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFF9333EA).withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9333EA).withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.smartphone_rounded,
                          size: iconSize,
                          color: const Color(0xFF9333EA),
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      Text(
                        '📱 Aplikasi Mobile',
                        style: GoogleFonts.poppins(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    children: [
                      Text(
                        'UNP Art Space adalah aplikasi mobile yang dioptimalkan untuk perangkat smartphone dan tablet.',
                        style: GoogleFonts.poppins(
                          fontSize: bodySize,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isMobile ? 16 : 20),

                      // Info cards
                      _buildInfoCard(
                        context: context,
                        isMobile: isMobile,
                        isSmallMobile: isSmallMobile,
                        icon: Icons.phone_android_rounded,
                        title: 'Pengalaman Terbaik di Mobile',
                        description:
                            'Aplikasi ini dirancang khusus untuk memberikan pengalaman terbaik di perangkat mobile.',
                      ),
                      SizedBox(height: isMobile ? 10 : 12),
                      _buildInfoCard(
                        context: context,
                        isMobile: isMobile,
                        isSmallMobile: isSmallMobile,
                        icon: Icons.desktop_windows_rounded,
                        title: 'Versi Web Belum Optimal',
                        description:
                            'Tampilan dan fitur di browser belum sepenuhnya responsif dan mungkin tidak berfungsi dengan baik.',
                      ),
                      SizedBox(height: isMobile ? 10 : 12),
                      _buildInfoCard(
                        context: context,
                        isMobile: isMobile,
                        isSmallMobile: isSmallMobile,
                        icon: Icons.download_rounded,
                        title: 'Download Aplikasi Mobile',
                        description:
                            'Untuk pengalaman optimal, silakan unduh aplikasi mobile kami di Google Play Store atau App Store.',
                      ),

                      SizedBox(height: isMobile ? 20 : 24),

                      // Action buttons
                      isMobile
                          ? Column(
                              children: [
                                // Download button (primary)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      // TODO: Link ke download page atau store
                                    },
                                    icon: Icon(
                                      Icons.download_rounded,
                                      size: isSmallMobile ? 16 : 18,
                                    ),
                                    label: Text(
                                      'Download App',
                                      style: GoogleFonts.poppins(
                                        fontSize: isSmallMobile ? 12 : 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF9333EA),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: buttonPadding,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                // Continue button (secondary)
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pop(context),
                                    icon: Icon(
                                      Icons.close,
                                      size: isSmallMobile ? 16 : 18,
                                    ),
                                    label: Text(
                                      'Lanjutkan di Browser',
                                      style: GoogleFonts.poppins(
                                        fontSize: isSmallMobile ? 12 : 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      padding: EdgeInsets.symmetric(
                                        vertical: buttonPadding,
                                      ),
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: Text(
                                      'Lanjutkan di Browser',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      // TODO: Link ke download page atau store
                                    },
                                    icon: const Icon(
                                      Icons.download_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Download App',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF9333EA),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                      SizedBox(height: isMobile ? 10 : 12),

                      Text(
                        'Pesan ini hanya muncul sekali',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallMobile ? 11 : 12,
                          color: Colors.white.withOpacity(0.5),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required bool isMobile,
    required bool isSmallMobile,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final cardPadding = isSmallMobile ? 10.0 : (isMobile ? 11.0 : 12.0);
    final iconBoxPadding = isSmallMobile ? 6.0 : 8.0;
    final iconSize = isSmallMobile ? 18.0 : 20.0;
    final titleSize = isSmallMobile ? 12.0 : 13.0;
    final descSize = isSmallMobile ? 11.0 : 12.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(iconBoxPadding),
            decoration: BoxDecoration(
              color: const Color(0xFF9333EA).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: iconSize, color: const Color(0xFF9333EA)),
          ),
          SizedBox(width: isMobile ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: descSize,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
