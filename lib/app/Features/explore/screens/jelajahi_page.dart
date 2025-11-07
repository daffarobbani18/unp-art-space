import 'package:flutter/material.dart';
import '../../../../main/main_app.dart';
import '../../artist/screens/artist_list_page.dart';
import '../../artist/screens/artist_detail_page.dart';
import '../../search/screens/search_results_page.dart';
import 'inspirasi_dunia_page.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_animations.dart';

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

  // Palet warna untuk latar belakang kartu - menggunakan AppTheme
  final List<LinearGradient> _gradients = const [
    AppTheme.secondaryGradient,
    AppTheme.accentGradient,
    LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFF06292)]),
    LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFFFB74D)]),
    AppTheme.primaryGradient,
    LinearGradient(colors: [Color(0xFFF44336), Color(0xFFE57373)]),
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        title: Text(
          'Jelajahi',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Search Bar with Animation ---
            FadeSlideAnimation(
              delay: const Duration(milliseconds: 100),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    boxShadow: AppTheme.shadowMd,
                  ),
                  child: TextFormField(
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Cari karya atau seniman...',
                      hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppTheme.textSecondary,
                        size: 24,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spaceMd,
                        horizontal: AppTheme.spaceMd,
                      ),
                    ),
                    onFieldSubmitted: (value) {
                      _performSearch(value);
                    },
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceLg),
            
            // --- Section Title: Spesialisasi ---
            FadeSlideAnimation(
              delay: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                child: Text(
                  'Jelajahi Berdasarkan Spesialisasi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: 'Playfair Display',
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            
            // Grid Spesialisasi dengan Animasi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppTheme.spaceMd,
                crossAxisSpacing: AppTheme.spaceMd,
                childAspectRatio: 2.5,
                children: List.generate(_specializations.length, (index) {
                  final specialization = _specializations[index];
                  final gradient = _gradients[index % _gradients.length];

                  return ScaleInAnimation(
                    delay: Duration(milliseconds: 300 + (index * 50)),
                    child: BounceAnimation(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              ArtistListPage(specialization: specialization),
                        ));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: AppTheme.shadowMd,
                        ),
                        child: Center(
                          child: Text(
                            specialization,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: AppTheme.spaceLg), 

            // Inspirasi Dunia Card dengan Hero Animation
            FadeSlideAnimation(
              delay: const Duration(milliseconds: 500),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                child: BounceAnimation(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const InspirasiDuniaPage()),
                    );
                  },
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      boxShadow: AppTheme.shadowLg,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            'https://images.unsplash.com/photo-1567095761054-7a02e69e5c43',
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '🌍',
                                  style: const TextStyle(fontSize: 48),
                                ),
                                const SizedBox(height: AppTheme.spaceXs),
                                Text(
                                  'Inspirasi Dunia',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontFamily: 'Playfair Display',
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spaceXs),
                                Text(
                                  'Jelajahi karya seni dari seluruh dunia',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spaceLg),

            // --- Talenta Baru Bergabung ---
            FadeSlideAnimation(
              delay: const Duration(milliseconds: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                child: Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: AppTheme.accentYellow,
                      size: 28,
                    ),
                    const SizedBox(width: AppTheme.spaceXs),
                    Text(
                      'Talenta Baru Bergabung',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'Playfair Display',
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            SizedBox(
              height: 180,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _newTalentsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      ),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spaceMd),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: AppTheme.error,
                            ),
                            const SizedBox(height: AppTheme.spaceXs),
                            Text(
                              'Gagal memuat talenta',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final talents = snap.data ?? [];
                  if (talents.isEmpty) {
                    return Center(
                      child: Text(
                        'Belum ada talenta baru.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: talents.length,
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                    itemBuilder: (context, index) {
                      final talent = talents[index];
                      final name = (talent['name'] ?? 'Pengguna') as String;
                      final spec = (talent['specialization'] ?? '') as String;
                      
                      return ScaleInAnimation(
                        delay: Duration(milliseconds: 700 + (index * 50)),
                        child: BounceAnimation(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) =>
                                    ArtistDetailPage(artistId: talent['id'])));
                          },
                          child: Container(
                            width: 150,
                            margin: const EdgeInsets.only(right: AppTheme.spaceMd),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              boxShadow: AppTheme.shadowMd,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.spaceMd),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppTheme.primaryGradient,
                                    ),
                                    child: CircleAvatar(
                                      radius: 32,
                                      backgroundColor: AppTheme.surface,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spaceSm),
                                  Text(
                                    name,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spaceXs,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                    ),
                                    child: Text(
                                      spec.isNotEmpty ? spec : 'Artist',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        fontSize: 11,
                                        color: AppTheme.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
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
            const SizedBox(height: AppTheme.spaceLg),
          ],
        ),
      ),
    );
  }
}