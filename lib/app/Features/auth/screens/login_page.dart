import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_page.dart';
import '../../../core/navigation/main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _animController.forward());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

Future<void> _login() async {
  if (!_formKey.currentState!.validate()) return;
  if (!mounted) return;
  
  setState(() => _isLoading = true);

  try {
    final supabase = Supabase.instance.client;
    
    // Add timeout to prevent infinite loading
    final response = await supabase.auth.signInWithPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('Koneksi timeout. Periksa koneksi internet Anda.');
      },
    );

    if (!mounted) return;

    final user = response.user;
    if (user == null) {
      throw Exception('Login gagal. User tidak ditemukan.');
    }

    // Cek verifikasi email
    if (user.emailConfirmedAt == null) {
      // Logout user yang belum verifikasi
      await supabase.auth.signOut();
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Akun belum aktif. Silakan verifikasi email Anda terlebih dahulu.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ));
      }
      return; // Stop execution
    }

    // Login berhasil dan email sudah diverifikasi
    if (mounted) {
      // Cek role user untuk routing
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      
      if (!mounted) return;
      
      final role = profile?['role'] as String?;
      
      // Navigate berdasarkan role
      if (role == 'organizer') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
        if (mounted) {
          Future.delayed(Duration.zero, () {
            Navigator.of(context).pushReplacementNamed('/organizer_home');
          });
        }
      } else {
        // Default untuk admin, artist, viewer - ke MainPage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Login berhasil!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ));
      }
    }

  } on AuthException catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login Gagal: ${e.message}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  void _goToRegister() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
  }

  // Auto-fill credentials untuk testing
  void _autoFillCredentials(String role) {
    setState(() {
      switch (role) {
        case 'Viewer':
          _emailController.text = 'viewer@campus.art';
          _passwordController.text = 'viewer123';
          break;
        case 'Artist':
          _emailController.text = 'artist@campus.art';
          _passwordController.text = 'artist123';
          break;
        case 'Event Organizer':
          _emailController.text = 'organizer@campus.art';
          _passwordController.text = 'organizer123';
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        margin: const EdgeInsets.all(10),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white24,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
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
            Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _buildGlassCard(context),
                  ),
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(32),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.asset(
                        'assets/images/logo_app.png',
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Selamat Datang',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Development Mode - Auto Fill
              _buildDevelopmentMode(),
              const SizedBox(height: 24),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildGlassTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || v.isEmpty ? 'Email wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildGlassTextField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (v) => v == null || v.length < 6 ? 'Minimal 6 karakter' : null,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          'Lupa Kata Sandi?',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Login Button (Gradient)
                    _buildGradientButton(
                      onPressed: _isLoading ? null : _login,
                      label: 'Login',
                      isLoading: _isLoading,
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'atau',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Google Button (White Glass)
                    _buildGlassGoogleButton(),

                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: _goToRegister,
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            children: [
                              const TextSpan(text: 'Belum punya akun? '),
                              TextSpan(
                                text: 'Daftar',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: Colors.white70,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.white, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: GoogleFonts.poppins(
          color: Colors.red[200],
          fontSize: 12,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDevelopmentMode() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.developer_mode,
                color: Colors.greenAccent,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Mode Development - Auto Fill:',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildAutoFillButton(
                  label: 'Viewer',
                  color: const Color(0xFF9333EA), // Purple
                  onTap: () => _autoFillCredentials('Viewer'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildAutoFillButton(
                  label: 'Artist',
                  color: const Color(0xFF3B82F6), // Blue
                  onTap: () => _autoFillCredentials('Artist'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildAutoFillButton(
                  label: 'Organizer',
                  color: const Color(0xFFEA580C), // Orange
                  onTap: () => _autoFillCredentials('Event Organizer'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Klik untuk auto-fill, lalu Login',
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAutoFillButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required String label,
    required bool isLoading,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9333EA), Color(0xFF3B82F6)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildGlassGoogleButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_google.png',
                height: 22,
              ),
              const SizedBox(width: 12),
              Text(
                'Login dengan Google',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
