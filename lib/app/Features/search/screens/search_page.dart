import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_animations.dart';
import '../../../../main/main_app.dart';
import '../../artwork/screens/artwork_detail_page.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _trendingArtworks = [];
  bool _isSearching = false;
  bool _isLoading = true;
  String _selectedFilter = 'Semua';

  final List<String> _filters = [
    'Semua',
    'Lukisan',
    'Fotografi',
    'Patung',
    'Digital Art',
    'Kerajinan',
    'Musik',
    'Film',
  ];

  @override
  void initState() {
    super.initState();
    _loadTrendingArtworks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingArtworks() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await supabase
          .from('artworks')
          .select()
          .eq('status', 'approved')
          .order('created_at', ascending: false)
          .limit(20) as List<dynamic>;
      
      if (mounted) {
        setState(() {
          _trendingArtworks = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading trending: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      var queryBuilder = supabase
          .from('artworks')
          .select()
          .eq('status', 'approved')
          .or('title.ilike.%$query%,description.ilike.%$query%,artist_name.ilike.%$query%');

      if (_selectedFilter != 'Semua') {
        queryBuilder = queryBuilder.eq('category', _selectedFilter);
      }

      final data = await queryBuilder.order('created_at', ascending: false) as List<dynamic>;

      if (mounted) {
        setState(() {
          _searchResults = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      print('Error searching: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencari: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Widget _buildArtworkGrid(List<Map<String, dynamic>> artworks) {
    return MasonryGridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppTheme.spaceMd,
      crossAxisSpacing: AppTheme.spaceMd,
      itemCount: artworks.length,
      itemBuilder: (context, idx) {
        final artwork = artworks[idx];
        final imageUrl = ((artwork['thumbnail_url'] ?? artwork['media_url'] ?? artwork['image_url']) ?? '') as String;
        final title = (artwork['title'] ?? '') as String;
        final artist = (artwork['artist_name'] ?? '') as String;
        final isVideo = (artwork['artwork_type'] ?? '') == 'video';

        return RevealAnimation(
          delay: Duration(milliseconds: idx * 50),
          child: BounceAnimation(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArtworkDetailPage(artwork: artwork),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.shadowMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image/Thumbnail
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusLg),
                    ),
                    child: Stack(
                      children: [
                        if (imageUrl.isNotEmpty)
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                height: 160,
                                color: AppTheme.textTertiary.withOpacity(0.1),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                        : null,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.secondary,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 160,
                              color: AppTheme.textTertiary.withOpacity(0.1),
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 180,
                            color: AppTheme.textTertiary.withOpacity(0.1),
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        // Video indicator
                        if (isVideo)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Info
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceSm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontFamily: 'Playfair Display',
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          artist,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Search Bar
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                boxShadow: AppTheme.shadowSm,
              ),
              child: Column(
                children: [
                  // Search Bar
                  FadeSlideAnimation(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        border: Border.all(
                          color: AppTheme.secondary.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          if (value.trim().isEmpty) {
                            setState(() {
                              _searchResults = [];
                            });
                          }
                        },
                        onSubmitted: _performSearch,
                        decoration: InputDecoration(
                          hintText: 'Cari karya seni, artis...',
                          hintStyle: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppTheme.secondary,
                            size: 24,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: AppTheme.textSecondary,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spaceMd,
                            vertical: AppTheme.spaceSm,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  // Filter Chips
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = _selectedFilter == filter;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: AppTheme.spaceXs),
                          child: BounceAnimation(
                            onTap: () {
                              setState(() {
                                _selectedFilter = filter;
                              });
                              if (_searchController.text.isNotEmpty) {
                                _performSearch(_searchController.text);
                              }
                            },
                            child: AnimatedContainer(
                              duration: AppTheme.animationFast,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spaceMd,
                                vertical: AppTheme.spaceXs,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [AppTheme.secondary, AppTheme.secondaryLight],
                                      )
                                    : null,
                                color: isSelected ? null : AppTheme.background,
                                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : AppTheme.secondary.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isSearching
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                      ),
                    )
                  : _searchController.text.isNotEmpty && _searchResults.isEmpty
                      ? Center(
                          child: FadeInAnimation(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.spaceLg),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.secondary.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.search_off_rounded,
                                    size: 64,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spaceMd),
                                Text(
                                  'Tidak Ada Hasil',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontFamily: 'Playfair Display',
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spaceXs),
                                Text(
                                  'Coba kata kunci lain',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(AppTheme.spaceMd),
                          children: [
                            if (_searchResults.isEmpty) ...[
                              // Trending Section
                              FadeSlideAnimation(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.trending_up_rounded,
                                      color: AppTheme.secondary,
                                      size: 28,
                                    ),
                                    const SizedBox(width: AppTheme.spaceXs),
                                    Text(
                                      'Karya Trending',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontFamily: 'Playfair Display',
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceMd),
                              _isLoading
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(AppTheme.spaceLg),
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                                        ),
                                      ),
                                    )
                                  : _trendingArtworks.isEmpty
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.all(AppTheme.spaceLg),
                                            child: Text(
                                              'Belum ada karya',
                                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                        )
                                      : _buildArtworkGrid(_trendingArtworks),
                            ] else ...[
                              // Search Results
                              FadeSlideAnimation(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.search_rounded,
                                      color: AppTheme.secondary,
                                      size: 28,
                                    ),
                                    const SizedBox(width: AppTheme.spaceXs),
                                    Text(
                                      'Hasil Pencarian (${_searchResults.length})',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontFamily: 'Playfair Display',
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceMd),
                              _buildArtworkGrid(_searchResults),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
