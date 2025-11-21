import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../main/main_app.dart';
import '../../artwork/screens/artwork_detail_page.dart';
import '../../../shared/widgets/custom_network_image.dart';

class ArtistDetailPage extends StatefulWidget {
  final String artistId;
  const ArtistDetailPage({super.key, required this.artistId});

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  late Future<Map<String, dynamic>> _artistFuture;
  late Future<List<Map<String, dynamic>>> _artworksFuture;

  // Glassmorphism gradient colors
  static const List<Color> _bgGradient = [
    Color(0xFF0F2027),
    Color(0xFF203A43),
    Color(0xFF2C5364),
  ];

  @override
  void initState() {
    super.initState();
    _artistFuture = _fetchArtistProfile();
    _artworksFuture = _fetchArtistArtworks();
  }

  Future<Map<String, dynamic>> _fetchArtistProfile() async {
    final result = await supabase
        .from('users')
        .select()
        .eq('id', widget.artistId)
        .maybeSingle();
    return result ?? <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> _fetchArtistArtworks() async {
    return await supabase
        .from('artworks')
        .select()
        .eq('artist_id', widget.artistId)
        .eq('status', 'approved')
        .order('created_at');
  }

  void _navigateToDetail(Map<String, dynamic> artwork) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ArtworkDetailPage(artwork: artwork),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildGlassCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: iconColor ?? Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl, String artistName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Full screen image with zoom capability
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(
                    tag: 'profile_image_$imageUrl',
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 100,
                            color: Colors.white54,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Back button (top left)
              SafeArea(
                child: Positioned(
                  top: 10,
                  left: 10,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Close button (top right)
              SafeArea(
                child: Positioned(
                  top: 10,
                  right: 10,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Artist name overlay
              SafeArea(
                child: Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          artistName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final coverHeight = screenHeight * 0.25;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Layer - Full screen gradient
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _bgGradient,
              ),
            ),
          ),

          // Content Layer
          SafeArea(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _artistFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_off_rounded,
                                  size: 64,
                                  color: Colors.red.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Seniman tidak ditemukan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final artist = snapshot.data!;
                final displayName = (artist['name'] as String?) ?? 'Seniman';
                final role = (artist['role'] as String?) ?? 'viewer';
                final specialization =
                    (artist['specialization'] as String?) ?? '';
                final department = (artist['department'] as String?) ?? '';
                final bio =
                    (artist['bio'] as String?) ??
                    'Seniman ini belum menambahkan bio.';
                final avatarUrl = (artist['profile_image_url'] as String?) ?? '';
                final coverUrl = (artist['cover_url'] as String?) ?? '';
                final socialMedia = (artist['social_media'] is Map)
                    ? Map<String, dynamic>.from(artist['social_media'])
                    : <String, dynamic>{};

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with Cover Image & Avatar
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Cover Image with Gradient Overlay
                          Container(
                            height: coverHeight,
                            decoration: BoxDecoration(
                              image: coverUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(coverUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              gradient: coverUrl.isEmpty
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.purple.shade700,
                                        Colors.blue.shade900,
                                      ],
                                    )
                                  : null,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.3),
                                    Colors.black.withOpacity(0.6),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Back Button
                          Positioned(
                            top: 10,
                            left: 16,
                            child: _buildGlassCircleButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                          ),

                          // Avatar (overlapping at bottom)
                          Positioned(
                            bottom: -50,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  if (avatarUrl.isNotEmpty) {
                                    _showFullImage(context, avatarUrl, displayName);
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 5,
                                        sigmaY: 5,
                                      ),
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 4,
                                          ),
                                        ),
                                        child: avatarUrl.isNotEmpty
                                            ? Hero(
                                                tag: 'profile_image_$avatarUrl',
                                                child: CustomNetworkImage(
                                                  imageUrl: avatarUrl,
                                                  fit: BoxFit.cover,
                                                  borderRadius: 100,
                                                ),
                                              )
                                            : Container(
                                                color: Colors.white.withOpacity(
                                                  0.1,
                                                ),
                                                child: Icon(
                                                  Icons.person_rounded,
                                                  size: 60,
                                                  color: Colors.white.withOpacity(
                                                    0.6,
                                                  ),
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

                      const SizedBox(height: 60),

                      // Artist Info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Text(
                              displayName,
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            if (role == 'artist' &&
                                (specialization.isNotEmpty ||
                                    department.isNotEmpty))
                              Text(
                                [
                                  specialization,
                                  department,
                                ].where((s) => s.isNotEmpty).join(' • '),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: role == 'artist'
                                    ? Colors.purple.withOpacity(0.3)
                                    : Colors.blue.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: role == 'artist'
                                      ? Colors.purple.withOpacity(0.5)
                                      : Colors.blue.withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                role == 'artist' ? 'Seniman' : 'Pengunjung',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Stats - Glass Card
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _artworksFuture,
                        builder: (context, artSnap) {
                          final artCount = artSnap.hasData
                              ? artSnap.data!.length
                              : 0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            artCount.toString(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Total Karya',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                      Column(
                                        children: [
                                          Text(
                                            '0',
                                            style: GoogleFonts.poppins(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Total Suka',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Bio - Glass Card
                      if (bio.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bio',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      bio,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.8),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Social Media Links
                      if (socialMedia.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Media Sosial',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (socialMedia['instagram'] != null &&
                                      socialMedia['instagram']
                                          .toString()
                                          .isNotEmpty)
                                    _buildSocialButton(
                                      icon: Icons.camera_alt_rounded,
                                      label: 'Instagram',
                                      onTap: () =>
                                          _launchUrl(socialMedia['instagram']),
                                      color: Colors.pink,
                                    ),
                                  if (socialMedia['twitter'] != null &&
                                      socialMedia['twitter']
                                          .toString()
                                          .isNotEmpty)
                                    _buildSocialButton(
                                      icon: Icons.tag_rounded,
                                      label: 'Twitter',
                                      onTap: () =>
                                          _launchUrl(socialMedia['twitter']),
                                      color: Colors.blue,
                                    ),
                                  if (socialMedia['facebook'] != null &&
                                      socialMedia['facebook']
                                          .toString()
                                          .isNotEmpty)
                                    _buildSocialButton(
                                      icon: Icons.facebook_rounded,
                                      label: 'Facebook',
                                      onTap: () =>
                                          _launchUrl(socialMedia['facebook']),
                                      color: Colors.blue.shade800,
                                    ),
                                  if (socialMedia['website'] != null &&
                                      socialMedia['website']
                                          .toString()
                                          .isNotEmpty)
                                    _buildSocialButton(
                                      icon: Icons.language_rounded,
                                      label: 'Website',
                                      onTap: () =>
                                          _launchUrl(socialMedia['website']),
                                      color: Colors.teal,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Gallery Section
                      if (role == 'artist')
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Galeri Karya',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Artworks Grid
                      if (role == 'artist')
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _artworksFuture,
                          builder: (context, artSnap) {
                            if (artSnap.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(48),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white70,
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (artSnap.hasError) {
                              return Padding(
                                padding: const EdgeInsets.all(20),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 8,
                                      sigmaY: 8,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.error_outline_rounded,
                                            color: Colors.red.shade400,
                                            size: 32,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Gagal memuat karya',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            final artworks = artSnap.data ?? [];
                            if (artworks.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(48),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                      child: Icon(
                                        Icons.palette_outlined,
                                        size: 64,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Seniman ini belum mengunggah karya',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.75,
                                    ),
                                itemCount: artworks.length,
                                itemBuilder: (context, index) {
                                  final artwork = artworks[index];
                                  final imageUrl = artwork['media_url'] ?? '';
                                  final title = artwork['title'] ?? '';

                                  return InkWell(
                                    onTap: () => _navigateToDetail(artwork),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10,
                                          sigmaY: 10,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.15,
                                              ),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              // Image
                                              Expanded(
                                                child: imageUrl.isNotEmpty
                                                    ? CustomNetworkImage(
                                                        imageUrl: imageUrl,
                                                        fit: BoxFit.cover,
                                                        borderRadius: 16,
                                                      )
                                                    : Container(
                                                          color: Colors.white
                                                              .withOpacity(
                                                                0.05,
                                                              ),
                                                          child: Center(
                                                            child: Icon(
                                                              Icons
                                                                  .image_not_supported_rounded,
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                    0.5,
                                                                  ),
                                                              size: 32,
                                                            ),
                                                          ),
                                                        ),
                                              ),

                                              // Title
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      title,
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 14,
                                                          ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                                },
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
