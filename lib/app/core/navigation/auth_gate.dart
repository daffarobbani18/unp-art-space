import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Features/auth/screens/login_page.dart';
import 'main_page.dart';
import '../../../organizer/organizer_main_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Tampilkan loading dengan splash screen yang bagus
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.deepPurple[800],
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.palette,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Campus Art Space',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          );
        }

        // Periksa apakah user sudah login
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          // User sudah login, cek role untuk routing
          return FutureBuilder<Map<String, dynamic>?>(
            future: _getUserRole(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: const Color(0xFF1E1E2C),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Memuat data...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (roleSnapshot.hasError || roleSnapshot.data == null) {
                // Jika error atau tidak ada data, tetap ke MainPage
                return const MainPage();
              }

              final role = roleSnapshot.data!['role'] as String?;

              // Routing berdasarkan role
              if (role == 'organizer') {
                return const OrganizerMainScreen();
              } else {
                // Default untuk admin, artist, viewer
                return const MainPage();
              }
            },
          );
        } else {
          // User belum login
          return const LoginPage();
        }
      },
    );
  }

  Future<Map<String, dynamic>?> _getUserRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return null;
    }
  }
}
