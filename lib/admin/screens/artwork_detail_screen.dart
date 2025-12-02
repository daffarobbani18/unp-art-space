import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../app/shared/widgets/custom_network_image.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';

class ArtworkDetailScreen extends StatefulWidget {
  final int artworkId;

  const ArtworkDetailScreen({
    Key? key,
    required this.artworkId,
  }) : super(key: key);

  @override
  State<ArtworkDetailScreen> createState() => _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends State<ArtworkDetailScreen> {
  final _supabase = Supabase.instance.client;
  
  Map<String, dynamic>? _artwork;
  Map<String, dynamic>? _artistInfo;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadArtworkDetail();
  }

  Future<void> _loadArtworkDetail() async {
    setState(() => _isLoading = true);
    
    try {
      // Load artwork
      final artworkResponse = await _supabase
          .from('artworks')
          .select('*')
          .eq('id', widget.artworkId)
          .single();

      _artwork = artworkResponse;

      // Load artist info
      if (_artwork!['artist_id'] != null) {
        try {
          final userResponse = await _supabase
              .from('users')
              .select('name, email, bio, specialization, profile_image_url, social_media')
              .eq('id', _artwork!['artist_id'])
              .maybeSingle();

          if (userResponse != null) {
            _artistInfo = userResponse;
          } else {
            final profileResponse = await _supabase
                .from('profiles')
                .select('username')
                .eq('id', _artwork!['artist_id'])
                .maybeSingle();

            _artistInfo = {
              'name': profileResponse?['username'] ?? 'Unknown Artist',
            };
          }
        } catch (e) {
          _artistInfo = {'name': 'Unknown Artist'};
        }
      }

      // Load comments
      final commentsResponse = await _supabase
          .from('comments')
          .select('*, profiles:user_id(username)')
          .eq('artwork_id', widget.artworkId)
          .order('created_at', ascending: false);

      _comments = List<Map<String, dynamic>>.from(commentsResponse);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading artwork: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateArtworkStatus(String newStatus) async {
    setState(() => _isProcessing = true);

    try {
      await _supabase
          .from('artworks')
          .update({'status': newStatus})
          .eq('id', widget.artworkId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Karya berhasil ${newStatus == 'approved' ? 'disetujui' : 'ditolak'}',
            ),
            backgroundColor: newStatus == 'approved' ? Colors.green : Colors.red,
          ),
        );

        // Reload data
        await _loadArtworkDetail();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
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

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
      case 'disetujui':
        return 'Disetujui';
      case 'rejected':
      case 'ditolak':
        return 'Ditolak';
      case 'pending':
      case 'menunggu':
      case 'menunggu_persetujuan':
        return 'Menunggu';
      default:
        return status ?? 'Unknown';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
      case 'disetujui':
        return const Color(0xFF4CAF50);
      case 'rejected':
      case 'ditolak':
        return const Color(0xFFFF6584);
      case 'pending':
      case 'menunggu':
      case 'menunggu_persetujuan':
        return const Color(0xFFFFA726);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: GlassAppBar(
        title: 'Detail Karya',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadArtworkDetail,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            )
          : _artwork == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.white30,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Karya tidak ditemukan',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column - Image
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildImageSection(),
                              const SizedBox(height: 24),
                              _buildCommentsSection(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column - Details
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              _buildInfoSection(),
                              const SizedBox(height: 24),
                              _buildArtistSection(),
                              const SizedBox(height: 24),
                              _buildStatsSection(),
                              if (_artwork!['status']?.toLowerCase() == 'pending' ||
                                  _artwork!['status']?.toLowerCase() == 'menunggu') ...[
                                const SizedBox(height: 24),
                                _buildActionsSection(),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildImageSection() {
    final mediaUrl = _artwork!['media_url'] ?? '';
    final artworkType = _artwork!['artwork_type'] ?? 'image';

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image/Video
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: artworkType == 'video'
                  ? Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_circle_outline,
                              color: Colors.white,
                              size: 80,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Video Artwork',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : CustomNetworkImage(
                      imageUrl: mediaUrl,
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
          
          // Title and Description
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _artwork!['title'] ?? 'Untitled',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_artwork!['description'] != null &&
                    _artwork!['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _artwork!['description'],
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final status = _artwork!['status'];
    final category = _artwork!['category'];
    final createdAt = _artwork!['created_at'];
    final isAiSuspected = _artwork!['is_ai_suspected'] == true;
    final aiScore = _artwork!['ai_generated_score'];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Informasi Karya',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Status
          _buildInfoRow(
            'Status',
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor(status),
                  width: 1.5,
                ),
              ),
              child: Text(
                _getStatusLabel(status),
                style: GoogleFonts.poppins(
                  color: _getStatusColor(status),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const Divider(color: Colors.white12, height: 32),
          
          // Category
          if (category != null)
            _buildInfoRow(
              'Kategori',
              Text(
                category,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          
          const Divider(color: Colors.white12, height: 32),
          
          // Upload Date
          _buildInfoRow(
            'Tanggal Upload',
            Text(
              _formatDate(createdAt),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const Divider(color: Colors.white12, height: 32),
          
          // Artwork Type
          _buildInfoRow(
            'Tipe',
            Row(
              children: [
                Icon(
                  _artwork!['artwork_type'] == 'video'
                      ? Icons.videocam_outlined
                      : Icons.image_outlined,
                  color: const Color(0xFF6366F1),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _artwork!['artwork_type'] == 'video' ? 'Video' : 'Gambar',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // AI Detection Info
          if (isAiSuspected) ...[
            const Divider(color: Colors.white12, height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6584).withOpacity(0.15),
                    const Color(0xFFFFA726).withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6584).withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.analytics_outlined,
                        color: Color(0xFFFF6584),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Terindikasi AI',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFF6584),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Skor Probabilitas: ${((aiScore ?? 0.0) * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: aiScore ?? 0.0,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF6584),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArtistSection() {
    final artistName = _artistInfo?['name'] ?? _artwork!['artist_name'] ?? 'Unknown';
    final artistEmail = _artistInfo?['email'];
    final artistBio = _artistInfo?['bio'];
    final artistSpec = _artistInfo?['specialization'];
    final profileImage = _artistInfo?['profile_image_url'];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Informasi Artist',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Artist Profile
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.3),
                backgroundImage: profileImage != null
                    ? NetworkImage(profileImage)
                    : null,
                child: profileImage == null
                    ? const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 32,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artistName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (artistSpec != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        artistSpec,
                        style: GoogleFonts.poppins(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          if (artistEmail != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  color: Colors.white54,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    artistEmail,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          
          if (artistBio != null) ...[
            const SizedBox(height: 16),
            Text(
              artistBio,
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 13,
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final likesCount = _artwork!['likes_count'] ?? 0;
    final viewsCount = _artwork!['views_count'] ?? 0;
    final sharesCount = _artwork!['shares_count'] ?? 0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Statistik',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.favorite_outline,
                likesCount.toString(),
                'Likes',
                const Color(0xFFFF6584),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white12,
              ),
              _buildStatItem(
                Icons.visibility_outlined,
                viewsCount.toString(),
                'Views',
                const Color(0xFF6366F1),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white12,
              ),
              _buildStatItem(
                Icons.share_outlined,
                sharesCount.toString(),
                'Shares',
                const Color(0xFF4CAF50),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.comment_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Komentar (${_comments.length})',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (_comments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Belum ada komentar',
                  style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length,
              separatorBuilder: (context, index) => const Divider(
                color: Colors.white12,
                height: 24,
              ),
              itemBuilder: (context, index) {
                final comment = _comments[index];
                final username = comment['profiles']?['username'] ?? 'Anonymous';
                final content = comment['content'] ?? '';
                final createdAt = comment['created_at'];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF6366F1).withOpacity(0.3),
                          child: Text(
                            username[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formatDate(createdAt),
                                style: GoogleFonts.poppins(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
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

  Widget _buildActionsSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aksi Moderasi',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  text: 'Tolak',
                  onPressed: _isProcessing
                      ? () {}
                      : () => _updateArtworkStatus('rejected'),
                  type: GlassButtonType.danger,
                  icon: Icons.close,
                  isLoading: _isProcessing,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GlassButton(
                  text: 'Setujui',
                  onPressed: _isProcessing
                      ? () {}
                      : () => _updateArtworkStatus('approved'),
                  type: GlassButtonType.success,
                  icon: Icons.check,
                  isLoading: _isProcessing,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, Widget value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: value),
      ],
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
