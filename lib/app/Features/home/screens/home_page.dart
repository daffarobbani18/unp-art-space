import 'package:flutter/material.dart';
import '../../../../main/main_app.dart'; // access supabase client
import '../../../core/navigation/auth_gate.dart';
import '../../artwork/screens/upload_artwork_page.dart';
import '../../events/upload_event_screen.dart';
import '../../artwork/screens/artwork_detail_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_animations.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

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
      isScrollControlled: true,
      builder: (context) => SlideInAnimation(
        begin: const Offset(0, 0.3),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
            boxShadow: AppTheme.shadowXl,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppTheme.spaceSm),
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textTertiary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLg),
                // Title
                FadeInAnimation(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    'Pilih Jenis Upload',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'Playfair Display',
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLg),
                // Upload Artwork Option
                FadeSlideAnimation(
                  delay: const Duration(milliseconds: 200),
                  child: BounceAnimation(
                    onTap: () => Navigator.pop(context, 'artwork'),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                      padding: const EdgeInsets.all(AppTheme.spaceMd),
                      decoration: BoxDecoration(
                        gradient: AppTheme.secondaryGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: AppTheme.shadowMd,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spaceMd),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: const Icon(
                              Icons.palette_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unggah Karya',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Upload artwork/karya seni Anda',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMd),
                // Upload Event Option
                FadeSlideAnimation(
                  delay: const Duration(milliseconds: 300),
                  child: BounceAnimation(
                    onTap: () => Navigator.pop(context, 'event'),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                      padding: const EdgeInsets.all(AppTheme.spaceMd),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: AppTheme.shadowMd,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spaceMd),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: const Icon(
                              Icons.event_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ajukan Event',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ajukan event atau pameran seni',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLg),
              ],
            ),
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
      print('Error loading events: \$e');
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
  _artworksFuture = _loadArtworks();
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Simple App Bar
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Explore',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  fontSize: 28,
                  letterSpacing: 0.5,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_outlined, size: 20),
                  ),
                  color: Colors.black87,
                  onPressed: () {},
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none_outlined, size: 20),
                  ),
                  color: Colors.black87,
                  onPressed: () {},
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                
                // Simple Event Section
                if (_isLoadingEvents)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      height: 180,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                        ),
                      ),
                    ),
                  ),
                if (!_isLoadingEvents && _events.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Event Seni Mendatang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Lihat Semua',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
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
                        
                        return Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Event Image
                                Container(
                                  height: 100,
                                  width: double.infinity,
                                  color: Colors.grey[100],
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.image_outlined,
                                            size: 40,
                                            color: Colors.grey[400],
                                          ),
                                        )
                                      : Icon(
                                          Icons.event_outlined,
                                          size: 40,
                                          color: Colors.grey[400],
                                        ),
                                ),
                                // Event Info
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      if (eventDate != null)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 12,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDate(eventDate),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (location.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 12,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                location,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
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
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Simple Category Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, idx) {
                        final cat = _categories[idx];
                        final isSelected = _selectedCategory == cat;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat;
                                _artworksFuture = _loadArtworks();
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.black : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
                ),
                const SizedBox(height: 24),

          // Galeri Karya
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _artworksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                          ),
                          const SizedBox(height: AppTheme.spaceMd),
                          Text(
                            'Memuat karya seni...',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceLg),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: AppTheme.error,
                          ),
                          const SizedBox(height: AppTheme.spaceMd),
                          Text(
                            'Gagal memuat karya',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceXs),
                          Text(
                            '${snapshot.error}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                final artworks = snapshot.data ?? [];
                if (artworks.isEmpty) {
                  return FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceLg * 2),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spaceLg),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primary.withOpacity(0.1),
                              ),
                              child: Icon(
                                Icons.art_track_outlined,
                                size: 64,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            Text(
                              'Belum Ada Karya',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontFamily: 'Playfair Display',
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceXs),
                            Text(
                              'Belum ada karya yang disetujui dalam kategori ini',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Simple card layout
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: artworks.length,
                  itemBuilder: (context, idx) {
                    final artwork = artworks[idx];
                    final imageUrl = ((artwork['thumbnail_url'] ?? artwork['media_url'] ?? artwork['image_url']) ?? '') as String;
                    final title = (artwork['title'] ?? '') as String;
                    final artist = (artwork['artist_name'] ?? '') as String;
                    final category = (artwork['category'] ?? '') as String;
                    final isVideo = (artwork['artwork_type'] ?? '') == 'video';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with artist info
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.grey[200],
                                  child: Text(
                                    artist.isNotEmpty ? artist[0].toUpperCase() : 'A',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        artist,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (category.isNotEmpty)
                                        Text(
                                          category,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.more_horiz,
                                    color: Colors.grey[700],
                                  ),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),

                          // Main Image - Full width
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ArtworkDetailPage(artwork: artwork),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              constraints: BoxConstraints(
                                minHeight: MediaQuery.of(context).size.height * 0.5,
                                maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                                          height: MediaQuery.of(context).size.height * 0.5,
                                          color: Colors.grey[100],
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: MediaQuery.of(context).size.height * 0.5,
                                        color: Colors.grey[100],
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      height: MediaQuery.of(context).size.height * 0.5,
                                      color: Colors.grey[100],
                                      child: Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                  // Video indicator
                                  if (isVideo)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black.withOpacity(0.1),
                                        child: const Center(
                                          child: Icon(
                                            Icons.play_circle_outline,
                                            size: 64,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // Action buttons and info
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Action buttons
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.favorite_border,
                                        size: 26,
                                      ),
                                      color: Colors.black87,
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.mode_comment_outlined,
                                        size: 24,
                                      ),
                                      color: Colors.black87,
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.send_outlined,
                                        size: 24,
                                      ),
                                      color: Colors.black87,
                                      onPressed: () {},
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.bookmark_border,
                                        size: 26,
                                      ),
                                      color: Colors.black87,
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Title
                                if (title.isNotEmpty)
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
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
          const SizedBox(height: 24),
            ],
          ),
        ),
      ],
      ),
      floatingActionButton: _currentUserRole == 'artist'
          ? FloatingActionButton.extended(
              onPressed: _openUploadPage,
              backgroundColor: Colors.black87,
              elevation: 2,
              icon: const Icon(Icons.add, color: Colors.white, size: 22),
              label: const Text(
                'Upload',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            )
          : null,
    );
  }
}
