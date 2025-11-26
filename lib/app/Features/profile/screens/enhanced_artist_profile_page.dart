import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../artwork/screens/artwork_detail_page.dart';
import '../../../shared/widgets/custom_network_image.dart';

class EnhancedArtistProfilePage extends StatefulWidget {
  final String artistId;

  const EnhancedArtistProfilePage({
    Key? key,
    required this.artistId,
  }) : super(key: key);

  @override
  State<EnhancedArtistProfilePage> createState() => _EnhancedArtistProfilePageState();
}

class _EnhancedArtistProfilePageState extends State<EnhancedArtistProfilePage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  late TabController _tabController;
  bool _isLoading = true;
  
  Map<String, dynamic>? _artistProfile;
  List<Map<String, dynamic>> _artworks = [];
  Map<String, dynamic> _statistics = {};
  
  // Follow system
  bool _isFollowing = false;
  int _followerCount = 0;
  int _followingCount = 0;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadArtistProfile();
    _checkIfCurrentUser();
    _checkFollowStatus();
    _loadFollowCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadArtistProfile() async {
    setState(() => _isLoading = true);

    try {
      // Load artist profile from users table
      final userResponse = await supabase
          .from('users')
          .select('id, name, email, specialization, bio, social_media, profile_image_url')
          .eq('id', widget.artistId)
          .single();

      // Load artist artworks
      final artworksResponse = await supabase
          .from('artworks')
          .select('id, title, media_url, thumbnail_url, artwork_type, likes_count, category, created_at')
          .eq('artist_id', widget.artistId)
          .eq('status', 'approved')
          .order('created_at', ascending: false) as List;

      // Calculate statistics
      final totalArtworks = artworksResponse.length;
      final totalLikes = artworksResponse.fold<int>(
        0,
        (sum, artwork) => sum + ((artwork['likes_count'] as int?) ?? 0),
      );

      // Count categories
      final categoryMap = <String, int>{};
      for (var artwork in artworksResponse) {
        final category = artwork['category'] as String? ?? 'Uncategorized';
        categoryMap[category] = (categoryMap[category] ?? 0) + 1;
      }

      setState(() {
        _artistProfile = userResponse;
        _artworks = List<Map<String, dynamic>>.from(artworksResponse);
        _statistics = {
          'total_artworks': totalArtworks,
          'total_likes': totalLikes,
          'avg_likes': totalArtworks > 0 ? (totalLikes / totalArtworks).toStringAsFixed(1) : '0',
          'categories': categoryMap,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading artist profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkIfCurrentUser() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        setState(() {
          _isCurrentUser = currentUser.id == widget.artistId;
        });
      }
    } catch (e) {
      debugPrint('Error checking current user: $e');
    }
  }

  Future<void> _checkFollowStatus() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null || _isCurrentUser) return;

      final response = await supabase
          .from('artist_follows')
          .select('id')
          .eq('follower_id', currentUser.id)
          .eq('artist_id', widget.artistId)
          .maybeSingle();

      setState(() {
        _isFollowing = response != null;
      });
    } catch (e) {
      debugPrint('Error checking follow status: $e');
    }
  }

  Future<void> _loadFollowCounts() async {
    try {
      // Get follower count
      final followerResponse = await supabase
          .from('artist_follows')
          .select('id')
          .eq('artist_id', widget.artistId);

      // Get following count
      final followingResponse = await supabase
          .from('artist_follows')
          .select('id')
          .eq('follower_id', widget.artistId);

      setState(() {
        _followerCount = followerResponse.length;
        _followingCount = followingResponse.length;
      });
    } catch (e) {
      debugPrint('Error loading follow counts: $e');
    }
  }

  Future<void> _toggleFollow() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to follow artists')),
        );
        return;
      }

      if (_isFollowing) {
        // Unfollow
        await supabase
            .from('artist_follows')
            .delete()
            .eq('follower_id', currentUser.id)
            .eq('artist_id', widget.artistId);

        setState(() {
          _isFollowing = false;
          _followerCount = (_followerCount - 1).clamp(0, 999999);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unfollowed successfully')),
          );
        }
      } else {
        // Follow
        await supabase.from('artist_follows').insert({
          'follower_id': currentUser.id,
          'artist_id': widget.artistId,
        });

        setState(() {
          _isFollowing = true;
          _followerCount++;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Following successfully')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
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
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF8B5CF6),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadArtistProfile,
                color: const Color(0xFF8B5CF6),
                child: CustomScrollView(
                  slivers: [
                    // Profile Header
                    SliverToBoxAdapter(
                      child: _buildProfileHeader(),
                    ),

                    // Statistics Cards
                    SliverToBoxAdapter(
                      child: _buildStatisticsCards(),
                    ),

                    // Bio Section
                    if (_artistProfile?['bio'] != null)
                      SliverToBoxAdapter(
                        child: _buildBioSection(),
                      ),

                    // Social Media
                    if (_artistProfile?['social_media'] != null)
                      SliverToBoxAdapter(
                        child: _buildSocialMedia(),
                      ),

                    // Tab Bar
                    SliverToBoxAdapter(
                      child: _buildTabBar(),
                    ),

                    // Tab Content
                    SliverFillRemaining(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPortfolioTab(),
                          _buildCategoriesTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final profileImageUrl = _artistProfile?['profile_image_url'];
    final name = _artistProfile?['name'] ?? 'Unknown Artist';
    final specialization = _artistProfile?['specialization'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
      child: Column(
        children: [
          // Profile Image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF8B5CF6),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: profileImageUrl != null
                  ? CustomNetworkImage(
                      imageUrl: profileImageUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.white.withOpacity(0.1),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 60,
                        color: Colors.white54,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          // Specialization
          if (specialization != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                specialization,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],

          // Follow Button (only show if not current user)
          if (!_isCurrentUser && supabase.auth.currentUser != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _toggleFollow,
              icon: Icon(
                _isFollowing ? Icons.check_rounded : Icons.person_add_rounded,
                size: 18,
              ),
              label: Text(
                _isFollowing ? 'Following' : 'Follow',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing 
                    ? Colors.white.withOpacity(0.2) 
                    : const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: _isFollowing ? 0 : 4,
              ),
            ),
          ],

          // Followers/Following stats
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFollowStat('Followers', _followerCount),
              Container(
                width: 1,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.white.withOpacity(0.3),
              ),
              _buildFollowStat('Following', _followingCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowStat(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Artworks',
              _statistics['total_artworks']?.toString() ?? '0',
              Icons.palette_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Likes',
              _statistics['total_likes']?.toString() ?? '0',
              Icons.favorite_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Avg Likes',
              _statistics['avg_likes']?.toString() ?? '0',
              Icons.trending_up_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF8B5CF6), size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBioSection() {
    final bio = _artistProfile?['bio'];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
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
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'About',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  bio,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialMedia() {
    final socialMedia = _artistProfile?['social_media'] as Map<String, dynamic>?;
    if (socialMedia == null || socialMedia.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
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
                Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Connect',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: socialMedia.entries.map((entry) {
                    IconData icon;
                    Color color;
                    
                    switch (entry.key.toLowerCase()) {
                      case 'instagram':
                        icon = Icons.camera_alt_rounded;
                        color = const Color(0xFFE4405F);
                        break;
                      case 'twitter':
                      case 'x':
                        icon = Icons.close_rounded;
                        color = const Color(0xFF1DA1F2);
                        break;
                      case 'linkedin':
                        icon = Icons.business_center_rounded;
                        color = const Color(0xFF0077B5);
                        break;
                      case 'website':
                        icon = Icons.language_rounded;
                        color = const Color(0xFF8B5CF6);
                        break;
                      default:
                        icon = Icons.link_rounded;
                        color = Colors.grey;
                    }
                    
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              labelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 14,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Portfolio'),
                Tab(text: 'Categories'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioTab() {
    if (_artworks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.palette_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No artworks yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _artworks.length,
      itemBuilder: (context, index) {
        final artwork = _artworks[index];
        return _buildArtworkCard(artwork);
      },
    );
  }

  Widget _buildCategoriesTab() {
    final categories = _statistics['categories'] as Map<String, int>? ?? {};
    
    if (categories.isEmpty) {
      return const Center(child: Text('No categories'));
    }

    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final entry = sortedCategories[index];
        final percentage = (_statistics['total_artworks'] as int) > 0
            ? (entry.value / (_statistics['total_artworks'] as int) * 100).toStringAsFixed(0)
            : '0';
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          entry.value.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$percentage% of total artworks',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white60,
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
        );
      },
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
}
