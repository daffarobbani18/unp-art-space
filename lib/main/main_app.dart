//File main untuk aplikasi mobile (pengguna)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app/core/navigation/auth_gate.dart';
import '../app/core/screens/splash_screen.dart';
import 'package:project1/app/core/utils/http_overrides.dart';

// Variabel global untuk akses Supabase client di seluruh aplikasi
late final SupabaseClient supabase;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();

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
      home: const SplashScreen(), 
    );
  }
}