import 'package:flutter/material.dart';
import '../../../../main/main_app.dart'; // Untuk akses supabase
import '../../artwork/screens/artwork_detail_page.dart';
import '../../artwork/screens/edit_artwork_page.dart';
import '../../profile/screens/setting_page.dart';
import '../../profile/widgets/artist_profile_header.dart';
import '../../profile/screens/edit_profile_page.dart';

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
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Navigasi ke Halaman Pengaturan
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              ).then((_) { // <-- INI BAGIAN PENTINGNYA
                // Refresh halaman profil setelah kembali dari halaman Settings
                setState(() {
                  _userProfileFuture = _fetchUserProfile();
                  _myArtworksFuture = _fetchMyArtworks();
                });
              });
            },
          ),
        ],
      ),
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          debugPrint('ProfilePage.PointerDown at ${event.localPosition} global=${event.position}');
        },
        onPointerUp: (event) {
          debugPrint('ProfilePage.PointerUp at ${event.localPosition} global=${event.position}');
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header profil + stats + conditional content berdasarkan role
            FutureBuilder<Map<String, dynamic>>(
              future: _userProfileFuture,
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (userSnap.hasError) {
                  return Column(
                    children: [
                      const Text('Gagal memuat profil.'),
                      const SizedBox(height: 8),
                      Text(userSnap.error.toString()),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => setState(() => _userProfileFuture = _fetchUserProfile()),
                        child: const Text('Coba lagi'),
                      ),
                    ],
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

                        const Divider(thickness: 2),
                        const SizedBox(height: 12),

                        // Conditional: artist -> tampilkan Karya Saya; selainnya tampilkan placeholder "Karya yang Disukai"
                        if (role == 'artist') ...[
                          const Text('Karya Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 12),

                          // Tampilkan konten galeri berdasarkan artSnap state
                          if (artSnap.connectionState == ConnectionState.waiting) ...[
                            const Center(child: CircularProgressIndicator()),
                          ] else if (artSnap.hasError) ...[
                            Column(
                              children: [
                                const Text('Gagal memuat karya.'),
                                Text(artSnap.error.toString()),
                                ElevatedButton(
                                  onPressed: () => setState(() => _myArtworksFuture = _fetchMyArtworks()),
                                  child: const Text('Coba lagi'),
                                ),
                              ],
                            ),
                          ] else if (artworks.isEmpty) ...[
                            const Text('Anda belum mengunggah karya.'),
                          ] else ...[
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.8),
                              itemCount: artworks.length,
                              itemBuilder: (context, index) {
                                final artwork = artworks[index];
                                final status = (artwork['status'] ?? '').toString();
                                final imageUrl = artwork['media_url'] ?? '';

                                return Card(
                                  clipBehavior: Clip.hardEdge,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Stack(
                                    children: [
                                      InkWell(
                                        onTap: () => _navigateToDetail(artwork),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: imageUrl.isNotEmpty
                                                  ? Image.network(imageUrl, fit: BoxFit.cover)
                                                  : Container(color: Colors.grey[300]),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(artwork['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Status chip top-left
                                      Positioned(
                                        left: 8,
                                        top: 8,
                                        child: Chip(
                                          label: Text(status == 'approved' ? 'Disetujui' : (status == 'rejected' ? 'Ditolak' : 'Menunggu')),
                                          backgroundColor: status == 'approved' ? Colors.green[100] : (status == 'rejected' ? Colors.red[100] : Colors.orange[100]),
                                        ),
                                      ),
                                      // Edit/Delete if owner
                                      if (_isOwnProfile)
                                        Positioned(
                                          right: 4,
                                          top: 4,
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                                                onPressed: () {
                                                  Navigator.of(context).push(MaterialPageRoute(builder: (c) => EditArtworkPage(artwork: artwork))).then((_) {
                                                    setState(() {
                                                      _myArtworksFuture = _fetchMyArtworks();
                                                    });
                                                  });
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                                                onPressed: () => _deleteArtwork(artwork['id'], artwork['media_url']),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ] else ...[
                          // Viewer / non-artist view
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text('Karya yang Disukai', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center,),
                          ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Text('Fitur "Karya yang Disukai" akan segera hadir.'),
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
    ),
    );
  }
}