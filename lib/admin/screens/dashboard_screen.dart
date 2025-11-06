import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isLoading = true;
  
  int _pendingArtworks = 0;
  int _approvedArtworks = 0;
  int _totalArtists = 0;
  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animController.forward();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ringkasan sistem UNP Art Space',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _loadDashboardData,
                        icon: const Icon(Icons.refresh_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Statistics Cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        title: 'Karya Menunggu Persetujuan',
                        value: _pendingArtworks.toString(),
                        icon: Icons.pending_actions_rounded,
                        color: Color(0xFFEA580C),
                        gradient: [Color(0xFFEA580C).withOpacity(0.1), Color(0xFFFB923C).withOpacity(0.1)],
                      ),
                      _buildStatCard(
                        title: 'Total Karya Terbit',
                        value: _approvedArtworks.toString(),
                        icon: Icons.check_circle_rounded,
                        color: Color(0xFF059669),
                        gradient: [Color(0xFF059669).withOpacity(0.1), Color(0xFF10B981).withOpacity(0.1)],
                      ),
                      _buildStatCard(
                        title: 'Jumlah Seniman',
                        value: _totalArtists.toString(),
                        icon: Icons.palette_rounded,
                        color: Color(0xFF9333EA),
                        gradient: [Color(0xFF9333EA).withOpacity(0.1), Color(0xFFA855F7).withOpacity(0.1)],
                      ),
                      _buildStatCard(
                        title: 'Total Pengguna',
                        value: _totalUsers.toString(),
                        icon: Icons.people_rounded,
                        color: Color(0xFF1E3A8A),
                        gradient: [Color(0xFF1E3A8A).withOpacity(0.1), Color(0xFF3B82F6).withOpacity(0.1)],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Quick Actions
                  Text(
                    'Pintasan Cepat',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildQuickActionButton(
                        label: 'Lihat Karya Baru',
                        icon: Icons.visibility_rounded,
                        color: Color(0xFFEA580C),
                        onTap: () {
                          // Navigate to moderation screen
                        },
                      ),
                      _buildQuickActionButton(
                        label: 'Kelola Pengguna',
                        icon: Icons.manage_accounts_rounded,
                        color: Color(0xFF1E3A8A),
                        onTap: () {
                          // Navigate to user management
                        },
                      ),
                      _buildQuickActionButton(
                        label: 'Tambah Kategori',
                        icon: Icons.add_circle_rounded,
                        color: Color(0xFF9333EA),
                        onTap: () {
                          // Navigate to settings/categories
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
  }) {
    return FadeTransition(
      opacity: _animController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: Colors.grey[400], size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
