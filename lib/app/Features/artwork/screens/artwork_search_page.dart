import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'artwork_detail_page.dart';
import '../../profile/screens/enhanced_artist_profile_page.dart';
import '../../../shared/widgets/custom_network_image.dart';

class ArtworkSearchPage extends StatefulWidget {
  const ArtworkSearchPage({Key? key}) : super(key: key);

  @override
  State<ArtworkSearchPage> createState() => _ArtworkSearchPageState();
}

class _ArtworkSearchPageState extends State<ArtworkSearchPage> {
  final supabase = Supabase.instance.client;
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _artworks = [];
  List<Map<String, dynamic>> _filteredArtworks = [];
  bool _isLoading = false;
  
  String _selectedCategory = 'All';
  String _selectedType = 'All';
  String _sortBy = 'newest'; // newest, oldest, most_liked, title_az, title_za
  
  final List<String> _categories = [
    'All',
    'Lukisan',
    'Patung',
    'Fotografi',
    'Digital Art',
    'Instalasi',
    'Mixed Media',
    'Lainnya',
  ];

  final List<String> _types = [
    'All',
    'image',
    'video',
  ];

  @override
  void initState() {
    super.initState();
    _loadArtworks();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> _loadArtworks() async {
    setState(() => _isLoading = true);

    try {
      final response = await supabase
          .from('artworks')
          .select('id, title, description, media_url, thumbnail_url, category, artwork_type, likes_count, artist_name, artist_id, created_at')
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      setState(() {
        _artworks = List<Map<String, dynamic>>.from(response);
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading artworks: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_artworks);

    // Search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((artwork) {
        final title = (artwork['title'] ?? '').toString().toLowerCase();
        final artist = (artwork['artist_name'] ?? '').toString().toLowerCase();
        final description = (artwork['description'] ?? '').toString().toLowerCase();
        return title.contains(query) || 
               artist.contains(query) || 
               description.contains(query);
      }).toList();
    }

    // Category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((artwork) => 
        artwork['category'] == _selectedCategory
      ).toList();
    }

    // Type filter
    if (_selectedType != 'All') {
      filtered = filtered.where((artwork) => 
        artwork['artwork_type'] == _selectedType
      ).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'newest':
        filtered.sort((a, b) => 
          (b['created_at'] ?? '').compareTo(a['created_at'] ?? '')
        );
        break;
      case 'oldest':
        filtered.sort((a, b) => 
          (a['created_at'] ?? '').compareTo(b['created_at'] ?? '')
        );
        break;
      case 'most_liked':
        filtered.sort((a, b) => 
          ((b['likes_count'] as int?) ?? 0).compareTo((a['likes_count'] as int?) ?? 0)
        );
        break;
      case 'title_az':
        filtered.sort((a, b) => 
          (a['title'] ?? '').toString().toLowerCase().compareTo((b['title'] ?? '').toString().toLowerCase())
        );
        break;
      case 'title_za':
        filtered.sort((a, b) => 
          (b['title'] ?? '').toString().toLowerCase().compareTo((a['title'] ?? '').toString().toLowerCase())
        );
        break;
    }

    setState(() {
      _filteredArtworks = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Search Artworks',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(20),
                child: _buildSearchBar(),
              ),

              // Active Filters
              if (_selectedCategory != 'All' || _selectedType != 'All')
                _buildActiveFilters(),

              // Results Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_filteredArtworks.length} artwork${_filteredArtworks.length != 1 ? 's' : ''} found',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    _buildSortButton(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Results Grid
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B5CF6),
                        ),
                      )
                    : _filteredArtworks.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadArtworks,
                            color: const Color(0xFF8B5CF6),
                            child: GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _filteredArtworks.length,
                              itemBuilder: (context, index) {
                                final artwork = _filteredArtworks[index];
                                return _buildArtworkCard(artwork);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by title, artist, or description...',
              hintStyle: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF8B5CF6),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_selectedCategory != 'All')
            _buildFilterChip(
              'Category: $_selectedCategory',
              () => setState(() {
                _selectedCategory = 'All';
                _applyFilters();
              }),
            ),
          if (_selectedType != 'All')
            _buildFilterChip(
              'Type: $_selectedType',
              () => setState(() {
                _selectedType = 'All';
                _applyFilters();
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.3),
      deleteIcon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
      onDeleted: onRemove,
      side: BorderSide.none,
    );
  }

  Widget _buildSortButton() {
    String sortLabel;
    switch (_sortBy) {
      case 'newest':
        sortLabel = 'Newest';
        break;
      case 'oldest':
        sortLabel = 'Oldest';
        break;
      case 'most_liked':
        sortLabel = 'Most Liked';
        break;
      case 'title_az':
        sortLabel = 'Title A-Z';
        break;
      case 'title_za':
        sortLabel = 'Title Z-A';
        break;
      default:
        sortLabel = 'Sort';
    }

    return PopupMenuButton<String>(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sortLabel,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF8B5CF6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.sort_rounded,
            color: Color(0xFF8B5CF6),
            size: 20,
          ),
        ],
      ),
      onSelected: (value) {
        setState(() {
          _sortBy = value;
          _applyFilters();
        });
      },
      itemBuilder: (context) => [
        _buildSortMenuItem('Newest', 'newest'),
        _buildSortMenuItem('Oldest', 'oldest'),
        _buildSortMenuItem('Most Liked', 'most_liked'),
        _buildSortMenuItem('Title A-Z', 'title_az'),
        _buildSortMenuItem('Title Z-A', 'title_za'),
      ],
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(String label, String value) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          if (_sortBy == value)
            const Icon(Icons.check_rounded, size: 20, color: Color(0xFF8B5CF6))
          else
            const SizedBox(width: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkCard(Map<String, dynamic> artwork) {
    final imageUrl = artwork['thumbnail_url'] ?? artwork['media_url'];
    final isVideo = artwork['artwork_type'] == 'video';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArtworkDetailPage.fromId(
              artworkId: artwork['id'],
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: imageUrl != null
                            ? CustomNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.white.withOpacity(0.05),
                                child: const Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: Colors.white24,
                                ),
                              ),
                      ),
                      if (isVideo)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artwork['title'] ?? 'Untitled',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          final artistId = artwork['artist_id'] as String?;
                          if (artistId != null && artistId.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EnhancedArtistProfilePage(
                                  artistId: artistId,
                                ),
                              ),
                            );
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_rounded,
                              size: 12,
                              color: Colors.white60,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                artwork['artist_name'] ?? 'Unknown Artist',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            size: 14,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (artwork['likes_count'] ?? 0).toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No artworks found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e).withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Artworks',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCategory = 'All';
                            _selectedType = 'All';
                          });
                        },
                        child: Text(
                          'Reset',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Category Filter
                  Text(
                    'Category',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            _selectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF8B5CF6)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF8B5CF6)
                                  : Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Type Filter
                  Text(
                    'Type',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _types.map((type) {
                      final isSelected = _selectedType == type;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            _selectedType = type;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF8B5CF6)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF8B5CF6)
                                  : Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            type == 'All' ? 'All' : type.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = _selectedCategory;
                          _selectedType = _selectedType;
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Apply Filters',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
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
}
