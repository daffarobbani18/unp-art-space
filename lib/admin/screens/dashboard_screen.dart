import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/stat_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  
  int _pendingArtworks = 0;
  int _approvedArtworks = 0;
  int _rejectedArtworks = 0;
  int _totalArtists = 0;
  int _totalUsers = 0;
  int _totalEvents = 0;
  int _pendingEvents = 0;
  int _totalOrganizers = 0;
  
  List<Map<String, dynamic>> _recentArtworks = [];
  List<Map<String, dynamic>> _recentEvents = [];
  
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _animationController.reset();
    
    try {
      debugPrint('🔄 Loading dashboard data...');
      
      // Load all data in parallel for faster loading
      final results = await Future.wait([
        // Artworks statistics
        Supabase.instance.client.from('artworks').select('id').eq('status', 'pending'),
        Supabase.instance.client.from('artworks').select('id').eq('status', 'approved'),
        Supabase.instance.client.from('artworks').select('id').eq('status', 'rejected'),
        
        // Users statistics (using profiles table)
        Supabase.instance.client.from('profiles').select('id').eq('role', 'artist'),
        Supabase.instance.client.from('profiles').select('id').eq('role', 'organizer'),
        Supabase.instance.client.from('profiles').select('id'),
        
        // Events statistics
        Supabase.instance.client.from('events').select('id'),
        Supabase.instance.client.from('events').select('id').eq('status', 'pending'),
        
        // Recent artworks (last 5)
        Supabase.instance.client
            .from('artworks')
            .select('id, title, status, created_at, artist_id')
            .order('created_at', ascending: false)
            .limit(5),
        
        // Recent events (last 5)
        Supabase.instance.client
            .from('events')
            .select('id, title, status, created_at')
            .order('created_at', ascending: false)
            .limit(5),
      ]);

      debugPrint('✅ Dashboard data loaded successfully');
      
      if (!mounted) return;
      setState(() {
        _pendingArtworks = (results[0] as List).length;
        _approvedArtworks = (results[1] as List).length;
        _rejectedArtworks = (results[2] as List).length;
        _totalArtists = (results[3] as List).length;
        _totalOrganizers = (results[4] as List).length;
        _totalUsers = (results[5] as List).length;
        _totalEvents = (results[6] as List).length;
        _pendingEvents = (results[7] as List).length;
        _recentArtworks = List<Map<String, dynamic>>.from(results[8] as List);
        _recentEvents = List<Map<String, dynamic>>.from(results[9] as List);
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading dashboard data: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
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
          ? _buildLoadingSkeleton()
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: const Color(0xFF6366F1),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header with Animation
                    FadeTransition(
                      opacity: _animationController,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, -0.5),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeOut,
                        )),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6366F1).withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.dashboard_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Selamat Datang, Admin',
                                        style: GoogleFonts.poppins(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Terakhir diperbarui: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ringkasan sistem Campus Art Space',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Statistics Cards with Animation
                    _buildStatisticsSection(),
                    
                    const SizedBox(height: 32),

                    // Activity Overview
                    _buildActivityOverview(),
                    
                    const SizedBox(height: 32),

                    // Recent Activity Section
                    _buildRecentActivity(),
                    
                    const SizedBox(height: 32),

                    // Quick Actions
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmer(height: 80, width: double.infinity),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.3,
            children: List.generate(8, (index) => _buildShimmer(height: 150)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer({required double height, double? width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return FadeTransition(
      opacity: _animationController,
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 1400
              ? 4
              : constraints.maxWidth > 1000
                  ? 3
                  : constraints.maxWidth > 600
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
                gradientColors: const [Color(0xFFF59E0B), Color(0xFFEA580C)],
                subtitle: 'Menunggu review',
              ),
              StatCard(
                title: 'Karya Approved',
                value: _approvedArtworks.toString(),
                icon: Icons.check_circle_rounded,
                gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                subtitle: 'Sudah terbit',
              ),
              StatCard(
                title: 'Karya Rejected',
                value: _rejectedArtworks.toString(),
                icon: Icons.cancel_rounded,
                gradientColors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                subtitle: 'Ditolak',
              ),
              StatCard(
                title: 'Total Seniman',
                value: _totalArtists.toString(),
                icon: Icons.palette_rounded,
                gradientColors: const [Color(0xFF8B5CF6), Color(0xFF9333EA)],
                subtitle: 'Artist aktif',
              ),
              StatCard(
                title: 'Total Organizer',
                value: _totalOrganizers.toString(),
                icon: Icons.business_center_rounded,
                gradientColors: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
                subtitle: 'Event organizer',
              ),
              StatCard(
                title: 'Total Pengguna',
                value: _totalUsers.toString(),
                icon: Icons.people_rounded,
                gradientColors: const [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                subtitle: 'User terdaftar',
              ),
              StatCard(
                title: 'Total Event',
                value: _totalEvents.toString(),
                icon: Icons.event_rounded,
                gradientColors: const [Color(0xFFEC4899), Color(0xFFDB2777)],
                subtitle: 'Event terdaftar',
              ),
              StatCard(
                title: 'Event Pending',
                value: _pendingEvents.toString(),
                icon: Icons.event_busy_rounded,
                gradientColors: const [Color(0xFFF97316), Color(0xFFEA580C)],
                subtitle: 'Menunggu review',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivityOverview() {
    final totalArtworks = _pendingArtworks + _approvedArtworks + _rejectedArtworks;
    final approvalRate = totalArtworks > 0 ? (_approvedArtworks / totalArtworks * 100) : 0.0;
    
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Aktivitas',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 800;
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  SizedBox(
                    width: isWide ? constraints.maxWidth * 0.48 : constraints.maxWidth,
                    child: _buildInfoCard(
                      'Approval Rate',
                      '${approvalRate.toStringAsFixed(1)}%',
                      Icons.thumbs_up_down_rounded,
                      const [Color(0xFF10B981), Color(0xFF059669)],
                      'Dari $totalArtworks total karya',
                    ),
                  ),
                  SizedBox(
                    width: isWide ? constraints.maxWidth * 0.48 : constraints.maxWidth,
                    child: _buildInfoCard(
                      'Perlu Perhatian',
                      '${_pendingArtworks + _pendingEvents}',
                      Icons.notification_important_rounded,
                      const [Color(0xFFF59E0B), Color(0xFFEA580C)],
                      'Karya & Event menunggu',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, List<Color> colors, String subtitle) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktivitas Terbaru',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 900;
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  SizedBox(
                    width: isWide ? constraints.maxWidth * 0.48 : constraints.maxWidth,
                    child: _buildRecentArtworksList(),
                  ),
                  SizedBox(
                    width: isWide ? constraints.maxWidth * 0.48 : constraints.maxWidth,
                    child: _buildRecentEventsList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentArtworksList() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.art_track_rounded, color: Colors.white.withOpacity(0.9), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Karya Terbaru',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentArtworks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Belum ada karya',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              )
            else
              ...List.generate(_recentArtworks.length, (index) {
                final artwork = _recentArtworks[index];
                return _buildActivityItem(
                  artwork['title'] ?? 'Untitled',
                  artwork['status'] ?? 'unknown',
                  artwork['created_at'],
                  Icons.palette_rounded,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEventsList() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_rounded, color: Colors.white.withOpacity(0.9), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Event Terbaru',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentEvents.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Belum ada event',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              )
            else
              ...List.generate(_recentEvents.length, (index) {
                final event = _recentEvents[index];
                return _buildActivityItem(
                  event['title'] ?? 'Untitled Event',
                  event['status'] ?? 'unknown',
                  event['created_at'],
                  Icons.event_rounded,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String status, String? createdAt, IconData icon) {
    Color statusColor;
    String statusText;
    
    switch (status.toLowerCase()) {
      case 'pending':
      case 'menunggu_persetujuan':
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Pending';
        break;
      case 'approved':
      case 'disetujui':
        statusColor = const Color(0xFF10B981);
        statusText = 'Approved';
        break;
      case 'rejected':
      case 'ditolak':
        statusColor = const Color(0xFFEF4444);
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    String timeAgo = 'Baru saja';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        final diff = DateTime.now().difference(date);
        if (diff.inDays > 0) {
          timeAgo = '${diff.inDays} hari lalu';
        } else if (diff.inHours > 0) {
          timeAgo = '${diff.inHours} jam lalu';
        } else if (diff.inMinutes > 0) {
          timeAgo = '${diff.inMinutes} menit lalu';
        }
      } catch (e) {
        // Keep default value
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: statusColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return FadeTransition(
      opacity: _animationController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                GlassButton(
                  text: 'Pengaturan',
                  onPressed: () {
                    // Navigate to settings
                  },
                  type: GlassButtonType.outline,
                  icon: Icons.settings_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
