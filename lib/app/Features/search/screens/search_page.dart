import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../../main/main_app.dart';
import '../../artist/screens/artist_list_page.dart';
import '../../artist/screens/artist_detail_page.dart';
import 'search_results_page.dart';
import '../../explore/screens/inspirasi_dunia_page.dart';

// Glassmorphism-styled SearchPage using SingleChildScrollView
class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // State & Controllers
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _newTalentsFuture;
  bool _isLoading = true;

  final List<String> _specializations = [
    'Pelukis',
    'Fotografer',
    'Ilustrator',
    'Videografer',
    'Desainer Grafis',
    'Musisi',
  ];

  static const List<Color> _bgGradient = [
    Color(0xFF0F2027),
    Color(0xFF203A43),
    Color(0xFF2C5364),
  ];

  @override
  void initState() {
    super.initState();
    _newTalentsFuture = _fetchNewTalents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch New Talents from Supabase
  Future<List<Map<String, dynamic>>> _fetchNewTalents() async {
    try {
      setState(() => _isLoading = true);
      final res = await supabase
          .from('users')
          .select('id, name, specialization, profile_image_url')
          .eq('role', 'artist')
          .order('created_at', ascending: false)
          .limit(8);

      setState(() => _isLoading = false);
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading talents: $e');
      return [];
    }
  }

  // Perform Search Logic
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final searchQuery = '%$query%';

      // Search artists
      final artistResults = await supabase
          .from('users')
          .select()
          .eq('role', 'artist')
          .ilike('name', searchQuery);

      // Search artworks
      final artworkResults = await supabase
          .from('artworks')
          .select('*, users!inner(name)')
          .eq('status', 'approved')
          .ilike('title', searchQuery);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Navigate to results page
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
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error pencarian: ${e.toString()}'),
            backgroundColor: Colors.red.withOpacity(0.8),
          ),
        );
      }
    }
  }

  // Search by Specialization
  void _searchBySpecialization(String specialization) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtistListPage(specialization: specialization),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Layer - Gradient penuh layar
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
          // Content Layer - Scrollable
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar (Glass) with Controller
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.14),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(color: Colors.white),
                                  cursorColor: Colors.white70,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Cari seniman, karya, atau event...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (v) => _performSearch(v),
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Section: Jelajahi Berdasarkan Spesialisasi
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Jelajahi Berdasarkan Spesialisasi',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _specializations.map((spec) {
                        return GestureDetector(
                          onTap: () => _searchBySpecialization(spec),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                ),
                                child: Text(
                                  spec,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.95),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Banner Inspirasi Dunia (Wide Glass Card) with Navigation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InspirasiDuniaPage(),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            Container(
                              height: 140,
                              color: Colors.white.withOpacity(0.04),
                              child: Image.network(
                                'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1400&q=80',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 140,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.white.withOpacity(0.04),
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.white38,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 12,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 8,
                                    sigmaY: 8,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.12),
                                      ),
                                    ),
                                    child: Row(
                                      children: const [
                                        Expanded(
                                          child: Text(
                                            'Inspirasi Dunia',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: Colors.white70,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section: Talenta Baru Bergabung (Horizontal list with real data)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Talenta Baru Bergabung',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ArtistListPage(specialization: ''),
                            ),
                          ),
                          child: Text(
                            'Lihat Semua',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // FutureBuilder for New Talents
                  SizedBox(
                    height: 84,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _newTalentsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white70,
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'Gagal memuat talenta',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ),
                          );
                        }

                        final talents = snapshot.data ?? [];

                        if (talents.isEmpty) {
                          return Center(
                            child: Text(
                              'Belum ada talenta baru',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: talents.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, idx) {
                            final talent = talents[idx];
                            final name =
                                (talent['name'] ?? 'Pengguna') as String;
                            final avatarUrl =
                                talent['profile_image_url'] as String?;

                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ArtistDetailPage(artistId: talent['id']),
                                ),
                              ),
                              child: Column(
                                children: [
                                  ClipOval(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 6,
                                        sigmaY: 6,
                                      ),
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.06),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.12,
                                            ),
                                          ),
                                        ),
                                        child:
                                            (avatarUrl != null &&
                                                avatarUrl.isNotEmpty)
                                            ? ClipOval(
                                                child: Image.network(
                                                  avatarUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Center(
                                                        child: Text(
                                                          name.isNotEmpty
                                                              ? name[0]
                                                                    .toUpperCase()
                                                              : 'U',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                ),
                                              )
                                            : Center(
                                                child: Text(
                                                  name.isNotEmpty
                                                      ? name[0].toUpperCase()
                                                      : 'U',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: 72,
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
