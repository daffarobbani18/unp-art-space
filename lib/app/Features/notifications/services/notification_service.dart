import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all notifications for current user
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      return true;
    } catch (e) {
      print('Error marking all as read: $e');
      return false;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _supabase.from('notifications').delete().eq('id', notificationId);
      return true;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  /// Stream of notifications (real-time updates)
  Stream<List<NotificationModel>> notificationsStream() {
    final userId = _supabase.auth.currentUser?.id;
    print('🔔 NotificationService: Current user ID = $userId');
    
    if (userId == null) {
      print('❌ NotificationService: No user logged in');
      return Stream.value([]);
    }

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) {
          print('📊 NotificationService: Received ${data.length} notifications from stream');
          if (data.isNotEmpty) {
            print('📋 First notification data: ${data.first}');
          }
          return data
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        });
  }

  /// Stream of unread count (real-time)
  Stream<int> unreadCountStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value(0);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((item) => item['user_id'] == userId && item['is_read'] == false)
            .length);
  }

  /// Manually create notification (for testing or manual triggers)
  Future<bool> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    int? artworkId,
    String? eventId,
    String? submissionId,
    String? iconType,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'artwork_id': artworkId,
        'event_id': eventId,
        'submission_id': submissionId,
        'icon_type': iconType,
        'is_read': false,
      });
      return true;
    } catch (e) {
      print('Error creating notification: $e');
      return false;
    }
  }
}
