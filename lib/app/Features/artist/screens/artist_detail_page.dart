import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../profile/widgets/artist_profile_header.dart';

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

  // Palet warna brand kita
  static const Color deepBlue = Color(0xFF1E3A8A);
  static const Color lightBackground = Color(0xFFF8F7FA);

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
        .eq('status', 'disetujui');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _artistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Seniman tidak ditemukan.'));
          }

          final artist = snapshot.data!;
          final socialMedia = (artist['social_media'] is Map) ? Map<String, dynamic>.from(artist['social_media']) : <String, dynamic>{};
          final displayName = (artist['name'] as String?)?.toString() ?? 'Seniman';
          final specialization = (artist['specialization'] as String?)?.toString() ?? '';
          final bio = (artist['bio'] as String?)?.toString() ?? 'Seniman ini belum menambahkan bio.';

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [ //START ############################
                FutureBuilder<List<Map<String, dynamic>>>(
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
                // --- HEADER DENGAN STACK ---
                // (optional commented UI code removed or left commented intentionally)

                const SizedBox(height: 12),

                // --- GALERI KARYA SENIMAN ---
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _artworksFuture,
                  builder: (context, artworkSnapshot) {
                    if (artworkSnapshot.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(child: CircularProgressIndicator(color: deepBlue)),
                      );
                    }
                    if (artworkSnapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(child: Text('Gagal memuat karya.', style: TextStyle(color: Colors.grey[700]))),
                      );
                    }
                    final artworks = artworkSnapshot.data ?? [];
                    if (artworks.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(child: Text('Seniman ini belum punya karya.', style: TextStyle(color: Colors.grey[700]))),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: MasonryGridView.count(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        itemCount: artworks.length,
                        itemBuilder: (context, index) {
                          final art = artworks[index];
                          final imageUrl = (art['media_url'] as String?) ?? (art['image_url'] as String?) ?? '';
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ArtworkDetailPage(artwork: art),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 3 / 4,
                                child: Image.network(
                                  imageUrl.isNotEmpty ? imageUrl : 'https://picsum.photos/seed/art_${art['id']}/400/600',
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Center(child: CircularProgressIndicator()),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
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
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}