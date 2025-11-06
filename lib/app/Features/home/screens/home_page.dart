import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../main/main_app.dart'; // access supabase client
import '../../../core/navigation/auth_gate.dart';
import '../../artwork/screens/upload_artwork_page.dart';
import '../../artwork/screens/artwork_detail_page.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  // Dummy data for events
  final List<Map<String, String>> _events = [
    {
      'title': 'Pameran Tugas Akhir DKV',
      'date': '12 - 15 Juli 2024',
      'image': 'https://images.unsplash.com/photo-1504198453319-5ce911bafcde?auto=format&fit=crop&w=800&q=60',
    },
    {
      'title': 'Festival Seni Rupa',
      'date': '20 Juli 2024',
      'image': 'https://images.unsplash.com/photo-1529101091764-c3526daf38fe?auto=format&fit=crop&w=800&q=60',
    },
    {
      'title': 'Workshop Ilustrasi',
      'date': '25 Juli 2024',
      'image': 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=800&q=60',
    },
  ];

  // Kategori yang digunakan di halaman Home
  List<String> _categories = [
    'Semua',
    'Lukisan',
    'Fotografi',
    'Patung',
    'Digital Art',
    'Kerajinan',
    'Musik',
    'Film',
    'Lainnya'
  ];

  String _selectedCategory = 'Semua';
  late Future<List<Map<String, dynamic>>> _artworksFuture;
  String? _currentUserRole;

  void _openUploadPage() async {
    // Only artists can upload
    if (_currentUserRole != 'artist') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hanya akun Artist yang dapat mengunggah karya.')),
        );
      }
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadArtworkPage()),
    );
    setState(() {
      _artworksFuture = _loadArtworks();
    });
  }

  @override
  void initState() {
    super.initState();
    _artworksFuture = _loadArtworks();
    _loadCurrentUserRole();
  }

  Future<void> _loadCurrentUserRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _currentUserRole = null);
      return;
    }

    try {
      final result = await supabase.from('users').select('role').eq('id', user.id).maybeSingle();
      if (mounted) {
        setState(() {
          _currentUserRole = result != null ? (result['role'] as String?) : null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _currentUserRole = null);
    }
  }

  Future<List<Map<String, dynamic>>> _loadArtworks() async {
    var query = supabase.from('artworks').select();

    if (_selectedCategory != 'Semua') {
      query = query.eq('category', _selectedCategory);
    }

    final data = await query.eq('status', 'approved').order('created_at', ascending: false) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
  _artworksFuture = _loadArtworks();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'UNP Art Space',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'Logout',
            onPressed: () async {
              try {
                await supabase.auth.signOut();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout gagal: $e')),
                  );
                }
                return;
              }

              if (!mounted) return;
              setState(() {
                _selectedCategory = 'Semua';
                _artworksFuture = Future.value(<Map<String, dynamic>>[]);
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              });
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Event Seni Mendatang',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: GoogleFonts.playfairDisplay().fontFamily,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _events.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, idx) {
                final event = _events[idx];
                return SizedBox(
                  width: 300,
                  child: Card(
                    color: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                    child: Stack(
                      children: [
                        // Background image from Unsplash (dummy)
                        Container(
                          height: double.infinity,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            image: DecorationImage(
                              image: NetworkImage(event['image'] ?? ''),
                              fit: BoxFit.cover,
                            ),
                          ),
                          // subtle gradient overlay to ensure text contrast
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black26],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          bottom: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event['title'] ?? '',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                event['date'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Bagian 2: Filter Kategori (ChoiceChips horizontal)
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: _selectedCategory == cat,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                          _artworksFuture = _loadArtworks();
                        });
                      }
                    },
                    selectedColor: Colors.deepPurple[700],
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: _selectedCategory == cat ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Bagian 3: Galeri Karya Utama (Pinterest-like Masonry)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _artworksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Gagal memuat karya: ${snapshot.error}'));
                }
                final artworks = snapshot.data ?? [];
                if (artworks.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('Belum ada karya yang disetujui.')),
                  );
                }

                return MasonryGridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemCount: artworks.length,
                  itemBuilder: (context, idx) {
                    final artwork = artworks[idx];
                    // Prefer thumbnail_url for videos, fall back to media_url, then legacy image_url
                    final imageUrl = ((artwork['thumbnail_url'] ?? artwork['media_url'] ?? artwork['image_url']) ?? '') as String;
                    final title = (artwork['title'] ?? '') as String;
                    final artist = (artwork['artist_name'] ?? '') as String;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArtworkDetailPage(artwork: artwork),
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image (network with placeholder)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: imageUrl.isNotEmpty
                                  ? Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          // let the image dictate height so staggered looks dynamic
                                          loadingBuilder: (context, child, progress) {
                                            if (progress == null) return child;
                                            return Container(
                                              height: 140,
                                              color: Colors.grey[300],
                                              child: const Center(child: CircularProgressIndicator()),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            height: 140,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                          ),
                                        ),
                                        if ((artwork['artwork_type'] ?? '') == 'video')
                                          Container(
                                            color: Colors.black26,
                                          ),
                                        if ((artwork['artwork_type'] ?? '') == 'video')
                                          const Center(
                                            child: Icon(
                                              Icons.play_circle_fill,
                                              size: 56,
                                              color: Colors.white70,
                                            ),
                                          ),
                                      ],
                                    )
                                  : Container(height: 160, color: Colors.grey[300]),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    artist,
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      floatingActionButton: _currentUserRole == 'artist'
          ? FloatingActionButton.extended(
              onPressed: _openUploadPage,
              backgroundColor: Colors.black,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Unggah Karya',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
      
    );
  }
}
