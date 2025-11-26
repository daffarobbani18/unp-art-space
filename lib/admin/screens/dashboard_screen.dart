import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/stat_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  
  int _pendingArtworks = 0;
  int _approvedArtworks = 0;
  int _totalArtists = 0;
  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      print('📊 Loading dashboard data...');
      
      // Get pending artworks count
      final pendingResponse = await Supabase.instance.client
          .from('artworks')
          .select('id')
          .eq('status', 'pending');
      print('⏳ Pending artworks: ${(pendingResponse as List).length}');
      
      // Get approved artworks count
      final approvedResponse = await Supabase.instance.client
          .from('artworks')
          .select('id')
          .eq('status', 'approved');
      print('✅ Approved artworks: ${(approvedResponse as List).length}');
      
      // Get total artists count from users table (where role = 'artist')
      final artistsResponse = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('role', 'artist');
      print('🎨 Total artists: ${(artistsResponse as List).length}');
      
      // Get total users count from users table
      final usersResponse = await Supabase.instance.client
          .from('users')
          .select('id');
      print('👥 Total users: ${(usersResponse as List).length}');

      setState(() {
        _pendingArtworks = (pendingResponse as List).length;
        _approvedArtworks = (approvedResponse as List).length;
        _totalArtists = (artistsResponse as List).length;
        _totalUsers = (usersResponse as List).length;
        _isLoading = false;
      });
      
      print('✨ Dashboard loaded successfully!');
    } catch (e) {
      print('❌ Error loading dashboard: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: 'Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  Text(
                    'Selamat Datang, Admin',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ringkasan sistem UNP Art Space',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Statistics Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = constraints.maxWidth > 1200
                          ? 4
                          : constraints.maxWidth > 800
                              ? 2
                              : 1;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.3,
                        children: [
                          StatCard(
                            title: 'Karya Pending',
                            value: _pendingArtworks.toString(),
                            icon: Icons.pending_actions_rounded,
                            gradientColors: const [
                              Color(0xFFF59E0B),
                              Color(0xFFEA580C),
                            ],
                            subtitle: 'Menunggu review',
                          ),
                          StatCard(
                            title: 'Karya Approved',
                            value: _approvedArtworks.toString(),
                            icon: Icons.check_circle_rounded,
                            gradientColors: const [
                              Color(0xFF10B981),
                              Color(0xFF059669),
                            ],
                            subtitle: 'Sudah terbit',
                          ),
                          StatCard(
                            title: 'Total Seniman',
                            value: _totalArtists.toString(),
                            icon: Icons.palette_rounded,
                            gradientColors: const [
                              Color(0xFF8B5CF6),
                              Color(0xFF9333EA),
                            ],
                            subtitle: 'Artist aktif',
                          ),
                          StatCard(
                            title: 'Total Pengguna',
                            value: _totalUsers.toString(),
                            icon: Icons.people_rounded,
                            gradientColors: const [
                              Color(0xFF3B82F6),
                              Color(0xFF1E3A8A),
                            ],
                            subtitle: 'User terdaftar',
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Quick Actions
                  Text(
                    'Pintasan Cepat',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        GlassButton(
                          text: 'Lihat Karya Baru',
                          onPressed: () {
                            // Navigate to moderation screen
                          },
                          type: GlassButtonType.secondary,
                          icon: Icons.visibility_rounded,
                        ),
                        GlassButton(
                          text: 'Kelola Pengguna',
                          onPressed: () {
                            // Navigate to user management
                          },
                          type: GlassButtonType.primary,
                          icon: Icons.manage_accounts_rounded,
                        ),
                        GlassButton(
                          text: 'Moderasi Event',
                          onPressed: () {
                            // Navigate to event moderation
                          },
                          type: GlassButtonType.success,
                          icon: Icons.event_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
