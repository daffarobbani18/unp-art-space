import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      // Initialize local notifications first
      await _initializeLocalNotifications();

      // Request permission for iOS & Android
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('🔔 FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          debugPrint('📱 FCM Token: $token');
          await _saveFCMToken(token);
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);

        // Setup message handlers
        _setupMessageHandlers();
      } else {
        debugPrint('❌ FCM Permission denied');
      }
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
    }
  }

  /// Initialize local notifications with channel
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel for high importance
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel', // Same as in AndroidManifest
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    debugPrint('✅ Local notifications initialized');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📬 Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        // Parse payload if it's JSON
        // You can add navigation logic here
        debugPrint('Payload: ${response.payload}');
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Save FCM token to database using RPC (bypass RLS)
  Future<void> _saveFCMToken(String token) async {
    try {
      debugPrint('💾 Attempting to save FCM token via RPC...');
      
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No user logged in, skipping FCM token save');
        return;
      }

      debugPrint('✅ User authenticated: ${user.id}');
      debugPrint('📧 User email: ${user.email}');

      // Get platform
      String platform = 'android';
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        platform = 'ios';
      } else if (kIsWeb) {
        platform = 'web';
      }

      debugPrint('📱 Platform: $platform');
      debugPrint('🎫 Token (first 30 chars): ${token.substring(0, token.length > 30 ? 30 : token.length)}...');

      // PENTING: Gunakan RPC function untuk bypass RLS
      debugPrint('🔧 Calling RPC: upsert_fcm_token...');
      
      final result = await _supabase.rpc('upsert_fcm_token', params: {
        'p_token': token,
        'p_user_id': user.id,
        'p_platform': platform,
        'p_device_id': null, // Bisa diisi device ID jika ada
      });

      debugPrint('📊 RPC Response: $result');
      
      if (result != null && result['success'] == true) {
        final operation = result['operation'];
        final message = result['message'];
        
        if (operation == 'insert') {
          debugPrint('✅ FCM token saved to database successfully!');
        } else {
          debugPrint('✅ FCM token ownership transferred to current user');
        }
        
        debugPrint('📝 Message: $message');
        debugPrint('🆔 Token ID: ${result['token_id']}');
      } else {
        debugPrint('⚠️ RPC returned non-success result');
        debugPrint('❌ Error: ${result?['error']}');
        debugPrint('📋 Detail: ${result?['detail']}');
      }
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error calling RPC upsert_fcm_token: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      
      // Fallback info
      if (e.toString().contains('upsert_fcm_token')) {
        debugPrint('💡 Pastikan RPC function sudah dibuat di database!');
        debugPrint('💡 Jalankan: create_rpc_upsert_fcm_token.sql');
      }
    }
  }

  /// Show local notification for foreground messages
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode,
        notification.title ?? 'Notification',
        notification.body ?? '',
        notificationDetails,
        payload: jsonEncode(message.data),
      );

      debugPrint('✅ Local notification displayed');
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
    }
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Foreground message received');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      // Show local notification when message arrives in foreground
      _showForegroundNotification(message);
      
      // Handle notification data
      _handleNotificationData(message.data);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📬 Notification tapped (app in background)');
      debugPrint('Data: ${message.data}');
      
      _handleNotificationTap(message.data);
    });

    // Handle notification tap when app was terminated
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📬 Notification tapped (app was terminated)');
        debugPrint('Data: ${message.data}');
        
        _handleNotificationTap(message.data);
      }
    });
  }

  /// Handle notification data (when received in foreground)
  void _handleNotificationData(Map<String, dynamic> data) {
    // You can implement custom logic here
    // For example, show a local notification or update badge count
    final type = data['type'];
    debugPrint('Notification type: $type');
  }

  /// Handle notification tap (navigation)
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];
    
    // Navigate based on notification type
    switch (type) {
      case 'event_status':
        // Navigate to event detail
        final eventId = data['event_id'];
        debugPrint('Navigate to event: $eventId');
        // TODO: Implement navigation
        break;
      
      case 'new_submission':
      case 'submission_status':
        // Navigate to submission/event
        final eventId = data['event_id'];
        debugPrint('Navigate to event submissions: $eventId');
        // TODO: Implement navigation
        break;
      
      case 'artwork_status':
        // Navigate to artwork detail
        final artworkId = data['artwork_id'];
        debugPrint('Navigate to artwork: $artworkId');
        // TODO: Implement navigation
        break;
      
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  /// Delete FCM token when user logs out
  Future<void> deleteFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _supabase
            .from('fcm_tokens')
            .update({'is_active': false})
            .eq('token', token);
        
        await _firebaseMessaging.deleteToken();
        debugPrint('✅ FCM token deleted');
      }
    } catch (e) {
      debugPrint('❌ Error deleting FCM token: $e');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Background message received');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}
