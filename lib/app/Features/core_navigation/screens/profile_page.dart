import 'package:flutter/material.dart';
import '../../../../main/main_app.dart'; // Untuk akses supabase
import '../../artwork/screens/artwork_detail_page.dart';
import '../../artwork/screens/edit_artwork_page.dart';
import '../../profile/screens/setting_page.dart';
import '../../profile/widgets/artist_profile_header.dart';
import '../../profile/screens/edit_profile_page.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_animations.dart';

class ProfilePage extends StatefulWidget {
  // If userId is provided, this page shows that user's public profile.
  // If null, it shows the currently signed-in user's profile.
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> _userProfileFuture;
  late Future<List<Map<String, dynamic>>> _myArtworksFuture;
  // The id of the profile being viewed. If empty, no user available.
  late String _userId;
  // Whether the viewed profile belongs to the signed-in user
  late bool _isOwnProfile;

  @override
  void initState() {
    super.initState();
    // Resolve which user id we're showing: explicit widget.userId wins, otherwise current user
    _userId = widget.userId ?? supabase.auth.currentUser?.id ?? '';
    _isOwnProfile = supabase.auth.currentUser?.id == _userId;

    _userProfileFuture = _fetchUserProfile();
    _myArtworksFuture = _fetchMyArtworks();
  }

  Future<Map<String, dynamic>> _fetchUserProfile() async {
    // Use maybeSingle to avoid throwing if row not found
    final result = await supabase.from('users').select().eq('id', _userId).maybeSingle();
    if (result != null) return result;

    // Jika baris profil belum ada di tabel 'users', coba bangun profil dari Auth
    final authUser = supabase.auth.currentUser;
    if (authUser == null) return <String, dynamic>{};

    final fallback = <String, dynamic>{
      'id': authUser.id,
      'name': authUser.userMetadata?['name'] ?? '',
      'email': authUser.email ?? '',
      'role': 'viewer',
      'specialization': null,
    };

    // Coba insert row users agar profil tersedia untuk ke depannya (jika policy mengizinkan)
    try {
      await supabase.from('users').insert(fallback);
    } catch (e) {
      // Jangan crash app jika insert gagal; masih tampilkan fallback
      debugPrint('Gagal membuat row users otomatis: $e');
    }

    return fallback;
  }

  Future<List<Map<String, dynamic>>> _fetchMyArtworks() async {
    if (_userId.isEmpty) return [];
    return await supabase.from('artworks').select().eq('artist_id', _userId).order('created_at');
  }

