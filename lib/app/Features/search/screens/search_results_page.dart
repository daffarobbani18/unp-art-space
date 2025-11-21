import 'package:flutter/material.dart';
import 'dart:ui';
import '../../artist/screens/artist_detail_page.dart';
import '../../artwork/screens/artwork_detail_page.dart';
import '../../../shared/widgets/custom_network_image.dart';

class SearchResultsPage extends StatelessWidget {
  final String query;
  final List<Map<String, dynamic>> artistResults;
  final List<Map<String, dynamic>> artworkResults;

  const SearchResultsPage({
    super.key,
    required this.query,
    required this.artistResults,
    required this.artworkResults,
  });

  Widget _buildGlassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildArtistCard(BuildContext context, Map<String, dynamic> artist) {
    final name = artist['name'] ?? 'Unknown Artist';
    final profileImage = artist['profile_image_url'] ?? '';
    final bio = artist['bio'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ArtistDetailPage(artistId: artist['id']),
          ),
        );
      },
      child: _buildGlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // Profile Image
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: profileImage.isNotEmpty
                    ? CustomNetworkImage(
                        imageUrl: profileImage,
                        fit: BoxFit.cover,
                        borderRadius: 50,
                      )
                    : Center(
                        child: Text(
                          name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Artist Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      bio,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtworkCard(BuildContext context, Map<String, dynamic> artwork) {
    final title = artwork['title'] ?? 'Untitled';
    final artistName = artwork['users']?['name'] ?? artwork['artist_name'] ?? 'Unknown Artist';
    final imageUrl = artwork['media_url'] ?? artwork['thumbnail_url'] ?? artwork['image_url'] ?? '';
    final category = artwork['category'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ArtworkDetailPage(artwork: artwork),
          ),
        );
      },
      child: _buildGlassContainer(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            // Artwork Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Container(
                width: 100,
                height: 100,
                color: Colors.white.withOpacity(0.05),
                child: imageUrl.isNotEmpty
                    ? CustomNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        borderRadius: 0,
                      )
                    : const Icon(
                        Icons.image_not_supported_outlined,
                        size: 40,
                        color: Colors.white38,
                      ),
              ),
            ),
            // Artwork Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by $artistName',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalResults = artistResults.length + artworkResults.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hasil Pencarian',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '"$query"',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
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
        child: SafeArea(
          child: totalResults == 0
              ? _buildEmptyState(
                  icon: Icons.search_off_rounded,
                  message: 'Tidak ada hasil untuk "$query"',
                )
              : ListView(
                  padding: const EdgeInsets.only(top: 16, bottom: 100),
                  children: [
                    // Total Results Summary
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildGlassContainer(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.greenAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ditemukan $totalResults hasil',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Artists Section
                    if (artistResults.isNotEmpty) ...[
                      _buildSectionHeader(
                        icon: Icons.person_rounded,
                        title: 'Seniman',
                        count: artistResults.length,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: artistResults
                              .map((artist) => _buildArtistCard(context, artist))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Artworks Section
                    if (artworkResults.isNotEmpty) ...[
                      _buildSectionHeader(
                        icon: Icons.palette_rounded,
                        title: 'Karya Seni',
                        count: artworkResults.length,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: artworkResults
                              .map((artwork) => _buildArtworkCard(context, artwork))
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}