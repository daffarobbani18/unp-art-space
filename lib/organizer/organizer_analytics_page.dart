import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class OrganizerAnalyticsPage extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const OrganizerAnalyticsPage({
    Key? key,
    required this.eventId,
    required this.eventTitle,
  }) : super(key: key);

  @override
  State<OrganizerAnalyticsPage> createState() => _OrganizerAnalyticsPageState();
}

class _OrganizerAnalyticsPageState extends State<OrganizerAnalyticsPage> {
  final supabase = Supabase.instance.client;
  
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      // Get event submissions
      final submissions = await supabase
          .from('event_submissions')
          .select('id, status, artwork_id, created_at')
          .eq('event_id', widget.eventId);

      // Get artworks with engagement data
      final artworkIds = submissions.map((s) => s['artwork_id']).toList();
      
      List<Map<String, dynamic>> artworks = [];
      int totalLikes = 0;
      int totalComments = 0;
      
      if (artworkIds.isNotEmpty) {
        // Fetch artworks basic info
        artworks = List<Map<String, dynamic>>.from(
          await supabase
              .from('artworks')
              .select('id, title, artist_name')
              .inFilter('id', artworkIds)
        );

        // Count real-time likes from likes table for each artwork
        for (var artwork in artworks) {
          final artworkId = artwork['id'];
          
          // Get likes count
          final likesResponse = await supabase
              .from('likes')
              .select('id')
              .eq('artwork_id', artworkId);
          
          final likesCount = likesResponse.length;
          artwork['likes_count'] = likesCount;
          totalLikes += likesCount;
          
          // Get comments count
          final commentsResponse = await supabase
              .from('comments')
              .select('id')
              .eq('artwork_id', artworkId);
          
          totalComments += commentsResponse.length;
        }
      }

      // Calculate statistics
      final approved = submissions.where((s) => s['status'] == 'approved').length;
      final pending = submissions.where((s) => s['status'] == 'pending').length;
      final rejected = submissions.where((s) => s['status'] == 'rejected').length;

      // Top artworks by likes (sort by real-time likes count)
      artworks.sort((a, b) => 
        ((b['likes_count'] as int?) ?? 0).compareTo((a['likes_count'] as int?) ?? 0)
      );
      final topArtworks = artworks.take(5).toList();

      setState(() {
        _analytics = {
          'total_submissions': submissions.length,
          'approved': approved,
          'pending': pending,
          'rejected': rejected,
          'total_likes': totalLikes,
          'total_comments': totalComments,
          'top_artworks': topArtworks,
          'avg_engagement': submissions.isEmpty ? 0 : (totalLikes + totalComments) / submissions.length,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      setState(() => _isLoading = false);
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
        title: Text(
          'Analytics',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF8B5CF6),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  color: const Color(0xFF8B5CF6),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Event Title
                      _buildEventHeader(),
                      const SizedBox(height: 24),

                      // Overview Cards
                      _buildOverviewCards(),
                      const SizedBox(height: 24),

                      // Submission Status Chart
                      _buildSubmissionChart(),
                      const SizedBox(height: 24),

                      // Engagement Stats
                      _buildEngagementStats(),
                      const SizedBox(height: 24),

                      // Top Artworks
                      _buildTopArtworks(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEventHeader() {
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
          child: Row(
            children: [
              const Icon(
                Icons.event_rounded,
                color: Color(0xFF8B5CF6),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.eventTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Submissions',
            _analytics['total_submissions']?.toString() ?? '0',
            Icons.inbox_rounded,
            const Color(0xFF8B5CF6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Approved',
            _analytics['approved']?.toString() ?? '0',
            Icons.check_circle_rounded,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionChart() {
    final approved = (_analytics['approved'] as int?) ?? 0;
    final pending = (_analytics['pending'] as int?) ?? 0;
    final rejected = (_analytics['rejected'] as int?) ?? 0;
    final total = approved + pending + rejected;

    if (total == 0) {
      return const SizedBox();
    }

    return ClipRRect(
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
              Text(
                'Submission Status',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(
                              value: approved.toDouble(),
                              title: '$approved',
                              color: Colors.green,
                              radius: 50,
                              titleStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              value: pending.toDouble(),
                              title: '$pending',
                              color: Colors.orange,
                              radius: 50,
                              titleStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              value: rejected.toDouble(),
                              title: '$rejected',
                              color: Colors.red,
                              radius: 50,
                              titleStyle: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Approved', Colors.green, approved),
                      const SizedBox(height: 8),
                      _buildLegendItem('Pending', Colors.orange, pending),
                      const SizedBox(height: 8),
                      _buildLegendItem('Rejected', Colors.red, rejected),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $value',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Likes',
            _analytics['total_likes']?.toString() ?? '0',
            Icons.favorite_rounded,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Comments',
            _analytics['total_comments']?.toString() ?? '0',
            Icons.comment_rounded,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildTopArtworks() {
    final topArtworks = _analytics['top_artworks'] as List<Map<String, dynamic>>? ?? [];

    if (topArtworks.isEmpty) {
      return const SizedBox();
    }

    return ClipRRect(
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
                    Icons.trending_up_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Top 5 Most Liked Artworks',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...topArtworks.asMap().entries.map((entry) {
                final index = entry.key;
                final artwork = entry.value;
                return _buildTopArtworkItem(
                  index + 1,
                  artwork['title'] ?? 'Untitled',
                  artwork['artist_name'] ?? 'Unknown',
                  artwork['likes_count'] ?? 0,
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopArtworkItem(int rank, String title, String artist, int likes) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: rank <= 3
                  ? const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                    )
                  : null,
              color: rank > 3 ? Colors.white.withOpacity(0.1) : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  artist,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.favorite_rounded,
                size: 16,
                color: Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                likes.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
