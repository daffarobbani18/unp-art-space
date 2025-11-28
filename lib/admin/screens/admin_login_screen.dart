import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_main_screen.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_text_field.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> 
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _floatController;
  late final AnimationController _scaleController;
  
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _floatAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
    
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _floatController.dispose();
    _scaleController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Login dengan Supabase Auth
      final authResponse = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (authResponse.user == null) throw Exception('Login gagal');

      // 2. Cek role di tabel profiles (gunakan maybeSingle untuk handle jika data tidak ada)
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', authResponse.user!.id)
          .maybeSingle();

      // 3. Validasi apakah profile ada dan role adalah admin
      if (profileResponse == null) {
        await Supabase.instance.client.auth.signOut();
        throw Exception('Akses Ditolak: Profile tidak ditemukan. Pastikan Anda sudah terdaftar sebagai admin.');
      }

      final role = profileResponse['role'] as String?;
      
      if (role != 'admin') {
        await Supabase.instance.client.auth.signOut();
        throw Exception('Akses Ditolak: Anda bukan administrator');
      }

      // 4. Navigasi ke dashboard admin
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminMainScreen()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) _showErrorDialog('Login Error: ${e.message}');
    } catch (e) {
      if (mounted) _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Auto-fill credentials untuk testing
  void _autoFillAdminCredentials() {
    setState(() {
      _emailController.text = 'admin@campus.art';
      _passwordController.text = 'admin123';
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GlassButton(
                text: 'OK',
                onPressed: () => Navigator.pop(context),
                type: GlassButtonType.primary,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Floating Logo
                        AnimatedBuilder(
                          animation: _floatAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatAnimation.value),
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF8B5CF6),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo_app.png',
                              width: 80,
                              height: 80,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Title
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6),
                              Color(0xFFEC4899),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'CAMPUS ART SPACE',
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            'Admin Panel',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Login Form
                        GlassCard(
                          padding: const EdgeInsets.all(32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Admin Login',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Masuk sebagai Administrator',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                
                                // Development Mode - Auto Fill
                                _buildDevelopmentMode(),
                                
                                const SizedBox(height: 24),
                                
                                GlassTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  hint: 'example@domain.com',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email tidak boleh kosong';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Format email tidak valid';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                
                                GlassTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  hint: 'Masukkan password',
                                  prefixIcon: Icons.lock_outline,
                                  suffixIcon: _isPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  onSuffixTap: () => setState(
                                    () => _isPasswordVisible = !_isPasswordVisible,
                                  ),
                                  obscureText: !_isPasswordVisible,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password tidak boleh kosong';
                                    }
                                    if (value.length < 6) {
                                      return 'Password minimal 6 karakter';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),
                                
                                GlassButton(
                                  text: 'Login Sekarang',
                                  onPressed: _handleLogin,
                                  type: GlassButtonType.primary,
                                  icon: Icons.login,
                                  isLoading: _isLoading,
                                  width: double.infinity,
                                  height: 54,
                                  fontSize: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          '© 2024 Campus Art Space. All rights reserved.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.4),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDevelopmentMode() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.greenAccent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.developer_mode,
                color: Colors.greenAccent,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Mode Development',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _autoFillAdminCredentials,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Text(
                'Admin',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Klik untuk auto-fill admin credentials',
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
