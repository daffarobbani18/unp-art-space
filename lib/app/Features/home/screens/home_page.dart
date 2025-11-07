import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../main/main_app.dart'; // access supabase client
import '../../../core/navigation/auth_gate.dart';
import '../../artwork/screens/upload_artwork_page.dart';
import '../../events/upload_event_screen.dart';
import '../../events/event_detail_screen.dart';
import '../../artwork/screens/artwork_detail_page.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  // Real events from database
  List<Map<String, dynamic>> _events = [];
  bool _isLoadingEvents = true;

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

    // Show dialog to choose between artwork or event
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Pilih Jenis Upload',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9333EA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.palette, color: Color(0xFF9333EA)),
                ),
                title: Text(
                  'Unggah Karya',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Upload artwork/karya seni Anda',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
                onTap: () => Navigator.pop(context, 'artwork'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.event, color: Color(0xFF1E3A8A)),
                ),
                title: Text(
                  'Ajukan Event',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Ajukan event atau pameran seni',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
                onTap: () => Navigator.pop(context, 'event'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

    if (choice == 'artwork') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UploadArtworkPage()),
      );
      setState(() {
        _artworksFuture = _loadArtworks();
      });
    } else if (choice == 'event') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UploadEventScreen()),
      );
      // Event doesn't affect artworks, but you might want to refresh something else
    }
  }

  @override
  void initState() {
    super.initState();
    _artworksFuture = _loadArtworks();
    _loadCurrentUserRole();
    _loadApprovedEvents();
  }

  Future<void> _loadApprovedEvents() async {
    try {
      final response = await Supabase.instance.client
          .from('events')
          .select('*')
          .eq('status', 'approved')
          .order('event_date', ascending: true)
          .limit(5);

      if (mounted) {
        setState(() {
          _events = List<Map<String, dynamic>>.from(response as List);
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      print('Error loading events: $e');
      if (mounted) {
        setState(() => _isLoadingEvents = false);
      }
    }
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

  String _formatEventDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = date.difference(now).inDays;

      if (difference == 0) {
        return 'Hari ini';
      } else if (difference == 1) {
        return 'Besok';
      } else if (difference < 7 && difference > 0) {
        return '$difference hari lagi';
      } else {
        // Format: "12 November 2024"
        return '${date.day} ${_getMonthName(date.month)} ${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month];
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
              itemCount: _isLoadingEvents ? 3 : _events.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, idx) {
                if (_isLoadingEvents) {
                  // Loading skeleton
                  return SizedBox(
                    width: 300,
                    child: Card(
                      color: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }

                if (_events.isEmpty) {
                  return SizedBox(
                    width: 300,
                    child: Card(
                      color: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada event',
                              style: GoogleFonts.poppins(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final event = _events[idx];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailScreen(event: event),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'event_${event['id']}',
                    child: SizedBox(
                      width: 300,
                      child: Card(
                        color: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                        child: Stack(
                          children: [
                            // Background image from database
                            Container(
                              height: double.infinity,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                image: DecorationImage(
                                  image: NetworkImage(event['image_url'] ?? ''),
                                  fit: BoxFit.cover,
                                  onError: (_, __) {},
                                ),
                              ),
                              // gradient overlay
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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
                                    event['title'] ?? 'Event',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (event['event_date'] != null)
                                    Text(
                                      _formatEventDate(event['event_date']),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  if (event['location'] != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 14, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            event['location'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
