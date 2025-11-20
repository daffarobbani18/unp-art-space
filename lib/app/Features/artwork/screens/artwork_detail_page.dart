import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../artist/screens/artist_detail_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class ArtworkDetailPage extends StatefulWidget {
  final Map<String, dynamic> artwork;

  const ArtworkDetailPage({Key? key, required this.artwork}) : super(key: key);

  @override
  State<ArtworkDetailPage> createState() => _ArtworkDetailPageState();
}

class _ArtworkDetailPageState extends State<ArtworkDetailPage>
    with SingleTickerProviderStateMixin {
  bool _isLiking = false;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Initialize Indonesian locale for date formatting
    initializeDateFormatting('id_ID', null);

    // Setup animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();

    // Video setup
    final artwork = widget.artwork;
    final artworkType = (artwork['artwork_type'] as String?) ?? 'image';
    if (artworkType == 'video') {
      final mediaUrl =
          (artwork['media_url'] as String?) ??
          (artwork['image_url'] as String?) ??
          '';
      if (mediaUrl.isNotEmpty) {
        _videoController = VideoPlayerController.network(mediaUrl);
        _videoController!
            .initialize()
            .then((_) {
              if (!mounted) return;
              setState(() {
                _isVideoInitialized = true;
                _isVideoPlaying = _videoController!.value.isPlaying;
              });
            })
            .catchError((e) {
              debugPrint('Error initializing video: $e');
            });
        _videoController!.addListener(() {
          if (!mounted) return;
          setState(() {
            _isVideoPlaying = _videoController!.value.isPlaying;
          });
        });
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url) ?? Uri();
    if (uri.toString().isEmpty) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final artwork = widget.artwork;
    final artworkType = (artwork['artwork_type'] as String?) ?? 'image';
    final title = (artwork['title'] as String?) ?? 'Untitled';
    final imageUrl =
        (artwork['media_url'] as String?) ??
        (artwork['image_url'] as String?) ??
        '';
    final likesCount = (artwork['likes_count'] ?? 0) as int;
    final commentsCount = (artwork['comments_count'] ?? 0) as int;

    // User/Artist info
    final users = (artwork['users'] as Map<String, dynamic>?) ?? {};
    final artistName =
        (users['name'] as String?) ??
        (artwork['artist_name'] as String?) ??
        'Unknown Artist';
    final artistId = (artwork['artist_id'] as String?) ?? '';
    final artistAvatar = (users['avatar_url'] as String?) ?? '';
    final artistBio =
        (users['bio'] as String?) ?? 'Seniman ini belum memiliki bio.';
    final social = (users['social_media'] as Map<String, dynamic>?) ?? {};

    final description = (artwork['description'] as String?) ?? '';
    final externalLink = (artwork['external_link'] as String?) ?? '';

    // New data structure - using correct field names from database
    final categoryName = (artwork['category'] as String?) ?? '—';
    final createdAt = artwork['created_at'] as String?;
    final uploadDate = createdAt != null
        ? DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(createdAt))
        : '—';
    final status = (artwork['status'] as String?) ?? 'pending';
    final isApproved = status.toLowerCase() == 'approved';
    final statusText = isApproved ? 'Terverifikasi' : 'Pending';

    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.5;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Layer 1: Dark Gradient Background (Full Screen)
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2027), // Deep Blue Dark
                  Color(0xFF203A43),
                  Color(0xFF2C5364),
                ],
              ),
            ),
          ),

          // Layer 2: Hero Image with Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                if (imageUrl.isNotEmpty && artworkType == 'image') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _FullScreenImageView(
                        imageUrl: imageUrl,
                        heroTag: 'artwork_${artwork['id']}',
                      ),
                    ),
                  );
                }
              },
              behavior: HitTestBehavior.translucent,
              child: SizedBox(
                height: imageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Hero Image
                    Hero(
                      tag: 'artwork_${artwork['id']}',
                      child: artworkType == 'image'
                          ? (imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF1E3A8A),
                                            Color(0xFF9333EA),
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.image,
                                        size: 120,
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF1E3A8A),
                                          Color(0xFF9333EA),
                                        ],
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.image,
                                      size: 120,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ))
                          : artworkType == 'video' && _videoController != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _videoController!.value.size.width,
                                    height: _videoController!.value.size.height,
                                    child: VideoPlayer(_videoController!),
                                  ),
                                ),
                                if (!_isVideoInitialized)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                Center(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: IconButton(
                                      icon: Icon(
                                        _isVideoPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_fill,
                                        size: 64,
                                        color: Colors.white,
                                      ),
                                      onPressed: _togglePlayPause,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1E3A8A),
                                    Color(0xFF9333EA),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.video_library,
                                size: 120,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                    ),
                    // Gradient Overlay (Smooth blend to dark background)
                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                              const Color(0xFF0F2027).withOpacity(0.8),
                              const Color(0xFF0F2027),
                            ],
                            stops: const [0.0, 0.5, 0.85, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Layer 3: Scrollable Content
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Spacing untuk foto - konten dimulai tepat di bawah foto
                SizedBox(height: imageHeight),

                // Content with Animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Glass Card
                        _buildGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.3,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Artist Info
                              InkWell(
                                onTap: () {
                                  if (artistId.isNotEmpty) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ArtistDetailPage(
                                          artistId: artistId,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.2,
                                      ),
                                      backgroundImage: artistAvatar.isNotEmpty
                                          ? NetworkImage(artistAvatar)
                                          : null,
                                      child: artistAvatar.isEmpty
                                          ? const Icon(
                                              Icons.person,
                                              size: 18,
                                              color: Colors.white70,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Karya oleh',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.white60,
                                            ),
                                          ),
                                          Text(
                                            artistName,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Stats Glass Card
                        _buildInfoGlassCard(
                          icon: Icons.favorite_rounded,
                          iconGradient: const LinearGradient(
                            colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                          ),
                          title: 'Interaksi',
                          content:
                              '$likesCount Likes • $commentsCount Komentar',
                        ),

                        const SizedBox(height: 12),

                        // Category Glass Card
                        _buildInfoGlassCard(
                          icon: Icons.category_rounded,
                          iconGradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                          ),
                          title: 'Kategori',
                          content: categoryName,
                        ),

                        const SizedBox(height: 12),

                        // Upload Date Glass Card
                        _buildInfoGlassCard(
                          icon: Icons.calendar_month_rounded,
                          iconGradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                          ),
                          title: 'Tanggal Upload',
                          content: uploadDate,
                        ),

                        const SizedBox(height: 12),

                        // Status Glass Card
                        _buildInfoGlassCard(
                          icon: Icons.verified_rounded,
                          iconGradient: LinearGradient(
                            colors: isApproved
                                ? [
                                    const Color(0xFF10B981),
                                    const Color(0xFF34D399),
                                  ]
                                : [
                                    const Color(0xFFF59E0B),
                                    const Color(0xFFFBBF24),
                                  ],
                          ),
                          title: 'Status',
                          content: statusText,
                        ),

                        const SizedBox(height: 16),

                        // Description Glass Card
                        if (description.isNotEmpty)
                          _buildGlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF10B981),
                                            Color(0xFF34D399),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.description_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Deskripsi Karya',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  description,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    height: 1.8,
                                    color: Colors.grey[300],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (description.isNotEmpty) const SizedBox(height: 16),

                        // About Artist Glass Card
                        _buildGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF8B5CF6),
                                          Color(0xFFA78BFA),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.person_outline_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Tentang Seniman',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                artistBio,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  height: 1.8,
                                  color: Colors.grey[300],
                                ),
                              ),
                              if (social.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    if ((social['instagram'] as String?)
                                            ?.isNotEmpty ??
                                        false)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        child: _buildSocialButton(
                                          icon: Icons.camera_alt,
                                          onTap: () => _openUrl(
                                            social['instagram'] as String,
                                          ),
                                        ),
                                      ),
                                    if ((social['behance'] as String?)
                                            ?.isNotEmpty ??
                                        false)
                                      _buildSocialButton(
                                        icon: Icons.work,
                                        onTap: () => _openUrl(
                                          social['behance'] as String,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // External Link (if exists)
                        if (externalLink.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _openUrl(externalLink),
                            borderRadius: BorderRadius.circular(12),
                            child: _buildGlassCard(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF3B82F6),
                                          Color(0xFF60A5FA),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.link_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tautan Eksternal',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.white60,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          externalLink,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blueAccent,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.open_in_new_rounded,
                                    color: Colors.white60,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 100), // Space for bottom button
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top Navigation: Back & Share Buttons (Glass Circles)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button (Glass)
                  _buildGlassCircleButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  // Share Button (Glass)
                  _buildGlassCircleButton(
                    icon: Icons.share_rounded,
                    onTap: () => _shareArtwork(title, imageUrl),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sticky Action Bar (Glass)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Like Button
                      Expanded(
                        flex: 3,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isLiking ? null : _likeArtwork,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFEC4899), // Pink
                                    Color(0xFFF472B6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFEC4899,
                                    ).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.favorite_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Suka',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Comment Button
                      Expanded(
                        flex: 2,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Fitur komentar akan segera hadir!',
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF3B82F6), // Blue
                                    Color(0xFF60A5FA),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF3B82F6,
                                    ).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.comment_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Komentar',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Glass Card Builder
  Widget _buildGlassCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // Info Glass Card with Icon
  Widget _buildInfoGlassCard({
    required IconData icon,
    required Gradient iconGradient,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: iconGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: iconGradient.colors.first.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        content,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: Colors.white,
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
    );
  }

  // Glass Circle Button (Back/Share)
  Widget _buildGlassCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _videoController?.removeListener(() {});
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController == null) return;
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    setState(() {
      _isVideoPlaying = _videoController!.value.isPlaying;
    });
  }

  Future<void> _likeArtwork() async {
    setState(() {
      _isLiking = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final roleRow = await Supabase.instance.client
            .from('users')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();
        final role = roleRow != null ? (roleRow['role'] as String?) : null;
        if (role == 'artist') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Akun Artist tidak dapat memberikan like.'),
              ),
            );
          }
          return;
        }
      }

      final currentLikes = widget.artwork['likes_count'] ?? 0;
      await Supabase.instance.client
          .from('artworks')
          .update({'likes_count': currentLikes + 1})
          .eq('id', widget.artwork['id']);

      setState(() {
        widget.artwork['likes_count'] = currentLikes + 1;
      });
    } catch (e) {
      debugPrint('Error liking artwork: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memberikan like: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLiking = false;
      });
    }
  }

  void _shareArtwork(String title, String imageUrl) {
    final shareText =
        '''
🎨 $title

Lihat karya seni ini di UNP Art Space!

#UNPArtSpace #KaryaSeni
    ''';

    Share.share(shareText, subject: title);
  }
}

// Full Screen Image View Widget
class _FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _FullScreenImageView({required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Interactive Image Viewer with Zoom
          Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.black,
                    child: Icon(
                      Icons.broken_image,
                      size: 100,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Close Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    customBorder: const CircleBorder(),
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
