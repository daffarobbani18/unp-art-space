import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_login_screen.dart';
import 'dashboard_screen.dart';
import 'work_moderation_screen.dart';
import 'event_moderation_screen.dart';
import 'user_management_screen.dart';
import 'settings_screen.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_sidebar.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;
  bool _isCollapsed = false;
  String _currentRoute = 'dashboard';

  final List<GlassSidebarItem> _sidebarItems = [
    GlassSidebarItem(
      icon: Icons.dashboard_rounded,
      title: 'Dashboard',
      route: 'dashboard',
    ),
    GlassSidebarItem(
      icon: Icons.palette_rounded,
      title: 'Moderasi Karya',
      route: 'work_moderation',
    ),
    GlassSidebarItem(
      icon: Icons.event_rounded,
      title: 'Moderasi Event',
      route: 'event_moderation',
    ),
    GlassSidebarItem(
      icon: Icons.people_rounded,
      title: 'Manajemen Pengguna',
      route: 'user_management',
    ),
    GlassSidebarItem(
      icon: Icons.settings_rounded,
      title: 'Pengaturan',
      route: 'settings',
    ),
  ];

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ModerationScreen(),
    const EventModerationScreen(),
    const UserManagementScreen(),
    const SettingsScreen(),
  ];

  Future<void> _handleLogout() async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Text('Apakah Anda yakin ingin keluar?', style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Logout', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ).catchError((e) {
        debugPrint('Dialog error: $e');
        return false;
      });

      if (confirm != true) return;

      // Jalankan signOut dengan error handling
      try {
        await Supabase.instance.client.auth.signOut();
        debugPrint('✅ Admin logout berhasil');
      } catch (e) {
        debugPrint("❌ Error saat admin logout: $e");
        // Tetap lanjut ke navigasi meskipun signOut gagal
      }

      // FORCE NAVIGATION - Paksa navigasi untuk clear stack
      // Hancurkan seluruh halaman admin dari memori
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AdminLoginScreen(),
        ),
        (route) => false, // Hapus SEMUA route dari memori
      );
    } catch (e, stackTrace) {
      debugPrint('Complete logout error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Navigate in next microtask
      if (mounted) {
        scheduleMicrotask(() {
          if (mounted) {
            try {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                (route) => false,
              );
            } catch (navError) {
              debugPrint('Final navigation error: $navError');
            }
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      body: AnimatedBackground(
        child: Row(
          children: [
            // Glass Sidebar
            Column(
              children: [
                Expanded(
                  child: GlassSidebar(
                    items: _sidebarItems,
                    currentRoute: _sidebarItems[_selectedIndex].route,
                    onItemTap: (route) {
                      final index = _sidebarItems.indexWhere(
                        (item) => item.route == route,
                      );
                      if (index != -1) {
                        setState(() {
                          _selectedIndex = index;
                          _currentRoute = route;
                        });
                      }
                    },
                    isCollapsed: _isCollapsed,
                  ),
                ),
                
                // User Info & Logout Section
                Container(
                  width: _isCollapsed ? 80 : 260,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (!_isCollapsed) ...[
                        GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Admin',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      user?.email ?? '',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      SizedBox(
                        width: double.infinity,
                        child: GlassButton(
                          text: _isCollapsed ? '' : 'Logout',
                          onPressed: _handleLogout,
                          type: GlassButtonType.danger,
                          icon: Icons.logout_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Toggle Collapse Button
            Positioned(
              left: _isCollapsed ? 68 : 248,
              top: 12,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _isCollapsed = !_isCollapsed),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isCollapsed
                          ? Icons.arrow_forward_ios
                          : Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Main Content
            Expanded(
              child: _screens[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}
