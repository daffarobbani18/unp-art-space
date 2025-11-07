import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import '../../artist/screens/artist_detail_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_animations.dart';

class ArtworkDetailPage extends StatefulWidget {
  final Map<String, dynamic> artwork;

  const ArtworkDetailPage({
    Key? key,
    required this.artwork,
  }) : super(key: key);

  @override
  State<ArtworkDetailPage> createState() => _ArtworkDetailPageState();
}

class _ArtworkDetailPageState extends State<ArtworkDetailPage> {
  bool _isLiking = false;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    final artwork = widget.artwork;
    final artworkType = (artwork['artwork_type'] as String?) ?? 'image';
    if (artworkType == 'video') {
      final mediaUrl = (artwork['media_url'] as String?) ?? (artwork['image_url'] as String?) ?? '';
      if (mediaUrl.isNotEmpty) {
        _videoController = VideoPlayerController.network(mediaUrl);
        _videoController!.initialize().then((_) {
          if (!mounted) return;
          setState(() {
            _isVideoInitialized = true;
            _isVideoPlaying = _videoController!.value.isPlaying;
          });
        }).catchError((e) {
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

  // Colors removed - now using AppTheme

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url) ?? Uri();
    if (uri.toString().isEmpty) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka tautan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final artwork = widget.artwork;
    final artworkType = (artwork['artwork_type'] as String?) ?? 'image';
    final title = (artwork['title'] as String?) ?? 'Untitled';
  final imageUrl = (artwork['media_url'] as String?) ?? (artwork['image_url'] as String?) ?? '';
    final likesCount = (artwork['likes_count'] ?? 0) as int;
    // user info might be nested under 'users' (per spec) or use artist_name fallback
    final users = (artwork['users'] as Map<String, dynamic>?) ?? {};
    final artistName = (users['name'] as String?) ??
        (artwork['artist_name'] as String?) ??
        'Unknown Artist';
    final artistId = (artwork['artist_id'] as String?) ?? '';
    final artistBio = (users['bio'] as String?) ?? 'Seniman ini belum memiliki bio.';
    final social = (users['social_media'] as Map<String, dynamic>?) ?? {};
    final description = (artwork['description'] as String?) ?? '';
    final externalLink = (artwork['external_link'] as String?) ?? '';

    // specs placeholder (if artwork contains a 'specs' map use it)
    final specs = (artwork['specs'] as Map<String, dynamic>?) ?? {
      'Tahun': artwork['year']?.toString() ?? '—',
      'Medium': artwork['medium'] ?? '—',
      'Ukuran': artwork['dimensions'] ?? '—',
    };

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 400.0,
            backgroundColor: AppTheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.favorite_border_rounded,
                  color: AppTheme.error,
                ),
                onPressed: _isLiking ? null : _likeArtwork,
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () => _shareArtwork(title, imageUrl),
              ),
              const SizedBox(width: AppTheme.spaceXs),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              // title: Text(
              //   title,
              //   maxLines: 1,
              //   overflow: TextOverflow.ellipsis,
              //   style: GoogleFonts.poppins(
              //     color: const Color.fromARGB(255, 199, 12, 237),
              //     fontSize: 16,
              //     fontWeight: FontWeight.w600,
              //   ),
              // ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (artworkType == 'image')
                    if (imageUrl.isNotEmpty)
                      PhotoView(
                        imageProvider: NetworkImage(imageUrl),
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 2.0,
                        heroAttributes: PhotoViewHeroAttributes(tag: artwork['id'].toString()),
                        backgroundDecoration: const BoxDecoration(color: Colors.white),
                        loadingBuilder: (context, progress) => const Center(child: CircularProgressIndicator()),
                      )
                    else
                      Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.image_not_supported, size: 60)))
                  else if (artworkType == 'video')
                    Center(
                      child: _videoController != null
                          ? AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  VideoPlayer(_videoController!),
                                  if (!_isVideoInitialized)
                                    const Center(child: CircularProgressIndicator()),
                                  Positioned(
                                    bottom: 12,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(_isVideoPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 42, color: Colors.white),
                                          onPressed: _togglePlayPause,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(color: Colors.black12, child: const Center(child: Icon(Icons.play_circle_fill, size: 72))),
                    )
                  else
                    Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.image_not_supported, size: 60))),
                  // gradient overlay bottom for readability
                  // Positioned(
                  //   left: 0,
                  //   right: 0,
                  //   bottom: 0,
                  //   height: 160,
                  //   child: Container(
                  //     decoration: BoxDecoration(
                  //       gradient: LinearGradient(
                  //         begin: Alignment.topCenter,
                  //         end: Alignment.bottomCenter,
                  //         colors: [
                  //           Colors.transparent,
                  //           // ignore: deprecated_member_use
                  //           Colors.black.withOpacity(0.65),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // small badge at bottom-left: UNP ART SPACE
                  // Positioned(
                  //   left: 16,
                  //   bottom: 20,
                  //   child: Text(
                  //     'UNP ART SPACE',
                  //     style: GoogleFonts.playfairDisplay(
                  //       color: AppTheme.secondary,
                  //       fontWeight: FontWeight.w700,
                  //       fontSize: 18,
                  //       shadows: [
                  //         const Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),

          // content
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header summary: title, artist, quick stats
                      Text(
                        title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          if (artistId.isNotEmpty) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ArtistDetailPage(artistId: artistId)),
                            );
                          }
                        },
                        child: Text(
                          'oleh $artistName',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.favorite_border, color: Colors.red[400]),
                          const SizedBox(width: 6),
                          Text(
                            '$likesCount',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.comment_outlined, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${artwork['comments_count'] ?? 0} Komentar',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Card with details
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Deskripsi Karya
                              Text(
                                'Deskripsi Karya',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (description.isNotEmpty)
                                Text(
                                  description,
                                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800], height: 1.5),
                                )
                              else
                                Text(
                                  '-',
                                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                                ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),

                              // Spesifikasi
                              Text(
                                'Spesifikasi',
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: specs.entries.map((e) {
                                  return Chip(
                                    backgroundColor: Colors.grey[100],
                                    label: Text('${e.key}: ${e.value}', style: GoogleFonts.poppins(fontSize: 13)),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),

                              // Tentang Seniman
                              Text(
                                'Tentang Seniman',
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary),
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: (){
                                  final artistId = artwork['artist_id'] as String?;
                                  if (artistId == null) return; 
                                  Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ArtistDetailPage(artistId: artistId),
                                  ),
                                  );
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: AppTheme.secondary.withOpacity(0.12),
                                      child: Text(
                                        artistName.isNotEmpty ? artistName[0].toUpperCase() : 'A',
                                        style: GoogleFonts.poppins(color: AppTheme.secondary, fontWeight: FontWeight.w700, fontSize: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            artistName,
                                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            artistBio,
                                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                                          ),
                                          const SizedBox(height: 10),
                                          if (social.isNotEmpty)
                                          Row(
                                            children: [
                                              if ((social['instagram'] as String?)?.isNotEmpty ?? false)
                                                IconButton(
                                                  icon: const Icon(Icons.camera_alt),
                                                  color: AppTheme.primary,
                                                  onPressed: () => _openUrl(social['instagram'] as String),
                                                ),
                                              if ((social['behance'] as String?)?.isNotEmpty ?? false)
                                                IconButton(
                                                  icon: const Icon(Icons.work),
                                                  color: AppTheme.secondary,
                                                  onPressed: () => _openUrl(social['behance'] as String),
                                                ),
                                              // add more platforms if present
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),
                              if (externalLink.isNotEmpty) ...[
                                const Divider(),
                                const SizedBox(height: 8),
                                Text(
                                  'Tautan Eksternal',
                                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _openUrl(externalLink),
                                  child: Row(
                                    children: [
                                      Icon(Icons.link, color: AppTheme.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          externalLink,
                                          style: GoogleFonts.poppins(color: Colors.blue[700], decoration: TextDecoration.underline),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.open_in_new, color: Colors.grey[700]),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action buttons: Like & Comment (large)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLiking ? null : _likeArtwork,
                              icon: const Icon(Icons.favorite, color: Colors.white),
                              label: Text('Suka', style: GoogleFonts.poppins(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur komentar akan segera hadir!')));
                              },
                              icon: const Icon(Icons.comment_outlined),
                              label: Text('Komentar', style: GoogleFonts.poppins(color: AppTheme.primary)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(color: AppTheme.primary),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
              childCount: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
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
        final roleRow = await Supabase.instance.client.from('users').select('role').eq('id', user.id).maybeSingle();
        final role = roleRow != null ? (roleRow['role'] as String?) : null;
        if (role == 'artist') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Akun Artist tidak dapat memberikan like.')),
          );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memberikan like: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLiking = false;
      });
    }
  }

  void _shareArtwork(String title, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bagikan Karya'),
        content: Text('Bagikan "$title" ke media sosial?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur share akan segera hadir!')));
            },
            child: const Text('Bagikan'),
          ),
        ],
      ),
    );
  }
}
