import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Features/auth/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_unp_art_space - cut.jpg',
              height: 200,
            ),
            const SizedBox(height: 28),
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold),
                children: const [
                  TextSpan(text: 'UNP ', style: TextStyle(color: Color(0xFF1E3A8A))),
                  TextSpan(text: 'ART SPACE', style: TextStyle(color: Color(0xFF9333EA))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
