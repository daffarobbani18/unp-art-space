import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_animations.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    // Simulasi notifikasi - nanti bisa diganti dengan data real dari database
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _notifications = [
        {
          'id': 1,
          'title': 'Karya Anda Disetujui',
          'message': 'Karya "Sunset in Paradise" telah disetujui oleh admin',
          'time': '5 menit lalu',
          'type': 'success',
          'isRead': false,
        },
        {
          'id': 2,
          'title': 'Event Baru',
          'message': 'Pameran Seni Rupa 2024 akan segera dimulai',
          'time': '1 jam lalu',
          'type': 'info',
          'isRead': false,
        },
        {
          'id': 3,
          'title': 'Like Baru',
          'message': 'Sarah menyukai karya Anda',
          'time': '2 jam lalu',
          'type': 'like',
          'isRead': true,
        },
      ];
      _isLoading = false;
    });
  }

  IconData _getIconByType(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle_rounded;
      case 'info':
        return Icons.event_rounded;
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.comment_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorByType(String type) {
    switch (type) {
      case 'success':
        return AppTheme.success;
      case 'info':
        return AppTheme.info;
      case 'like':
        return AppTheme.accent;
      case 'comment':
        return AppTheme.secondary;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: AppTheme.textTertiary.withOpacity(0.1),
        title: Text(
          'Notifikasi',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          if (_notifications.any((n) => n['isRead'] == false))
            TextButton(
              onPressed: () {
                setState(() {
                  for (var notification in _notifications) {
                    notification['isRead'] = true;
                  }
                });
              },
              child: Text(
                'Tandai Semua',
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary),
              ),
            )
          : _notifications.isEmpty
              ? Center(
                  child: FadeInAnimation(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spaceLg),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.secondary.withOpacity(0.1),
                          ),
                          child: Icon(
                            Icons.notifications_off_rounded,
                            size: 64,
                            color: AppTheme.secondary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceMd),
                        Text(
                          'Belum Ada Notifikasi',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontFamily: 'Playfair Display',
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceXs),
                        Text(
                          'Notifikasi Anda akan muncul di sini',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: AppTheme.secondary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.spaceMd),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spaceSm),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['isRead'] as bool;
                      
                      return FadeSlideAnimation(
                        delay: Duration(milliseconds: index * 50),
                        child: BounceAnimation(
                          onTap: () {
                            setState(() {
                              notification['isRead'] = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spaceMd),
                            decoration: BoxDecoration(
                              color: isRead 
                                  ? AppTheme.surface 
                                  : AppTheme.secondary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              border: Border.all(
                                color: isRead 
                                    ? Colors.transparent 
                                    : AppTheme.secondary.withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: AppTheme.shadowSm,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.spaceSm),
                                  decoration: BoxDecoration(
                                    color: _getColorByType(notification['type']).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  ),
                                  child: Icon(
                                    _getIconByType(notification['type']),
                                    color: _getColorByType(notification['type']),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceSm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification['title'],
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: AppTheme.secondary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notification['message'],
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notification['time'],
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: AppTheme.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
