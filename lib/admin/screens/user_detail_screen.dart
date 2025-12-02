import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';

class UserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserDetailScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late Map<String, dynamic> _currentUser;
  bool _isLoading = false;
  int _artworksCount = 0;
  int _eventsCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;
  List<Map<String, dynamic>> _recentArtworks = [];
  List<Map<String, dynamic>> _recentEvents = [];

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    setState(() => _isLoading = true);
    try {
      final userId = _currentUser['id'];

      // Load artworks count
      final artworksResponse = await Supabase.instance.client
          .from('artworks')
          .select('id')
          .eq('artist_id', userId);
      _artworksCount = (artworksResponse as List).length;

      // Load recent artworks
      final recentArtworksResponse = await Supabase.instance.client
          .from('artworks')
          .select('*')
          .eq('artist_id', userId)
          .order('created_at', ascending: false)
          .limit(3);
      _recentArtworks = List<Map<String, dynamic>>.from(recentArtworksResponse as List);

      // Load events count (for organizers)
      if (_currentUser['role'] == 'organizer') {
        final eventsResponse = await Supabase.instance.client
            .from('events')
            .select('id')
            .eq('organizer_id', userId);
        _eventsCount = (eventsResponse as List).length;

        // Load recent events
        final recentEventsResponse = await Supabase.instance.client
            .from('events')
            .select('*')
            .eq('organizer_id', userId)
            .order('created_at', ascending: false)
            .limit(3);
        _recentEvents = List<Map<String, dynamic>>.from(recentEventsResponse as List);
      }

      // Load followers count
      final followersResponse = await Supabase.instance.client
          .from('artist_follows')
          .select('id')
          .eq('artist_id', userId);
      _followersCount = (followersResponse as List).length;

      // Load following count
      final followingResponse = await Supabase.instance.client
          .from('artist_follows')
          .select('id')
          .eq('follower_id', userId);
      _followingCount = (followingResponse as List).length;

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserRole(String newRole) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'role': newRole})
          .eq('id', _currentUser['id']);

      // Update profiles table as well
      await Supabase.instance.client
          .from('profiles')
          .update({'role': newRole})
          .eq('id', _currentUser['id']);

      setState(() {
        _currentUser['role'] = newRole;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Role berhasil diubah menjadi $newRole',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate changes
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFFF6584),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFEF4444);
      case 'artist':
        return const Color(0xFF8B5CF6);
      case 'organizer':
        return const Color(0xFF3B82F6);
      case 'viewer':
      default:
        return const Color(0xFF10B981);
    }
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'artist':
        return Icons.palette;
      case 'organizer':
        return Icons.event;
      case 'viewer':
      default:
        return Icons.person;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  void _showRoleChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.swap_horiz, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ubah Role',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentUser['name'] ?? 'Unknown User',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ...[
                  {'role': 'admin', 'label': 'Admin', 'icon': Icons.admin_panel_settings},
                  {'role': 'artist', 'label': 'Artist', 'icon': Icons.palette},
                  {'role': 'organizer', 'label': 'Organizer', 'icon': Icons.event},
                  {'role': 'viewer', 'label': 'Viewer', 'icon': Icons.person},
                ].map((roleData) {
                  final isCurrentRole = _currentUser['role'] == roleData['role'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        text: roleData['label'] as String,
                        icon: roleData['icon'] as IconData,
                        onPressed: isCurrentRole
                            ? () {}
                            : () {
                                Navigator.pop(context);
                                _updateUserRole(roleData['role'] as String);
                              },
                        type: isCurrentRole
                            ? GlassButtonType.outline
                            : GlassButtonType.primary,
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: GlassAppBar(
        title: 'Detail Pengguna',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadUserStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            )
          : SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1400 : double.infinity,
                  ),
                  padding: EdgeInsets.all(isDesktop ? 32 : 16),
                  child: isDesktop
                      ? _buildDesktopLayout()
                      : _buildMobileLayout(),
                ),
              ),
            ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column - Profile & Stats
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildProfileCard(),
              const SizedBox(height: 24),
              _buildStatsCard(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right Column - Details & Activity
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildInfoCard(),
              const SizedBox(height: 24),
              if (_currentUser['role'] == 'artist' && _recentArtworks.isNotEmpty)
                _buildRecentArtworksCard(),
              if (_currentUser['role'] == 'organizer' && _recentEvents.isNotEmpty)
                _buildRecentEventsCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildProfileCard(),
        const SizedBox(height: 16),
        _buildStatsCard(),
        const SizedBox(height: 16),
        _buildInfoCard(),
        if (_currentUser['role'] == 'artist' && _recentArtworks.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildRecentArtworksCard(),
        ],
        if (_currentUser['role'] == 'organizer' && _recentEvents.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildRecentEventsCard(),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProfileCard() {
    final role = _currentUser['role'] ?? 'viewer';
    final roleColor = _getRoleColor(role);

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile Image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: roleColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: roleColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: _currentUser['profile_image_url'] != null &&
                      _currentUser['profile_image_url'].toString().isNotEmpty
                  ? Image.network(
                      _currentUser['profile_image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF2D2D3A),
                        child: Icon(_getRoleIcon(role), size: 60, color: roleColor),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF2D2D3A),
                      child: Icon(_getRoleIcon(role), size: 60, color: roleColor),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            _currentUser['name'] ?? 'Unknown User',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: roleColor, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getRoleIcon(role), color: roleColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  role.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: roleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Change Role Button
          GlassButton(
            text: 'Ubah Role',
            icon: Icons.swap_horiz,
            onPressed: _showRoleChangeDialog,
            type: GlassButtonType.primary,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(Icons.image_outlined, 'Karya', _artworksCount.toString()),
          const SizedBox(height: 12),
          if (_currentUser['role'] == 'organizer')
            _buildStatRow(Icons.event_outlined, 'Event', _eventsCount.toString()),
          if (_currentUser['role'] == 'organizer') const SizedBox(height: 12),
          _buildStatRow(Icons.people_outline, 'Followers', _followersCount.toString()),
          const SizedBox(height: 12),
          _buildStatRow(Icons.person_add_outlined, 'Following', _followingCount.toString()),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Informasi Detail',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.email_outlined, 'Email', _currentUser['email'] ?? '-'),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.calendar_today,
            'Bergabung',
            _formatDate(_currentUser['created_at']),
          ),
          if (_currentUser['specialization'] != null) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.work_outline,
              'Spesialisasi',
              _currentUser['specialization'],
            ),
          ],
          if (_currentUser['bio'] != null && _currentUser['bio'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_outlined, color: Color(0xFF6366F1), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Bio',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _currentUser['bio'],
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ],
          if (_currentUser['social_media'] != null) ...[
            const SizedBox(height: 16),
            _buildSocialMediaSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF6366F1), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialMediaSection() {
    final socialMedia = _currentUser['social_media'];
    if (socialMedia == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Social Media',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (socialMedia['instagram'] != null && socialMedia['instagram'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.camera_alt, color: Color(0xFF8B5CF6), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    socialMedia['instagram'],
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        if (socialMedia['behance'] != null && socialMedia['behance'].toString().isNotEmpty)
          Row(
            children: [
              const Icon(Icons.work_outline, color: Color(0xFF3B82F6), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  socialMedia['behance'],
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRecentArtworksCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Karya Terbaru',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._recentArtworks.map((artwork) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      artwork['media_url'] ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: const Color(0xFF2D2D3A),
                        child: const Icon(Icons.image, color: Colors.white54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artwork['title'] ?? 'Untitled',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatDate(artwork['created_at']),
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentEventsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Terbaru',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._recentEvents.map((event) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                    ),
                    child: const Icon(Icons.event, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title'] ?? 'Untitled Event',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatDate(event['created_at']),
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
