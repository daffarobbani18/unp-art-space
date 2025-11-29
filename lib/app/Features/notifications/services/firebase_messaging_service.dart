import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      // Request permission for iOS
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

  /// Save FCM token to database
  Future<void> _saveFCMToken(String token) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No user logged in, skipping FCM token save');
        return;
      }

      // Get platform
      String platform = 'android';
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        platform = 'ios';
      } else if (kIsWeb) {
        platform = 'web';
      }

      // Check if token already exists
      final existingToken = await _supabase
          .from('fcm_tokens')
          .select()
          .eq('token', token)
          .maybeSingle();

      if (existingToken != null) {
        // Update existing token
        await _supabase
            .from('fcm_tokens')
            .update({
              'user_id': user.id,
              'is_active': true,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('token', token);
        debugPrint('✅ FCM token updated in database');
      } else {
        // Insert new token
        await _supabase.from('fcm_tokens').insert({
          'user_id': user.id,
          'token': token,
          'platform': platform,
          'is_active': true,
        });
        debugPrint('✅ FCM token saved to database');
      }
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
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

      // You can show local notification here or update UI
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
