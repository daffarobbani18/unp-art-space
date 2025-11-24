import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_main_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1E3A8A);
    const primaryPurple = Color(0xFF9333EA);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [primaryBlue, primaryPurple]),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo & Brand Container (White Box)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 100, maxWidth: 100),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Image.asset(
                                'assets/images/logo_app.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold),
                              children: [
                                TextSpan(text: 'UNP ', style: TextStyle(color: primaryBlue)),
                                TextSpan(text: 'ART SPACE', style: TextStyle(color: primaryPurple)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryBlue.withOpacity(0.1), primaryPurple.withOpacity(0.1)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryBlue.withOpacity(0.3), width: 1),
                            ),
                            child: Text('Admin Panel', style: GoogleFonts.poppins(fontSize: 12, color: primaryBlue, fontWeight: FontWeight.w600)),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      constraints: const BoxConstraints(maxWidth: 480),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 12))]),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Form(
                          key: _formKey,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            Text('Admin Login', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                            const SizedBox(height: 6),
                            Text('Masuk sebagai Administrator', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
                            const SizedBox(height: 22),

                            Text('Email', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(hintText: 'example@domain.com', hintStyle: GoogleFonts.poppins(color: Colors.grey[400]), filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryBlue.withOpacity(0.9), width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                                if (!value.contains('@')) return 'Format email tidak valid';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text('Password', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                              TextButton(onPressed: () {}, style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap), child: Text('Forgot ?', style: GoogleFonts.poppins(fontSize: 12, color: primaryBlue)))
                            ]),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(hintText: 'Enter your password', hintStyle: GoogleFonts.poppins(color: Colors.grey[400]), filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryPurple.withOpacity(0.9), width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), suffixIcon: IconButton(icon: Icon(_isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey[500]), onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible))),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
                                if (value.length < 6) return 'Password minimal 6 karakter';
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),

                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                                child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : Text('Login now', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ]),
                        ),
                      ),
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
