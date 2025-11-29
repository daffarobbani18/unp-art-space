//File main untuk aplikasi mobile (pengguna)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_strategy/url_strategy.dart';
import '../app/core/screens/splash_screen.dart';
import '../organizer/organizer_main_screen.dart';
import '../app/Features/artwork/screens/artwork_detail_page.dart';
import '../app/Features/notifications/services/firebase_messaging_service.dart';
import 'package:project1/app/core/utils/http_overrides.dart';
import '../app/Features/auth/screens/login_page.dart';
import '../pages/web_landing_page.dart';
import '../app/core/navigation/main_page.dart';
import '../admin/screens/admin_login_screen.dart';

// Variabel global untuk akses Supabase client di seluruh aplikasi
late final SupabaseClient supabase;

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📬 Background message: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Remove # from URL for web
  if (kIsWeb) {
    setPathUrlStrategy();
  }

  HttpOverrides.global = MyHttpOverrides();

  // Inisialisasi locale Indonesian untuk intl package
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Firebase (hanya untuk mobile)
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      debugPrint('✅ Firebase initialized');
    } catch (e) {
      debugPrint('❌ Firebase initialization error: $e');
    }
  }

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://vepmvxiddwmpetxfdwjn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZlcG12eGlkZHdtcGV0eGZkd2puIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0MjM5MjAsImV4cCI6MjA3NDk5OTkyMH0.x9KuPmzMUZosRChrYZHptlJylD4To9hzZ3YEQHXwvgA',
  );

  // Set variabel global supabase
  supabase = Supabase.instance.client;

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Art Space',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      // Remove fixed home to allow deep linking
      // home: const SplashScreen(),
      initialRoute: '/',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const MainPage(),
        '/organizer_home': (context) => const OrganizerMainScreen(),
        '/admin': (context) => const AdminLoginScreen(),
      },
      onGenerateRoute: (settings) {
        debugPrint('🔗 Navigation to: ${settings.name}');
        
        // Parse URI for better route handling
        final uri = Uri.parse(settings.name ?? '/');
        
        // ============================================
        // PLATFORM-AWARE ROOT ROUTE HANDLING
        // ============================================
        if (uri.path == '/') {
          if (kIsWeb) {
            // Web Browser: Show Landing Page with Download Button
            debugPrint('🌐 Web detected: Showing Landing Page');
            return MaterialPageRoute(
              builder: (context) => const WebLandingPage(),
              settings: settings,
            );
          } else {
            // Mobile App: Show Splash Screen
            debugPrint('📱 Mobile detected: Showing Splash Screen');
            return MaterialPageRoute(
              builder: (context) => const SplashScreen(),
              settings: settings,
            );
          }
        }
        
        // ============================================
        // DEEP LINK: /submission/{uuid}
        // QR Code dari Event Submissions
        // ============================================
        if (uri.path.startsWith('/submission/')) {
          final submissionId = uri.path.replaceFirst('/submission/', '');
          
          if (submissionId.isNotEmpty) {
            debugPrint('✅ Deep link detected: submission/$submissionId');
            return MaterialPageRoute(
              builder: (context) => ArtworkDetailPage.fromSubmission(submissionId: submissionId),
              settings: settings,
            );
          }
        }
        
        // ============================================
        // DEEP LINK: /artwork/{id}
        // Legacy support untuk direct artwork links
        // Tetap berfungsi untuk QR Code artwork
        // ============================================
        if (uri.path.startsWith('/artwork/')) {
          final artworkIdString = uri.path.replaceFirst('/artwork/', '');
          final artworkId = int.tryParse(artworkIdString);
          
          if (artworkId != null) {
            debugPrint('✅ Deep link detected: artwork/$artworkId');
            return MaterialPageRoute(
              builder: (context) => ArtworkDetailPage.fromId(artworkId: artworkId),
              settings: settings,
            );
          }
        }
        
        // ============================================
        // DEFAULT: Return null untuk named routes
        // ============================================
        return null;
      },
    );
  }
}