  //FUNGSI UNTUK LIHAT
  void _navigateToDetail(Map<String, dynamic> artwork) {
    // Perbaikan: Kirim seluruh objek artwork, bukan hanya id
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ArtworkDetailPage(artwork: artwork),
      ),
    );
  }

  // --- FUNGSI UNTUK DELETE ---
  Future<void> _deleteArtwork(int artworkId, String imageUrl) async {
    // Tampilkan dialog konfirmasi
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Karya'),
        content: const Text('Apakah Anda yakin ingin menghapus karya ini secara permanen?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      // 1. Hapus data dari tabel 'artworks'
      await supabase.from('artworks').delete().eq('id', artworkId);

      // 2. Hapus file gambar dari 'Storage'
      final fileName = imageUrl.split('/').last;
      // Path di storage adalah public/user_id/nama_file
      await supabase.storage.from('artworks').remove(['public/$_userId/$fileName']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Karya berhasil dihapus.'), backgroundColor: Colors.green));
        // Refresh daftar karya
        setState(() {
          _myArtworksFuture = _fetchMyArtworks();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Profil Saya',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: AppTheme.textPrimary.withOpacity(0.1),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_rounded, color: AppTheme.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              ).then((_) {
                setState(() {
                  _userProfileFuture = _fetchUserProfile();
                  _myArtworksFuture = _fetchMyArtworks();
                });
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header profil + stats + conditional content berdasarkan role
            FutureBuilder<Map<String, dynamic>>(
              future: _userProfileFuture,
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceLg * 2),
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  );
                }
                if (userSnap.hasError) {
                  return FadeInAnimation(
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spaceLg),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
                          const SizedBox(height: AppTheme.spaceSm),
                          Text(
                            'Gagal memuat profil.',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceXs),
                          Text(
                            userSnap.error.toString(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppTheme.spaceMd),
                          BounceAnimation(
                            onTap: () => setState(() => _userProfileFuture = _fetchUserProfile()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spaceMd,
                                vertical: AppTheme.spaceSm,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Text(
                                'Coba Lagi',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final user = userSnap.data ?? <String, dynamic>{};

                final displayName = (user['name'] as String?) ?? 'Pengguna';
                final specialization = (user['specialization'] as String?) ?? '';
                final department = (user['department'] as String?) ?? '';
                final bio = (user['bio'] as String?) ?? '';
                final likesReceived = user['likes_received'] ?? user['likes_count'] ?? 0;
                final socialMedia = user['social_media'] as Map<String, dynamic>?;

                // Ambil role pengguna untuk conditional rendering
                final role = (user['role'] as String?) ?? 'viewer';

                // Gunakan future artworks untuk header (artwork count) dan juga untuk menampilkan galeri jika artist
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _myArtworksFuture,
                  builder: (context, artSnap) {
                    final artCount = (artSnap.hasData ? artSnap.data!.length : 0);
                    final artworks = artSnap.data ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 12),

                            // Header profil asli tetap digunakan, tetapi sekarang menerima data nyata dan callback
                            ArtistProfileHeader(
                              role: user['role'] ?? 'viewer',
                              isOwnProfile: _isOwnProfile,
                              name: displayName,
                              specialization: [specialization, department].where((s) => s.isNotEmpty).join(' • '),
                              bio: bio,
                              artworkCount: artCount,
                              likesReceived: likesReceived,
                              socialMedia: socialMedia ?? <String, dynamic>{},
                              onEditProfile: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const EditProfilePage()),
                                ).then((_) {
                                  // refresh profil setelah edit
                                  setState(() {
                                    _userProfileFuture = _fetchUserProfile();
                                    _myArtworksFuture = _fetchMyArtworks();
                                  });
                                });
                              },
                              artistId: user['id'] ?? '',
                              onProfileUpdated: () {
                                setState(() {
                                  _userProfileFuture = _fetchUserProfile();
                                });
                              },
                              userData: user,
                            ),
                          ],
                        ),

                        const SizedBox(height: AppTheme.spaceLg),

                        // Conditional: artist -> tampilkan Karya Saya; selainnya tampilkan placeholder "Karya yang Disukai"
                        if (role == 'artist') ...[
                          FadeSlideAnimation(
                            delay: const Duration(milliseconds: 100),
                            child: Text(
                              'Karya Saya',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontFamily: 'Playfair Display',
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceMd),

                          // Tampilkan konten galeri berdasarkan artSnap state
                          if (artSnap.connectionState == ConnectionState.waiting) ...[
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppTheme.spaceLg),
                                child: CircularProgressIndicator(color: AppTheme.primary),
                              ),
                            ),
                          ] else if (artSnap.hasError) ...[
                            FadeInAnimation(
                              child: Container(
                                padding: const EdgeInsets.all(AppTheme.spaceMd),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 32),
                                    const SizedBox(height: AppTheme.spaceSm),
                                    Text(
                                      'Gagal memuat karya.',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: AppTheme.error,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spaceXs),
                                    Text(
                                      artSnap.error.toString(),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppTheme.spaceSm),
                                    BounceAnimation(
                                      onTap: () => setState(() => _myArtworksFuture = _fetchMyArtworks()),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppTheme.spaceMd,
                                          vertical: AppTheme.spaceSm,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.primaryGradient,
                                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                        ),
                                        child: Text(
                                          'Coba Lagi',
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else if (artworks.isEmpty) ...[
                            FadeInAnimation(
                              child: Container(
                                padding: const EdgeInsets.all(AppTheme.spaceLg * 2),
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
                                      'Anda belum mengunggah karya.',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: AppTheme.spaceSm,
                                mainAxisSpacing: AppTheme.spaceSm,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: artworks.length,
                              itemBuilder: (context, index) {
                                final artwork = artworks[index];
                                final status = (artwork['status'] ?? '').toString();
                                final imageUrl = artwork['media_url'] ?? '';

                                return RevealAnimation(
                                  delay: Duration(milliseconds: 50 * index),
                                  child: AnimatedCard(
                                    onTap: () => _navigateToDetail(artwork),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                        boxShadow: AppTheme.shadowMd,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Image with Status and Actions
                                          Expanded(
                                            child: Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.only(
                                                    topLeft: Radius.circular(AppTheme.radiusMd),
                                                    topRight: Radius.circular(AppTheme.radiusMd),
                                                  ),
                                                  child: imageUrl.isNotEmpty
                                                      ? Image.network(
                                                          imageUrl,
                                                          width: double.infinity,
                                                          height: double.infinity,
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
                                                                size: 32,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      : Container(
                                                          color: AppTheme.surface,
                                                          child: Center(
                                                            child: Icon(
                                                              Icons.image_not_supported_rounded,
                                                              color: AppTheme.textTertiary,
                                                              size: 32,
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                                
                                                // Status Badge - Top Left
                                                Positioned(
                                                  left: AppTheme.spaceXs,
                                                  top: AppTheme.spaceXs,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: AppTheme.spaceSm,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: status == 'approved'
                                                          ? AppTheme.success
                                                          : (status == 'rejected' ? AppTheme.error : AppTheme.warning),
                                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                                      boxShadow: AppTheme.shadowSm,
                                                    ),
                                                    child: Text(
                                                      status == 'approved'
                                                          ? 'Disetujui'
                                                          : (status == 'rejected' ? 'Ditolak' : 'Pending'),
                                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                
                                                // Edit & Delete Icons - Top Right
                                                if (_isOwnProfile)
                                                  Positioned(
                                                    right: AppTheme.spaceXs,
                                                    top: AppTheme.spaceXs,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Colors.black.withOpacity(0.6),
                                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          InkWell(
                                                            onTap: () {
                                                              Navigator.of(context)
                                                                  .push(MaterialPageRoute(
                                                                      builder: (c) => EditArtworkPage(artwork: artwork)))
                                                                  .then((_) {
                                                                setState(() {
                                                                  _myArtworksFuture = _fetchMyArtworks();
                                                                });
                                                              });
                                                            },
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(6),
                                                              child: Icon(
                                                                Icons.edit_rounded,
                                                                size: 16,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            width: 1,
                                                            height: 16,
                                                            color: Colors.white.withOpacity(0.3),
                                                          ),
                                                          InkWell(
                                                            onTap: () => _deleteArtwork(artwork['id'], artwork['media_url']),
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(6),
                                                              child: Icon(
                                                                Icons.delete_rounded,
                                                                size: 16,
                                                                color: AppTheme.error,
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
                                          
                                          // Title
                                          Padding(
                                            padding: const EdgeInsets.all(AppTheme.spaceSm),
                                            child: Text(
                                              artwork['title'] ?? '',
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textPrimary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ] else ...[
                          // Viewer / non-artist view
                          FadeInAnimation(
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.spaceLg * 2),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppTheme.spaceLg),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.secondary.withOpacity(0.1),
                                    ),
                                    child: Icon(
                                      Icons.favorite_outline_rounded,
                                      size: 64,
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spaceMd),
                                  Text(
                                    'Karya yang Disukai',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontFamily: 'Playfair Display',
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppTheme.spaceXs),
                                  Text(
                                    'Fitur ini akan segera hadir.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}