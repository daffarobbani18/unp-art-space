import 'package:flutter/material.dart';
import 'dart:ui';
import '../../Features/notifications/services/notification_service.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      height: 70,
      child: Stack(
        clipBehavior: Clip.none, // Penting untuk item yang pop-up
        children: [
          // Background Glass Container
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2C).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(0),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Nav Items
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.search_rounded,
                  label: 'Jelajahi',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.add_rounded,
                  label: 'Upload',
                  isCenter: true,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.notifications_rounded,
                  label: 'Notifikasi',
                  showBadge: true,
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_rounded,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    bool isCenter = false,
    bool showBadge = false,
  }) {
    final isSelected = widget.selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon with Pop-up Effect
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                transform: Matrix4.translationValues(
                  0,
                  isSelected ? -25 : 0,
                  0,
                ),
                child: ScaleTransition(
                  scale: isSelected ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: isCenter ? 57 : 47,
                        height: isCenter ? 57 : 47,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isSelected
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFF6B6B),
                                    Color(0xFFFF8E53),
                                  ],
                                )
                              : null,
                          color: isSelected ? null : Colors.transparent,
                          border: isSelected
                              ? Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 2.0,
                                )
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFFF6B6B).withOpacity(0.4),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 5),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
                            size: isCenter ? 26 : 22,
                          ),
                        ),
                      ),
                      // Badge for notifications
                      if (showBadge)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: StreamBuilder<int>(
                            stream: _notificationService.unreadCountStream(),
                            builder: (context, snapshot) {
                              final unreadCount = snapshot.data ?? 0;
                              if (unreadCount == 0) return const SizedBox.shrink();
                              
                              return Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Label (only show when not selected to save space)
              if (!isSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
