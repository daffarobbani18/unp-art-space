import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project1/app/Features/auth/screens/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../main/main_app.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

enum UserRole { artist, viewer }

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  UserRole? _selectedRole = UserRole.viewer;
  String? _selectedSpecialization;
  final List<String> _specializations = [
    'Pelukis', 'Fotografer', 'Ilustrator', 'Videografer', 'Desainer Grafis', 'Musisi'
  ];

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
  _namaController.dispose();
  _emailController.dispose();
  _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // 1. Buat user baru di Supabase Authentication
        final authResponse = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Jika pendaftaran di Auth berhasil & ada user yang dibuat
        if (authResponse.user != null) {
          final user = authResponse.user!;
          // Perbaiki: enum UserRole hanya punya 'artist' dan 'viewer'
          final roleString = _selectedRole == UserRole.artist ? 'artist' : 'viewer';

          // 2. Simpan data tambahan ke tabel 'users' di database
          await supabase.from('users').insert({
            'id': user.id, // Gunakan ID dari Auth sebagai Primary Key
            'name': _namaController.text.trim(),
            'email': _emailController.text.trim(),
            'role': roleString,
            'specialization': _selectedSpecialization,
          });

          Navigator.of(context).pop(); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registrasi berhasil! Silakan cek email untuk verifikasi.')),
          );
        }
      } on AuthException catch (e) {
        Navigator.of(context).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registrasi Gagal: ${e.message}')),
        );
      } catch (e) {
        Navigator.of(context).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF8F7FA);
    const deepBlue = Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 280,
              child: ClipPath(
                clipper: _HeaderWaveClipper(),
                child: Container(
                  height: 280,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E3A8A), Color(0xFF9333EA)],
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/images/logo_unp_art_space - cut.jpg',
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Daftar Akun',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 18),

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _namaController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.person_outline, color: deepBlue),
                                labelText: 'Nama Lengkap',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Masukkan nama lengkap' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email_outlined, color: deepBlue),
                                labelText: 'Email',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Masukkan email';
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Email tidak valid';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline, color: deepBlue),
                                labelText: 'Password',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              obscureText: true,
                              validator: (value) => value == null || value.length < 6 ? 'Minimal 6 karakter' : null,
                            ),
                            const SizedBox(height: 16),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Pilih Role:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800])),
                            ),
                            Column(
                              children: [
                                RadioListTile<UserRole>(
                                  value: UserRole.viewer,
                                  groupValue: _selectedRole,
                                  title: const Text('Viewer'),
                                  onChanged: (value) => setState(() => _selectedRole = value),
                                ),
                                RadioListTile<UserRole>(
                                  value: UserRole.artist,
                                  groupValue: _selectedRole,
                                  title: const Text('Artist'),
                                  onChanged: (value) => setState(() => _selectedRole = value),
                                ),

                                if (_selectedRole == UserRole.artist)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedSpecialization,
                                      decoration: InputDecoration(
                                        labelText: 'Pilih Spesialisasi',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      items: _specializations.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                                      onChanged: (newValue) => setState(() => _selectedSpecialization = newValue),
                                      validator: (value) => value == null ? 'Spesialisasi wajib dipilih' : null,
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: deepBlue,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                                      const SizedBox(width: 12),
                                      const Text('Mendaftar...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ])
                                  : const Text('Daftar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),

                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginPage()));
                                    },
                              child: const Text('Sudah punya akun? Login'),
                            ),
                          ],
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
    );
  }
}

// Reuse clipper from login
class _HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height - 40);
    path.quadraticBezierTo(size.width * 0.75, size.height - 80, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
