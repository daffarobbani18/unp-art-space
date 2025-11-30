import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  // Instance Firebase Messaging
  final _firebaseMessaging = FirebaseMessaging.instance;

  // Fungsi untuk inisialisasi notifikasi
  Future<void> initNotifications() async {
    // 1. Minta Izin ke User (Akan muncul Pop-up Dialog)
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // 2. Ambil FCM Token (Alamat HP ini)
    final fcmToken = await _firebaseMessaging.getToken();

    // 3. Print Token di Terminal (Untuk kita tes nanti)
    if (kDebugMode) {
      print('=======================================');
      print('🔔 FCM TOKEN HP INI: $fcmToken');
      print('=======================================');
    }

    // TODO: Nanti di sini kita simpan token ke Database Supabase
    // await saveTokenToDatabase(fcmToken);
  }
}