import 'package:flutter/material.dart';
import '../../../../main/main_app.dart'; // access supabase client
import '../../../core/navigation/auth_gate.dart';
import '../../artwork/screens/upload_artwork_page.dart';
import '../../events/upload_event_screen.dart';
import '../../events/event_detail_screen.dart';
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
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.secondary, AppTheme.secondaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: FlexibleSpaceBar(
                title: Text(
                  'UNP Art Space',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: Colors.white,
                tooltip: 'Notifikasi',
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                color: Colors.white,
                tooltip: 'Logout',
                onPressed: () async {
              try {
                await supabase.auth.signOut();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout gagal: $e'),
                      backgroundColor: AppTheme.error,
                    ),
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
          const SizedBox(width: AppTheme.spaceXs),
        ],
      ),
      
      SliverToBoxAdapter(
        child: Column(
          children: [
            // Gradient overlay effect at top
            Container(
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.secondary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
          // Section Header: Event Seni Mendatang
          FadeSlideAnimation(
            delay: const Duration(milliseconds: 100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.secondary.withOpacity(0.2), AppTheme.accent.withOpacity(0.2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event_note_rounded,
                      color: AppTheme.secondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSm),
                  Text(
                    'Event Seni Mendatang',
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
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
              itemCount: _isLoadingEvents ? 3 : (_events.isEmpty ? 1 : _events.length),
              itemBuilder: (context, idx) {
                if (_isLoadingEvents) {
                  // Loading skeleton with shimmer
                  return FadeInAnimation(
                    delay: Duration(milliseconds: idx * 100),
                    child: Container(
                      width: 320,
                      margin: const EdgeInsets.only(right: AppTheme.spaceMd),
                      child: const ShimmerLoading(
                        width: 320,
                        height: 220,
                        radius: AppTheme.radiusXl,
                      ),
                    ),
                  );
                }

                if (_events.isEmpty) {
                  return FadeInAnimation(
                    child: Container(
                      width: 320,
                      margin: const EdgeInsets.only(right: AppTheme.spaceMd),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                        boxShadow: AppTheme.shadowMd,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy_outlined,
                              size: 56,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(height: AppTheme.spaceSm),
                            Text(
                              'Belum ada event',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final event = _events[idx];
                return ScaleInAnimation(
                  delay: Duration(milliseconds: idx * 100),
                  child: BounceAnimation(
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
                      child: Container(
                        width: 320,
                        margin: const EdgeInsets.only(right: AppTheme.spaceMd),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          boxShadow: AppTheme.shadowLg,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          child: Stack(
                            children: [
                              // Background Image
                              Positioned.fill(
                                child: event['image_url'] != null
                                    ? Image.network(
                                        event['image_url']!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: AppTheme.textTertiary.withOpacity(0.1),
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 48,
                                            color: AppTheme.textTertiary,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.primaryGradient,
                                        ),
                                      ),
                              ),
                              // Gradient Overlay
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.8),
                                      ],
                                      stops: const [0.4, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              // Content
                              Positioned(
                                left: AppTheme.spaceMd,
                                right: AppTheme.spaceMd,
                                bottom: AppTheme.spaceMd,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event['title'] ?? 'Event',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontFamily: 'Playfair Display',
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: AppTheme.spaceSm),
                                    if (event['event_date'] != null)
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppTheme.spaceSm,
                                              vertical: AppTheme.spaceXs,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentYellow.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.calendar_today_rounded,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatEventDate(event['event_date']),
                                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (event['location'] != null) ...[
                                      const SizedBox(height: AppTheme.spaceXs),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_rounded,
                                            size: 16,
                                            color: Colors.white70,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              event['location'],
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),

          // Filter Kategori
          FadeSlideAnimation(
            delay: const Duration(milliseconds: 200),
            child: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                itemCount: _categories.length,
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final isSelected = _selectedCategory == cat;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: AppTheme.spaceXs),
                    child: BounceAnimation(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                          _artworksFuture = _loadArtworks();
                        });
                      },
                      child: AnimatedContainer(
                        duration: AppTheme.animationFast,
                        curve: Curves.easeInOut,
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
                          color: isSelected ? null : AppTheme.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : AppTheme.secondary.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: isSelected 
                              ? [
                                  BoxShadow(
                                    color: AppTheme.secondary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
          const SizedBox(height: AppTheme.spaceLg),

          // Galeri Karya Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.secondary.withOpacity(0.2), AppTheme.accent.withOpacity(0.2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.art_track_rounded,
                    color: AppTheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Text(
                  'Galeri Karya',
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

                // Full-screen card layout seperti social media
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

                    return FadeSlideAnimation(
                      delay: Duration(milliseconds: idx * 100),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppTheme.spaceLg),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.secondary.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          // Subtle gradient border effect
                          border: Border.all(
                            color: AppTheme.secondary.withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with artist info
                            Padding(
                              padding: const EdgeInsets.all(AppTheme.spaceMd),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [AppTheme.secondary, AppTheme.secondaryLight],
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppTheme.surface,
                                      child: Text(
                                        artist.isNotEmpty ? artist[0].toUpperCase() : 'A',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppTheme.secondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spaceSm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          artist,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (category.isNotEmpty)
                                          Text(
                                            category,
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.more_vert_rounded,
                                      color: AppTheme.textSecondary,
                                    ),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),

                            // Main Image - Full width
                            BounceAnimation(
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
                                            color: AppTheme.textTertiary.withOpacity(0.05),
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
                                          height: MediaQuery.of(context).size.height * 0.5,
                                          color: AppTheme.textTertiary.withOpacity(0.05),
                                          child: Center(
                                            child: Icon(
                                              Icons.broken_image_outlined,
                                              size: 64,
                                              color: AppTheme.textTertiary,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        height: MediaQuery.of(context).size.height * 0.5,
                                        color: AppTheme.textTertiary.withOpacity(0.05),
                                        child: Center(
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 64,
                                            color: AppTheme.textTertiary,
                                          ),
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
                                              size: 72,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    // Bottom gradient overlay for smooth transition
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              AppTheme.surface.withOpacity(0.3),
                                              AppTheme.surface,
                                            ],
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
                              padding: const EdgeInsets.all(AppTheme.spaceMd),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Action buttons
                                  Row(
                                    children: [
                                      _buildActionButton(
                                        icon: Icons.chat_bubble_outline_rounded,
                                        count: '10',
                                        onTap: () {},
                                      ),
                                      const SizedBox(width: AppTheme.spaceSm),
                                      _buildActionButton(
                                        icon: Icons.favorite_outline_rounded,
                                        count: '122',
                                        onTap: () {},
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: Icon(
                                          Icons.send_rounded,
                                          color: AppTheme.textSecondary,
                                          size: 22,
                                        ),
                                        onPressed: () {},
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.bookmark_outline_rounded,
                                          color: AppTheme.textSecondary,
                                          size: 22,
                                        ),
                                        onPressed: () {},
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppTheme.spaceSm),
                                  // Title
                                  Text(
                                    title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontFamily: 'Playfair Display',
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 2,
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
          const SizedBox(height: AppTheme.spaceLg),
            ],
          ),
        ),
      ],
      ),
      floatingActionButton: _currentUserRole == 'artist'
          ? ScaleInAnimation(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 400),
              child: FloatingActionButton.extended(
                onPressed: _openUploadPage,
                backgroundColor: AppTheme.secondary,
                elevation: 8,
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                label: Text(
                  'Unggah Karya',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceXs,
          vertical: 4,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 4),
            Text(
              count,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
