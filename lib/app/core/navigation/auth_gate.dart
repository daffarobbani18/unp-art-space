import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../Features/auth/screens/login_page.dart';
import '../../Features/notifications/services/firebase_messaging_service.dart';
import 'main_page.dart';
import '../../../organizer/organizer_main_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final FirebaseMessagingService _fcmService = FirebaseMessagingService();
  bool _fcmInitialized = false;

  @override
  void initState() {
    super.initState();
    // Delay FCM init untuk memberi waktu Firebase fully initialize
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _initializeFCM();
      }
    });
  }

  Future<void> _initializeFCM() async {
    print('🔍 [AuthGate] _initializeFCM called');
    print('🔍 [AuthGate] _fcmInitialized: $_fcmInitialized');
    print('🔍 [AuthGate] kIsWeb: $kIsWeb');
    
    if (_fcmInitialized || kIsWeb) {
      print('⏭️ [AuthGate] Skipping FCM init (already initialized or web)');
      return;
    }
    
    final session = Supabase.instance.client.auth.currentSession;
    print('🔍 [AuthGate] Session exists: ${session != null}');
    
    if (session != null) {
      print('🚀 [AuthGate] Initializing FCM service...');
      try {
        await _fcmService.initialize();
        if (!mounted) return;
        setState(() {
          _fcmInitialized = true;
        });
        print('✅ [AuthGate] FCM initialized successfully');
      } catch (e) {
        print('❌ [AuthGate] Error initializing FCM: $e');
        
        // Retry after 3 seconds if failed
        print('🔄 [AuthGate] Will retry FCM init in 3 seconds...');
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && !_fcmInitialized) {
            print('🔄 [AuthGate] Retrying FCM initialization...');
            _fcmInitialized = false; // Reset flag
            _initializeFCM();
          }
        });
      }
    } else {
      print('⚠️ [AuthGate] No session, FCM not initialized');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Initialize FCM saat user login
        if (snapshot.hasData && snapshot.data?.session != null && !_fcmInitialized && !kIsWeb) {
          _initializeFCM();
        }
        
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
