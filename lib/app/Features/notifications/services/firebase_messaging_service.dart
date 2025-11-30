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

  /// Save FCM token to database
  Future<void> _saveFCMToken(String token) async {
    try {
      debugPrint('💾 Attempting to save FCM token...');
      
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

      // PENTING: Nonaktifkan semua token lama untuk user ini di device lain
      // Karena 1 user hanya boleh punya 1 active token per device
      debugPrint('🔄 Deactivating old tokens for user ${user.id}...');
      await _supabase
          .from('fcm_tokens')
          .update({'is_active': false})
          .eq('user_id', user.id)
          .neq('token', token);

      // Check if this specific token already exists (bisa dari user lain atau user ini)
      debugPrint('🔍 Checking if token exists...');
      final existingToken = await _supabase
          .from('fcm_tokens')
          .select()
          .eq('token', token)
          .maybeSingle();

      if (existingToken != null) {
        // Update existing token - ganti user_id ke user yang baru login
        debugPrint('🔄 Token exists (old user_id: ${existingToken['user_id']}), updating to new user_id: ${user.id}...');
        final response = await _supabase
            .from('fcm_tokens')
            .update({
              'user_id': user.id, // PENTING: Update ke user yang baru login
              'is_active': true,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('token', token)
            .select();
        debugPrint('✅ FCM token ownership transferred to current user');
        debugPrint('📊 Update response: $response');
      } else {
        // Insert new token
        debugPrint('➕ Token not found, inserting new...');
        
        try {
          final response = await _supabase
              .from('fcm_tokens')
              .insert({
                'user_id': user.id,
                'token': token,
                'platform': platform,
                'is_active': true,
              })
              .select()
              .single();
          
          debugPrint('✅ FCM token saved to database successfully!');
          debugPrint('📊 Insert response: $response');
          debugPrint('🆔 Token ID: ${response['id']}');
        } catch (insertError, insertStack) {
          debugPrint('❌ INSERT FAILED!');
          debugPrint('❌ Error: $insertError');
          debugPrint('📋 Stack: $insertStack');
          
          // Cek apakah ini RLS error
          if (insertError.toString().contains('policy') || 
              insertError.toString().contains('RLS') ||
              insertError.toString().contains('permission')) {
            debugPrint('🔒 KEMUNGKINAN RLS POLICY BLOCK!');
            debugPrint('💡 Cek RLS policy di Supabase Dashboard');
          }
          
          rethrow;
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving FCM token: $e');
      debugPrint('📋 Stack trace: $stackTrace');
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
