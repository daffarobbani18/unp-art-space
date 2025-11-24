import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../main/main_app.dart'; // Untuk akses supabase
import '../../artwork/screens/artwork_detail_page.dart';
import '../../artwork/screens/edit_artwork_page.dart';
import '../../profile/screens/setting_page.dart';
import '../../profile/widgets/artist_profile_header.dart';
import '../../profile/screens/edit_profile_page.dart';
import '../../../shared/widgets/custom_network_image.dart';

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

  // Glassmorphism gradient colors
  static const List<Color> _bgGradient = [
    Color(0xFF0F2027),
    Color(0xFF203A43),
    Color(0xFF2C5364),
  ];

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
    final result = await supabase
        .from('users')
        .select()
        .eq('id', _userId)
        .maybeSingle();
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
    
    try {
      final result = await supabase
          .from('artworks')
          .select()
          .eq('artist_id', _userId)
          .order('created_at');
      
      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      debugPrint('Error fetching artworks: $e');
      // Return empty list if error occurs (user might not be an artist or no artworks yet)
      return [];
    }
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
        content: const Text(
          'Apakah Anda yakin ingin menghapus karya ini secara permanen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
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
      await supabase.storage.from('artworks').remove([
        'public/$_userId/$fileName',
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Karya berhasil dihapus.'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh daftar karya
        setState(() {
          _myArtworksFuture = _fetchMyArtworks();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Profil Saya',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white),
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  )
                  .then((_) {
                    setState(() {
                      _userProfileFuture = _fetchUserProfile();
                      _myArtworksFuture = _fetchMyArtworks();
                    });
                  });
            },
          ),
        ],
      ),
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
            child: SingleChildScrollView(
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
                            padding: const EdgeInsets.all(48),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white70,
                              ),
                            ),
                          ),
                        );
                      }

                      if (userSnap.hasError) {
                        return Padding(
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
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      size: 48,
                                      color: Colors.red.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Gagal memuat profil.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      userSnap.error.toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    InkWell(
                                      onTap: () => setState(
                                        () => _userProfileFuture =
                                            _fetchUserProfile(),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Coba Lagi',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
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
                          ),
                        );
                      }

                      final user = userSnap.data ?? <String, dynamic>{};

                      final displayName =
                          (user['name'] as String?) ?? 'Pengguna';
                      final specialization =
                          (user['specialization'] as String?) ?? '';
                      final department = (user['department'] as String?) ?? '';
                      final bio = (user['bio'] as String?) ?? '';
                      final likesReceived =
                          user['likes_received'] ?? user['likes_count'] ?? 0;
                      final socialMedia =
                          user['social_media'] as Map<String, dynamic>?;

                      // Ambil role pengguna untuk conditional rendering
                      final role = (user['role'] as String?) ?? 'viewer';

                      // Gunakan future artworks untuk header (artwork count) dan juga untuk menampilkan galeri jika artist
                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: _myArtworksFuture,
                        builder: (context, artSnap) {
                          final artCount = (artSnap.hasData
                              ? artSnap.data!.length
                              : 0);
                          final artworks = artSnap.data ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Column(
                                children: [
                                  const SizedBox(height: 12),

                                  // Header profil asli tetap digunakan
                                  ArtistProfileHeader(
                                    role: user['role'] ?? 'viewer',
                                    isOwnProfile: _isOwnProfile,
                                    name: displayName,
                                    specialization: [
                                      specialization,
                                      department,
                                    ].where((s) => s.isNotEmpty).join(' • '),
                                    bio: bio,
                                    artworkCount: artCount,
                                    likesReceived: likesReceived,
                                    socialMedia:
                                        socialMedia ?? <String, dynamic>{},
                                    onEditProfile: () {
                                      Navigator.of(context)
                                          .push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const EditProfilePage(),
                                            ),
                                          )
                                          .then((_) {
                                            setState(() {
                                              _userProfileFuture =
                                                  _fetchUserProfile();
                                              _myArtworksFuture =
                                                  _fetchMyArtworks();
                                            });
                                          });
                                    },
                                    artistId: user['id'] ?? '',
                                    onProfileUpdated: () {
                                      setState(() {
                                        _userProfileFuture =
                                            _fetchUserProfile();
                                      });
                                    },
                                    userData: user,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Conditional: artist -> tampilkan Karya Saya
                              if (role == 'artist') ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Text(
                                    'Karya Saya',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Tampilkan konten galeri
                                if (artSnap.connectionState ==
                                    ConnectionState.waiting) ...[
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white70,
                                            ),
                                      ),
                                    ),
                                  ),
                                ] else if (artSnap.hasError) ...[
                                  Padding(
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
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: Colors.red.withOpacity(
                                                0.2,
                                              ),
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
                                                'Gagal memuat karya.',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                artSnap.error.toString(),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 12),
                                              InkWell(
                                                onTap: () => setState(
                                                  () => _myArtworksFuture =
                                                      _fetchMyArtworks(),
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.25),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Coba Lagi',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                ] else if (artworks.isEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.all(48),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withOpacity(
                                              0.1,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.palette_outlined,
                                            size: 64,
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Anda belum mengunggah karya.',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.white.withOpacity(
                                              0.7,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
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
                                        final status = (artwork['status'] ?? '')
                                            .toString();
                                        final imageUrl =
                                            artwork['media_url'] ?? '';

                                        return InkWell(
                                          onTap: () =>
                                              _navigateToDetail(artwork),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                sigmaX: 10,
                                                sigmaY: 10,
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.15),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    // Image with Status and Actions
                                                    Expanded(
                                                      child: Stack(
                                                        children: [
                                                          ClipRRect(
                                                            borderRadius:
                                                                const BorderRadius.only(
                                                                  topLeft:
                                                                      Radius.circular(
                                                                        16,
                                                                      ),
                                                                  topRight:
                                                                      Radius.circular(
                                                                        16,
                                                                      ),
                                                                ),
                                                            child:
                                                                imageUrl
                                                                    .isNotEmpty
                                                                ? CustomNetworkImage(
                                                                    imageUrl: imageUrl,
                                                                    width: double
                                                                        .infinity,
                                                                    height: double
                                                                        .infinity,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                    borderRadius: 16,
                                                                  )
                                                                : Container(
                                                                    color: Colors
                                                                        .white
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
                                                                        size:
                                                                            32,
                                                                      ),
                                                                    ),
                                                                  ),
                                                          ),

                                                          // Status Badge - Glass Chip
                                                          Positioned(
                                                            left: 8,
                                                            top: 8,
                                                            child: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                              child: BackdropFilter(
                                                                filter:
                                                                    ImageFilter.blur(
                                                                      sigmaX: 5,
                                                                      sigmaY: 5,
                                                                    ),
                                                                child: Container(
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            8,
                                                                        vertical:
                                                                            4,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        status ==
                                                                            'approved'
                                                                        ? Colors.green.withOpacity(
                                                                            0.3,
                                                                          )
                                                                        : (status ==
                                                                                  'rejected'
                                                                              ? Colors.red.withOpacity(
                                                                                  0.3,
                                                                                )
                                                                              : Colors.orange.withOpacity(0.3)),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                    border: Border.all(
                                                                      color:
                                                                          status ==
                                                                              'approved'
                                                                          ? Colors.green.withOpacity(
                                                                              0.5,
                                                                            )
                                                                          : (status ==
                                                                                    'rejected'
                                                                                ? Colors.red.withOpacity(
                                                                                    0.5,
                                                                                  )
                                                                                : Colors.orange.withOpacity(0.5)),
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    status ==
                                                                            'approved'
                                                                        ? 'Disetujui'
                                                                        : (status ==
                                                                                  'rejected'
                                                                              ? 'Ditolak'
                                                                              : 'Pending'),
                                                                    style: GoogleFonts.poppins(
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                      fontSize:
                                                                          10,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),

                                                          // Edit & Delete - Glass Circular Buttons
                                                          if (_isOwnProfile)
                                                            Positioned(
                                                              right: 8,
                                                              top: 8,
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          20,
                                                                        ),
                                                                    child: BackdropFilter(
                                                                      filter: ImageFilter.blur(
                                                                        sigmaX:
                                                                            5,
                                                                        sigmaY:
                                                                            5,
                                                                      ),
                                                                      child: InkWell(
                                                                        onTap: () {
                                                                          Navigator.of(
                                                                                context,
                                                                              )
                                                                              .push(
                                                                                MaterialPageRoute(
                                                                                  builder:
                                                                                      (
                                                                                        c,
                                                                                      ) => EditArtworkPage(
                                                                                        artwork: artwork,
                                                                                      ),
                                                                                ),
                                                                              )
                                                                              .then((
                                                                                _,
                                                                              ) {
                                                                                setState(
                                                                                  () {
                                                                                    _myArtworksFuture = _fetchMyArtworks();
                                                                                  },
                                                                                );
                                                                              });
                                                                        },
                                                                        child: Container(
                                                                          padding:
                                                                              const EdgeInsets.all(
                                                                                6,
                                                                              ),
                                                                          decoration: BoxDecoration(
                                                                            color: Colors.white.withOpacity(
                                                                              0.2,
                                                                            ),
                                                                            shape:
                                                                                BoxShape.circle,
                                                                            border: Border.all(
                                                                              color: Colors.white.withOpacity(
                                                                                0.3,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          child: Icon(
                                                                            Icons.edit_rounded,
                                                                            size:
                                                                                14,
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 4,
                                                                  ),
                                                                  ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          20,
                                                                        ),
                                                                    child: BackdropFilter(
                                                                      filter: ImageFilter.blur(
                                                                        sigmaX:
                                                                            5,
                                                                        sigmaY:
                                                                            5,
                                                                      ),
                                                                      child: InkWell(
                                                                        onTap: () => _deleteArtwork(
                                                                          artwork['id'],
                                                                          artwork['media_url'],
                                                                        ),
                                                                        child: Container(
                                                                          padding:
                                                                              const EdgeInsets.all(
                                                                                6,
                                                                              ),
                                                                          decoration: BoxDecoration(
                                                                            color: Colors.red.withOpacity(
                                                                              0.3,
                                                                            ),
                                                                            shape:
                                                                                BoxShape.circle,
                                                                            border: Border.all(
                                                                              color: Colors.red.withOpacity(
                                                                                0.5,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          child: Icon(
                                                                            Icons.delete_rounded,
                                                                            size:
                                                                                14,
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),

                                                    // Title
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            12,
                                                          ),
                                                      child: Text(
                                                        artwork['title'] ?? '',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
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
                                  ),
                                ],
                                const SizedBox(height: 24),
                              ] else ...[
                                // Viewer / non-artist view
                                Padding(
                                  padding: const EdgeInsets.all(48),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.purple.withOpacity(0.2),
                                          border: Border.all(
                                            color: Colors.purple.withOpacity(
                                              0.3,
                                            ),
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.favorite_outline_rounded,
                                          size: 64,
                                          color: Colors.purple.shade300,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Karya yang Disukai',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Fitur ini akan segera hadir.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
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
          ),
        ],
      ),
    );
  }
}
