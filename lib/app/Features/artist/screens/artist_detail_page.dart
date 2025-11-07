import 'package:flutter/material.dart';
import '../../profile/widgets/artist_profile_header.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_animations.dart';

import '../../../../main/main_app.dart'; // Untuk akses supabase
import '../../artwork/screens/artwork_detail_page.dart';

class ArtistDetailPage extends StatefulWidget {
  final String artistId;
  const ArtistDetailPage({super.key, required this.artistId});

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  late final Future<Map<String, dynamic>> _artistFuture;
  late final Future<List<Map<String, dynamic>>> _artworksFuture;

  @override
  void initState() {
    super.initState();
    _artistFuture = _fetchArtistProfile();
    _artworksFuture = _fetchArtistArtworks();
  }

  Future<Map<String, dynamic>> _fetchArtistProfile() async {
    return await supabase.from('users').select().eq('id', widget.artistId).single();
  }

  Future<List<Map<String, dynamic>>> _fetchArtistArtworks() async {
    return await supabase
        .from('artworks')
        .select()
        .eq('artist_id', widget.artistId)
        .eq('status', 'approved');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _artistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_rounded, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: AppTheme.spaceMd),
                  Text(
                    'Seniman tidak ditemukan.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final artist = snapshot.data!;
          final socialMedia = (artist['social_media'] is Map) ? Map<String, dynamic>.from(artist['social_media']) : <String, dynamic>{};
          final displayName = (artist['name'] as String?)?.toString() ?? 'Seniman';
          final specialization = (artist['specialization'] as String?)?.toString() ?? '';
          final bio = (artist['bio'] as String?)?.toString() ?? 'Seniman ini belum menambahkan bio.';

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Artist Profile Header
                FadeInAnimation(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _artworksFuture,
                    builder: (context, artSnap) {
                      final artCount = artSnap.hasData ? artSnap.data!.length : 0;
                      return ArtistProfileHeader(
                        role: artist['role'] ?? 'viewer',
                        artistId: artist['id'],
                        name: displayName,
                        specialization: specialization,
                        bio: bio,
                        artworkCount: artCount,
                        likesReceived: 0, 
                        socialMedia: socialMedia,
                        isOwnProfile: false, 
                        onProfileUpdated: () {  }, 
                        userData: {}, 
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppTheme.spaceMd),

                // Gallery Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                  child: FadeSlideAnimation(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      'Galeri Karya',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'Playfair Display',
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMd),

                // Artworks Gallery
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _artworksFuture,
                  builder: (context, artworkSnapshot) {
                    if (artworkSnapshot.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceLg * 2),
                        child: Center(
                          child: CircularProgressIndicator(color: AppTheme.primary),
                        ),
                      );
                    }
                    if (artworkSnapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(AppTheme.spaceMd),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
                              const SizedBox(height: AppTheme.spaceSm),
                              Text(
                                'Gagal memuat karya.',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final artworks = artworkSnapshot.data ?? [];
                    if (artworks.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(AppTheme.spaceLg * 2),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppTheme.spaceLg),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primary.withOpacity(0.1),
                                ),
                                child: Icon(
                                  Icons.palette_outlined,
                                  size: 64,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceMd),
                              Text(
                                'Seniman ini belum punya karya.',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                      child: StaggeredListAnimation(
                        children: List.generate(artworks.length, (index) {
                          final art = artworks[index];
                          final imageUrl = (art['media_url'] as String?) ?? (art['image_url'] as String?) ?? '';
                          return RevealAnimation(
                            delay: Duration(milliseconds: 50 * index),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ArtworkDetailPage(artwork: art),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  boxShadow: AppTheme.shadowSm,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                  child: AspectRatio(
                                    aspectRatio: 3 / 4,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          imageUrl.isNotEmpty ? imageUrl : 'https://picsum.photos/seed/art_${art['id']}/400/600',
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, progress) {
                                            if (progress == null) return child;
                                            return Container(
                                              color: AppTheme.surface,
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  color: AppTheme.primary,
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (_, __, ___) => Container(
                                            color: AppTheme.surface,
                                            child: Center(
                                              child: Icon(
                                                Icons.broken_image_rounded,
                                                color: AppTheme.textTertiary,
                                                size: 48,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Gradient overlay at bottom for title
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(AppTheme.spaceSm),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  Colors.black.withOpacity(0.7),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                            child: Text(
                                              art['title'] ?? '',
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppTheme.spaceMd),
              ],
            ),
          );
        },
      ),
    );
  }
}