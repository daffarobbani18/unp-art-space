import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/navigation/auth_gate.dart';
import 'edit_profile_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => _buildLogoutDialog(context),
    );

    if (shouldLogout == true && context.mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );

      try {
        // Perform logout - wrap in try-catch to prevent crash
        try {
          await Supabase.instance.client.auth.signOut().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('Logout timeout, continuing anyway');
              return null; // Return null on timeout instead of throwing
            },
          );
        } catch (signOutError) {
          // Silently handle signOut errors - local logout will still work
          debugPrint('SignOut error (continuing): $signOutError');
        }

        // Small delay to ensure cleanup
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        // Catch any other errors
        debugPrint('Logout process error: $e');
      }

      // Always navigate to login regardless of logout success/failure
      if (context.mounted) {
        // Close loading dialog
        Navigator.of(context).pop();
      }

      // Small delay before navigation
      await Future.delayed(const Duration(milliseconds: 50));

      // Navigate to AuthGate (this will clear session and show login)
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AuthGate(),
          ),
          (route) => false,
        );
      }
    }
  }

  Widget _buildLogoutDialog(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout,
                size: 48,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Konfirmasi Logout',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Apakah Anda yakin ingin keluar dari akun?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildDialogButton(
                      context: context,
                      label: 'Batal',
                      onPressed: () => Navigator.of(context).pop(false),
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDialogButton(
                      context: context,
                      label: 'Keluar',
                      onPressed: () => Navigator.of(context).pop(true),
                      isPrimary: true,
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

  Widget _buildDialogButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary
                ? Colors.red.withOpacity(0.3)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary
                  ? Colors.red.withOpacity(0.5)
                  : Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isPrimary ? Colors.red[200] : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1E2C),
                  Color(0xFF2D1B69),
                  Color(0xFF1E1E2C),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with back button
                    Row(
                      children: [
                        _buildBackButton(context),
                        const SizedBox(width: 16),
                        Text(
                          'Pengaturan',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Manajemen Akun Section
                    _buildSectionTitle('Manajemen Akun'),
                    const SizedBox(height: 12),
                    _buildGlassMenuItem(
                      icon: Icons.person_outline,
                      title: 'Edit Profil',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EditProfilePage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildGlassMenuItem(
                      icon: Icons.lock_outline,
                      title: 'Ganti Password',
                      onTap: () {
                        // TODO: Navigate to change password page
                      },
                    ),
                    const SizedBox(height: 32),

                    // Notifikasi Section
                    _buildSectionTitle('Notifikasi'),
                    const SizedBox(height: 12),
                    _buildGlassMenuItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifikasi Push',
                      onTap: () {
                        // TODO: Navigate to notification settings
                      },
                    ),
                    const SizedBox(height: 32),

                    // Tentang Section
                    _buildSectionTitle('Tentang'),
                    const SizedBox(height: 12),
                    _buildGlassMenuItem(
                      icon: Icons.info_outline,
                      title: 'Tentang Aplikasi',
                      onTap: () {
                        // TODO: Navigate to about page
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildGlassMenuItem(
                      icon: Icons.help_outline,
                      title: 'Bantuan & Dukungan',
                      onTap: () {
                        // TODO: Navigate to help page
                      },
                    ),
                    const SizedBox(height: 32),

                    // Logout Section
                    _buildSectionTitle('Akun'),
                    const SizedBox(height: 12),
                    _buildLogoutMenuItem(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGlassMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withOpacity(0.5),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutMenuItem(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleLogout(context),
        borderRadius: BorderRadius.circular(15),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.logout,
                      color: Colors.red[200],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Log Out',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[200],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.red.withOpacity(0.5),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}