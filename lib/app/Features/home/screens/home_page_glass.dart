import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../main/main_app.dart';
import '../../artwork/screens/upload_artwork_page.dart';
import '../../events/upload_event_screen.dart';
import '../../artwork/screens/artwork_detail_page.dart';
import '../../events/event_detail_screen.dart';

class HomePageGlass extends StatefulWidget {
  const HomePageGlass({Key? key}) : super(key: key);

  @override
  State<HomePageGlass> createState() => _HomePageGlassState();
}

class _HomePageGlassState extends State<HomePageGlass> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoadingEvents = true;

  List<String> _categories = [
    'All',
    'Painting',
    'Digital',
    '3D',
    'Photography',
    'Sculpture',
    'Mixed Media',
  ];

  String _selectedCategory = 'All';
  late Future<List<Map<String, dynamic>>> _artworksFuture;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _artworksFuture = _loadArtworks();
    _loadCurrentUserRole();
  }

  Future<void> _loadEvents() async {
    try {
      final response = await supabase
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
    if (user != null) {
      try {
        final response = await supabase
            .from('users')
            .select('role')
            .eq('id', user.id)
            .single();
        if (mounted) {
          setState(() {
            _currentUserRole = response['role'] as String?;
          });
        }
      } catch (e) {
        print('Error loading user role: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadArtworks() async {
    var query = supabase.from('artworks').select();

    if (_selectedCategory != 'All') {
      query = query.eq('category', _selectedCategory);
    }

    final data = await query
        .eq('status', 'approved')
        .order('created_at', ascending: false) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _openUploadPage() async {
    if (_currentUserRole != 'artist') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hanya artist yang dapat mengunggah karya'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2027).withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Pilih Jenis Unggahan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildUploadOption(
                    icon: Icons.palette_rounded,
                    title: 'Unggah Karya Seni',
                    subtitle: 'Bagikan karya seni Anda',
                    onTap: () => Navigator.pop(context, 'artwork'),
                  ),
                  const SizedBox(height: 16),
                  _buildUploadOption(
                    icon: Icons.event_rounded,
                    title: 'Buat Event Seni',
                    subtitle: 'Adakan pameran atau workshop',
                    onTap: () => Navigator.pop(context, 'event'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == 'artwork' && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UploadArtworkPage()),
      );
    } else if (result == 'event' && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UploadEventScreen()),
      );
    }
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.5),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // Gradient Background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // SECTION 1: Glassmorphism Floating Header
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Art Gallery',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Row(
                                children: [
                                  _buildGlassIconButton(
                                    icon: Icons.search_rounded,
                                    onPressed: () {},
                                  ),
                                  const SizedBox(width: 8),
                                  _buildGlassIconButton(
                                    icon: Icons.notifications_outlined,
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // SECTION 2: Event Seni Mendatang
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  
                  // Section Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.event_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Event Seni Mendatang',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Event Carousel
                  if (_isLoadingEvents)
                    SizedBox(
                      height: 220,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ),
                  if (!_isLoadingEvents && _events.isNotEmpty)
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _events.length,
                        itemBuilder: (context, idx) {
                          final event = _events[idx];
                          final imageUrl = event['image_url'] ?? '';
                          final title = event['title'] ?? 'Event';
                          final location = event['location'] ?? '';
                          final eventDate = event['event_date'];
                          
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EventDetailScreen(event: event),
                                ),
                              );
                            },
                            child: Container(
                              width: 320,
                              margin: const EdgeInsets.only(right: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  children: [
                                    // Background Image
                                    Positioned.fill(
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: Colors.white.withOpacity(0.05),
                                                child: const Icon(
                                                  Icons.event_rounded,
                                                  size: 60,
                                                  color: Colors.white38,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: Colors.white.withOpacity(0.05),
                                              child: const Icon(
                                                Icons.event_rounded,
                                                size: 60,
                                                color: Colors.white38,
                                              ),
                                            ),
                                    ),
                                    // Glass Overlay at Bottom
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(24),
                                          bottomRight: Radius.circular(24),
                                        ),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.7),
                                                ],
                                              ),
                                              border: const Border(
                                                top: BorderSide(
                                                  color: Colors.white12,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                if (eventDate != null)
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.calendar_today,
                                                        size: 14,
                                                        color: Colors.white70,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        _formatDate(eventDate),
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                if (location.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.location_on,
                                                        size: 14,
                                                        color: Colors.white70,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          location,
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.white70,
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
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // SECTION 3: Glass Filter Chips (Fixed Height)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  itemBuilder: (context, idx) {
                    final cat = _categories[idx];
                    final isSelected = _selectedCategory == cat;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat;
                            _artworksFuture = _loadArtworks();
                          });
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.5)
                                      : Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // SECTION 4: Pinterest Style Gallery (SliverMasonryGrid)
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _artworksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  );
                }

                final artworks = snapshot.data ?? [];
                if (artworks.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.art_track_outlined,
                              size: 64,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum Ada Karya',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Masonry Grid
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childCount: artworks.length,
                    itemBuilder: (context, idx) {
                      final artwork = artworks[idx];
                      final imageUrl = ((artwork['thumbnail_url'] ?? 
                                        artwork['media_url'] ?? 
                                        artwork['image_url']) ?? '') as String;
                      final title = (artwork['title'] ?? '') as String;
                      final artist = (artwork['artist_name'] ?? '') as String;
                      
                      // Dynamic height untuk masonry effect
                      final heights = [200.0, 250.0, 180.0, 280.0, 220.0];
                      final height = heights[idx % heights.length];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ArtworkDetailPage(artwork: artwork),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: height,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Artwork Image
                                if (imageUrl.isNotEmpty)
                                  Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.white.withOpacity(0.05),
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                        size: 50,
                                        color: Colors.white38,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    color: Colors.white.withOpacity(0.05),
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 50,
                                      color: Colors.white38,
                                    ),
                                  ),
                                
                                // Glass Overlay at Bottom
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(20),
                                      bottomRight: Radius.circular(20),
                                    ),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.8),
                                            ],
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (title.isNotEmpty)
                                              Text(
                                                title,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            if (artist.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'by $artist',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white.withOpacity(0.7),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
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
                      );
                    },
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: _currentUserRole == 'artist'
          ? ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: _openUploadPage,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text(
                      'Upload',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
