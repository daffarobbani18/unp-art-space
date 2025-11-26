//File main untuk aplikasi mobile (pengguna)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_strategy/url_strategy.dart';
import '../app/core/screens/splash_screen.dart';
import '../organizer/organizer_main_screen.dart';
import '../app/Features/artwork/screens/artwork_detail_page.dart';
import 'package:project1/app/core/utils/http_overrides.dart';
import '../app/Features/auth/screens/login_page.dart';

// Variabel global untuk akses Supabase client di seluruh aplikasi
late final SupabaseClient supabase;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Remove # from URL for web
  if (kIsWeb) {
    setPathUrlStrategy();
  }

  HttpOverrides.global = MyHttpOverrides();

  // Inisialisasi locale Indonesian untuk intl package
  await initializeDateFormatting('id_ID', null);

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
      title: 'UNP Art Space',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      // Remove fixed home to allow deep linking
      // home: const SplashScreen(),
      initialRoute: '/',
      routes: {
        '/login': (context) => const LoginPage(),
        '/': (context) => const SplashScreen(),
        '/organizer_home': (context) => const OrganizerMainScreen(),
      },
      onGenerateRoute: (settings) {
        debugPrint('🔗 Navigation to: ${settings.name}');
        
        // Handle deep linking for /submission/{uuid} (QR Code from event submissions)
        if (settings.name != null && settings.name!.startsWith('/submission/')) {
          final submissionId = settings.name!.replaceFirst('/submission/', '');
          
          if (submissionId.isNotEmpty) {
            debugPrint('✅ Deep link detected: submission/$submissionId');
            return MaterialPageRoute(
              builder: (context) => ArtworkDetailPage.fromSubmission(submissionId: submissionId),
              settings: settings,
            );
          }
        }
        
        // Handle deep linking for /artwork/{id} (Legacy support for direct artwork links)
        if (settings.name != null && settings.name!.startsWith('/artwork/')) {
          final artworkIdString = settings.name!.replaceFirst('/artwork/', '');
          final artworkId = int.tryParse(artworkIdString);
          
          if (artworkId != null) {
            debugPrint('✅ Deep link detected: artwork/$artworkId');
            return MaterialPageRoute(
              builder: (context) => ArtworkDetailPage.fromId(artworkId: artworkId),
              settings: settings,
            );
          }
        }
        
        // Return null for other routes (will use default routing)
        return null;
      },
    );
  }
}