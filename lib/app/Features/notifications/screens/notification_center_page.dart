import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({Key? key}) : super(key: key);

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  final NotificationService _notificationService = NotificationService();
  bool _isMarkingAllRead = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          // Mark all as read button
          StreamBuilder<int>(
            stream: _notificationService.unreadCountStream(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount == 0) return const SizedBox.shrink();
              
              return IconButton(
                icon: _isMarkingAllRead
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.done_all, color: Colors.white),
                onPressed: _isMarkingAllRead ? null : _markAllAsRead,
                tooltip: 'Tandai semua dibaca',
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<NotificationModel>>(
            stream: _notificationService.notificationsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9333EA)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return _buildEmptyState();
              }

              return _buildNotificationList(notifications);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationCard(notifications[index]);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.delete_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        onDismissed: (direction) {
          _notificationService.deleteNotification(notification.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Notifikasi dihapus',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: notification.isRead
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: notification.isRead
                      ? Colors.white.withOpacity(0.1)
                      : const Color(0xFF9333EA).withOpacity(0.5),
                  width: notification.isRead ? 1 : 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _handleNotificationTap(notification),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        _buildNotificationIcon(notification),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification.title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (!notification.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF9333EA),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notification.message,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTime(notification.createdAt),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationModel notification) {
    IconData iconData;
    Color iconColor;
    Color bgColor;

    switch (notification.iconType) {
      case 'check':
        iconData = Icons.check_circle_rounded;
        iconColor = const Color(0xFF10B981);
        bgColor = const Color(0xFF10B981).withOpacity(0.2);
        break;
      case 'close':
        iconData = Icons.cancel_rounded;
        iconColor = const Color(0xFFEF4444);
        bgColor = const Color(0xFFEF4444).withOpacity(0.2);
        break;
      case 'event':
        iconData = Icons.event_rounded;
        iconColor = const Color(0xFF3B82F6);
        bgColor = const Color(0xFF3B82F6).withOpacity(0.2);
        break;
      case 'artwork':
        iconData = Icons.image_rounded;
        iconColor = const Color(0xFF9333EA);
        bgColor = const Color(0xFF9333EA).withOpacity(0.2);
        break;
      default:
        iconData = Icons.notifications_rounded;
        iconColor = const Color(0xFF9333EA);
        bgColor = const Color(0xFF9333EA).withOpacity(0.2);
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Notifikasi',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Notifikasi akan muncul di sini ketika ada aktivitas baru',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat notifikasi',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Mark as read
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
    }

    // Handle navigation based on notification type
    // TODO: Implement navigation to specific screens based on type
    // For now, just show a message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Membuka ${notification.title}...',
            style: GoogleFonts.poppins(),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() => _isMarkingAllRead = true);
    
    final success = await _notificationService.markAllAsRead();
    
    if (mounted) {
      setState(() => _isMarkingAllRead = false);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Semua notifikasi ditandai dibaca',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
