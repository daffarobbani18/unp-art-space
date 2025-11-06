import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../main/main_app.dart';
import '../../artist/screens/artist_list_page.dart';
import '../../artist/screens/artist_detail_page.dart';
import '../../search/screens/search_results_page.dart';
import 'inspirasi_dunia_page.dart';

class JelajahiPage extends StatefulWidget {
  const JelajahiPage({super.key});

  @override
  State<JelajahiPage> createState() => _JelajahiPageState();
  
}

class _JelajahiPageState extends State<JelajahiPage> {
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // %query% berarti "mengandung query", case-insensitive (ilike)
      final searchQuery = '%$query%';

      // Cari di tabel 'users' untuk seniman
      final artistResults = await supabase
          .from('users')
          .select()
          .eq('role', 'artist')
          .ilike('name', searchQuery);

      // Cari di tabel 'artworks' untuk karya
      final artworkResults = await supabase
          .from('artworks')
          .select('*, users!inner(name)')
          .eq('status', 'approved')
          .ilike('title', searchQuery);

      // Hentikan loading
      if (mounted) Navigator.of(context).pop();

      // Buka halaman hasil
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SearchResultsPage(
              query: query,
              artistResults: List<Map<String, dynamic>>.from(artistResults),
              artworkResults: List<Map<String, dynamic>>.from(artworkResults),
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Hentikan loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error pencarian: ${e.toString()}')),
        );
      }
    }
  }

  // Daftar spesialisasi untuk UI
  final List<String> _specializations = const [
    'Pelukis',
    'Fotografer',
    'Ilustrator',
    'Videografer',
    'Desainer Grafis',
    'Musisi'
  ];

  // Future untuk mengambil data talenta baru dari Supabase
  late Future<List<Map<String, dynamic>>> _newTalentsFuture;

  // Palet warna untuk latar belakang kartu
  final List<Color> _palette = const [
    Color(0xFF7C4DFF), // ungu
    Color(0xFF4CAF50), // hijau
    Color(0xFFE91E63), // pink
    Color(0xFFFF9800), // oranye
    Color(0xFF03A9F4), // biru muda
    Color(0xFFF44336), // merah
  ];

  @override
  void initState() {
    super.initState();
    _newTalentsFuture = _loadNewTalents();
  }

  Future<List<Map<String, dynamic>>> _loadNewTalents() async {
    // Mengambil data seniman terbaru dari tabel 'users'
    final res = await supabase
        .from('users')
        .select('id,name,specialization')
        .eq('role', 'artist')
        .order('created_at', ascending: false)
        .limit(10);
    return (res as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Jelajahi',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Search Bar ---
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: 'Cari karya atau seniman...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                ),
                onFieldSubmitted: (value) {
                  // Panggil fungsi pencarian saat user menekan 'Enter' di keyboard
                  _performSearch(value);
                },
              ),
            ),
            
            // --- Jelajahi Berdasarkan Spesialisasi ---
            const Text('Jelajahi Berdasarkan Spesialisasi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: List.generate(_specializations.length, (index) {
                final specialization = _specializations[index];
                final color = _palette[index % _palette.length];

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          ArtistListPage(specialization: specialization),
                    ));
                  },
                  child: Card(
                    color: color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: Text(
                        specialization,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24), 

            InkWell(
              onTap: () {
                // Navigasi ke halaman Inspirasi Dunia
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const InspirasiDuniaPage()),
                );
              },
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(
                      'https://images.unsplash.com/photo-1567095761054-7a02e69e5c43', // Gambar placeholder artistik
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    Text(
                      'Inspirasi Dunia 🌍',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24,),

            // --- Talenta Baru Bergabung ---
            const Text('Talenta Baru Bergabung',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _newTalentsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                        child: Text('Gagal memuat talenta: ${snap.error}'));
                  }
                  final talents = snap.data ?? [];
                  if (talents.isEmpty) {
                    return const Center(child: Text('Belum ada talenta baru.'));
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: talents.length,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemBuilder: (context, index) {
                      final talent = talents[index];
                      final name = (talent['name'] ?? 'Pengguna') as String;
                      final spec = (talent['specialization'] ?? '') as String;
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) =>
                                  ArtistDetailPage(artistId: talent['id'])));
                        },
                        child: SizedBox(
                          width: 140,
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0, vertical: 10.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                      radius: 36,
                                      child: Text(name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'U')),
                                  const SizedBox(height: 8),
                                  Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(spec,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}