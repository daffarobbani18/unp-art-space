import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../artist/screens/artist_detail_page.dart';
import '../../auth/screens/login_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../shared/widgets/custom_network_image.dart';

class ArtworkDetailPage extends StatefulWidget {
  final Map<String, dynamic>? artwork;
  final int? artworkId;
  final String? submissionId;

  const ArtworkDetailPage({Key? key, required this.artwork})
      : artworkId = null,
        submissionId = null,
        super(key: key);

  const ArtworkDetailPage.fromId({Key? key, required this.artworkId})
      : artwork = null,
        submissionId = null,
        super(key: key);

  const ArtworkDetailPage.fromSubmission({Key? key, required this.submissionId})
      : artwork = null,
        artworkId = null,
        super(key: key);

  @override
  State<ArtworkDetailPage> createState() => _ArtworkDetailPageState();
}

class _ArtworkDetailPageState extends State<ArtworkDetailPage>
    with SingleTickerProviderStateMixin {
  bool _isLiking = false;
  bool _isLiked = false;
  Map<String, dynamic>? _loadedArtwork;
  bool _isLoading = false;
  bool _isGuestMode = false;
  int _likeCount = 0;
  int _commentCount = 0;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isZoomButtonVisible = true;

  @override
  void initState() {
    super.initState();

    // Initialize Indonesian locale for date formatting
    initializeDateFormatting('id_ID', null);

    // Check if user is logged in (Guest Mode)
    final user = Supabase.instance.client.auth.currentUser;
    _isGuestMode = user == null;

    // Fetch artwork based on source
    if (widget.submissionId != null) {
      // Coming from /submission/{uuid} (QR Code scan)
      _fetchArtworkFromSubmission();
    } else if (widget.artworkId != null) {
      // Coming from /artwork/{id} (Legacy deep link)
      _fetchArtworkData();
    } else {
      // Coming from navigation with artwork data
      _loadedArtwork = widget.artwork;
    }

    // Initialize like status and counts (only if logged in)
    if (!_isGuestMode) {
      _initializeLikeStatus();
      _loadCommentCount();
    }

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

    _scrollController.addListener(() {
      // Sembunyikan button zoom saat scroll melewati 50px
      if (_scrollController.offset > 50 && _isZoomButtonVisible) {
        setState(() => _isZoomButtonVisible = false);
      } else if (_scrollController.offset <= 50 && !_isZoomButtonVisible) {
        setState(() => _isZoomButtonVisible = true);
      }
    });

    _animationController.forward();

    // Video setup - only if artwork data is available
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    final artwork = _loadedArtwork ?? widget.artwork;
    if (artwork == null) return;

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
    // Show loading indicator while fetching data
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F2027),
                Color(0xFF203A43),
                Color(0xFF2C5364),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF8B5CF6),
            ),
          ),
        ),
      );
    }

    final artwork = _loadedArtwork ?? widget.artwork;
    
    // Show error if no artwork data
    if (artwork == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F2027),
                Color(0xFF203A43),
                Color(0xFF2C5364),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.white54,
                ),
                const SizedBox(height: 16),
                Text(
                  'Karya tidak ditemukan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final artworkType = (artwork['artwork_type'] as String?) ?? 'image';
    final title = (artwork['title'] as String?) ?? 'Untitled';
    final imageUrl =
        (artwork['media_url'] as String?) ??
        (artwork['image_url'] as String?) ??
        '';

    // User/Artist info
    final users = (artwork['users'] as Map<String, dynamic>?) ?? {};
    final artistName =
        (users['name'] as String?) ??
        (artwork['artist_name'] as String?) ??
        'Unknown Artist';
    final artistId = (artwork['artist_id'] as String?) ?? '';
    final artistAvatar = (users['profile_image_url'] as String?) ?? '';
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
                                ? CustomNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    borderRadius: 0,
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
                              '$_likeCount Likes • $_commentCount Komentar',
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
                  child: _isGuestMode
                      ? _buildGuestModeBanner()
                      : Row(
                          children: [
                            // Like Button
                            Expanded(
                              flex: 3,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isLiking ? null : _toggleLike,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: _isLiked
                                            ? [
                                                const Color(0xFFDC2626), // Red
                                                const Color(0xFFEF4444),
                                              ]
                                            : [
                                                const Color(0xFFEC4899), // Pink
                                                const Color(0xFFF472B6),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isLiked
                                                  ? const Color(0xFFDC2626)
                                                  : const Color(0xFFEC4899))
                                              .withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _isLiked ? 'Disukai' : 'Suka',
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
                                  onTap: _showCommentsModal,
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

          // Zoom Button (Top layer above scroll)
          Positioned(
            top: 180,
            right: 0,
            left: 0,
            child: AnimatedOpacity(
              opacity: _isZoomButtonVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_isZoomButtonVisible,
                child: Container(
                  height: imageHeight,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (imageUrl.isNotEmpty && artworkType == 'image') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _FullScreenImageView(
                                imageUrl: imageUrl,
                                heroTag: 'artwork_${artwork['id']}_button',
                              ),
                            ),
                          );
                        }
                      },
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.zoom_out_map,
                          color: Colors.white,
                          size: 22,
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

  Future<void> _fetchArtworkData() async {
    if (widget.artworkId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔍 Fetching artwork with ID: ${widget.artworkId}');
      
      final response = await Supabase.instance.client
          .from('artworks')
          .select('*, users(*)')
          .eq('id', widget.artworkId!)
          .maybeSingle();

      debugPrint('📦 Response: $response');

      if (response == null) {
        debugPrint('❌ Artwork not found in database');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Show error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Karya dengan ID ${widget.artworkId} tidak ditemukan'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      debugPrint('✅ Artwork found: ${response['title']}');

      if (mounted) {
        setState(() {
          _loadedArtwork = response;
          _isLoading = false;
        });

        // Initialize video player if artwork is video type
        _initializeVideoPlayer();

        // Initialize like status and comments if user is logged in
        if (!_isGuestMode) {
          _initializeLikeStatus();
          _loadCommentCount();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching artwork: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Show error snackbar with details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _fetchArtworkFromSubmission() async {
    if (widget.submissionId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔍 Fetching artwork from submission UUID: ${widget.submissionId}');
      
      // Step 1: Get submission to find artwork_id
      final submissionResponse = await Supabase.instance.client
          .from('event_submissions')
          .select('id, artwork_id, artist_id, status')
          .eq('id', widget.submissionId!)
          .maybeSingle();

      debugPrint('📦 Submission Response: $submissionResponse');

      if (submissionResponse == null) {
        debugPrint('❌ Submission not found in database');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Karya tidak ditemukan atau sudah dihapus dari event'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final artworkId = submissionResponse['artwork_id'];
      final artistId = submissionResponse['artist_id'];
      debugPrint('📌 Found artwork_id: $artworkId, artist_id: $artistId');

      // Step 2: Fetch artwork data
      final artworkResponse = await Supabase.instance.client
          .from('artworks')
          .select('*')
          .eq('id', artworkId)
          .maybeSingle();

      debugPrint('🎨 Artwork Response: $artworkResponse');

      if (artworkResponse == null) {
        debugPrint('❌ Artwork not found');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Karya tidak ditemukan'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Step 3: Fetch user/artist info from users table
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('*')
          .eq('id', artistId)
          .maybeSingle();

      debugPrint('👤 User Response: $userResponse');

      // Merge artwork with user data
      final artworkData = {
        ...artworkResponse,
        'users': userResponse ?? {},
      };

      debugPrint('✅ Artwork found from submission: ${artworkData['title']}');

      if (mounted) {
        setState(() {
          _loadedArtwork = artworkData;
          _isLoading = false;
        });

        // Initialize video player if artwork is video type
        _initializeVideoPlayer();

        // Initialize like status and comments if user is logged in
        if (!_isGuestMode) {
          _initializeLikeStatus();
          _loadCommentCount();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching submission: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _initializeLikeStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final artwork = _loadedArtwork ?? widget.artwork;
      if (artwork == null) return;

      final artworkId = artwork['id'].toString();

      // Check if user already liked this artwork
      final likeResponse = await Supabase.instance.client
          .from('likes')
          .select()
          .eq('user_id', user.id)
          .eq('artwork_id', artworkId)
          .maybeSingle();

      // Count total likes
      final countResponse = await Supabase.instance.client
          .from('likes')
          .select()
          .eq('artwork_id', artworkId);

      if (mounted) {
        setState(() {
          _isLiked = likeResponse != null;
          _likeCount = countResponse.length;
        });
      }
    } catch (e) {
      debugPrint('Error initializing like status: $e');
    }
  }

  Future<void> _loadCommentCount() async {
    try {
      final artwork = _loadedArtwork ?? widget.artwork;
      if (artwork == null) return;

      final artworkId = artwork['id'].toString();
      final response = await Supabase.instance.client
          .from('comments')
          .select()
          .eq('artwork_id', artworkId);

      if (mounted) {
        setState(() {
          _commentCount = response.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading comment count: $e');
    }
  }

  Future<void> _toggleLike() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan login terlebih dahulu'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Optimistic UI update
    final previousLiked = _isLiked;
    final previousCount = _likeCount;
    
    setState(() {
      _isLiking = true;
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
    });

    try {
      final artwork = _loadedArtwork ?? widget.artwork;
      if (artwork == null) return;

      final artworkId = artwork['id'].toString();

      if (previousLiked) {
        // Unlike: Delete from likes table
        await Supabase.instance.client
            .from('likes')
            .delete()
            .eq('user_id', user.id)
            .eq('artwork_id', artworkId);
      } else {
        // Like: Insert to likes table
        await Supabase.instance.client.from('likes').insert({
          'user_id': user.id,
          'artwork_id': artworkId,
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      // Revert on error
      if (mounted) {
        setState(() {
          _isLiked = previousLiked;
          _likeCount = previousCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLiking = false;
        });
      }
    }
  }

  void _showCommentsModal() {
    final artwork = _loadedArtwork ?? widget.artwork;
    if (artwork == null) return;

    final artworkId = artwork['id'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsBottomSheet(
        artworkId: artworkId.toString(),
        onCommentAdded: () {
          _loadCommentCount();
        },
      ),
    );
  }

  Widget _buildGuestModeBanner() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _showDownloadDialog();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF8B5CF6), // Purple
                Color(0xFF3B82F6), // Blue
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.download_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Download Aplikasi',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Untuk like, comment & interaksi lainnya',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
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

  void _showDownloadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.phone_android_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'UNP Art Space',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  'Nikmati pengalaman lebih lengkap dengan aplikasi mobile kami',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Continue with Website Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to login page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: Text(
                      'Login untuk Berinteraksi',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Download App Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Show message that app is not available yet
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Aplikasi mobile sedang dalam pengembangan. Segera hadir di Play Store & App Store!',
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF8B5CF6),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 4),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      'Download Aplikasi',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: const Color(0xFF8B5CF6).withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                child: CustomNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  borderRadius: 0,
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

// Comments Bottom Sheet Widget
class _CommentsBottomSheet extends StatefulWidget {
  final String artworkId;
  final VoidCallback onCommentAdded;

  const _CommentsBottomSheet({
    required this.artworkId,
    required this.onCommentAdded,
  });

  @override
  State<_CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<_CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan login terlebih dahulu'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isSending = true);

    try {
      await Supabase.instance.client.from('comments').insert({
        'artwork_id': widget.artworkId,
        'user_id': user.id,
        'content': _commentController.text.trim(),
      });

      _commentController.clear();
      widget.onCommentAdded();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komentar berhasil dikirim'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim komentar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C).withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Komentar',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white70,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Comments List
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: Supabase.instance.client
                          .from('comments')
                          .stream(primaryKey: ['id'])
                          .eq('artwork_id', widget.artworkId)
                          .order('created_at', ascending: false),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          );
                        }

                        final comments = snapshot.data!;

                        if (comments.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.comment_outlined,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada komentar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            return _CommentItem(comment: comments[index]);
                          },
                        );
                      },
                    ),
                  ),

                  // Input Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _commentController,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Tulis komentar...',
                                  hintStyle: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                maxLines: null,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendComment(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isSending ? null : _sendComment,
                              borderRadius: BorderRadius.circular(25),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF3B82F6),
                                      Color(0xFF60A5FA),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: _isSending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Comment Item Widget
class _CommentItem extends StatelessWidget {
  final Map<String, dynamic> comment;

  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    final userId = comment['user_id'] as String?;
    final commentText = comment['content'] as String? ?? '';
    final createdAt = comment['created_at'] as String?;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUserProfile(userId),
      builder: (context, snapshot) {
        final userName = snapshot.data?['name'] as String? ?? 'User';
        final avatarUrl = snapshot.data?['profile_image_url'] as String? ?? '';
        final userRole = snapshot.data?['role'] as String? ?? '';
        final isArtist = userRole == 'artist';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar (Clickable)
              GestureDetector(
                onTap: () {
                  if (userId != null && isArtist) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArtistDetailPage(artistId: userId),
                      ),
                    );
                  }
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  backgroundImage:
                      avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          color: Colors.white.withOpacity(0.5),
                          size: 20,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Comment Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isArtist) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF8B5CF6),
                                  Color(0xFF6366F1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Artist',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        if (createdAt != null)
                          Text(
                            _formatTimeAgo(DateTime.parse(createdAt)),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      commentText,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchUserProfile(String? userId) async {
    if (userId == null) return null;
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('name, profile_image_url, role')
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('d MMM', 'id_ID').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}h lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}j lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m lalu';
    } else {
      return 'Baru saja';
    }
  }
}
