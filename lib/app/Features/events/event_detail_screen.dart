import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/widgets/custom_network_image.dart';
import '../../../../main/main_app.dart';

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isZoomButtonVisible = true;
  late TabController _tabController;
  
  // New variables for submission status
  Map<String, dynamic>? _submissionStatus;
  bool _isLoadingSubmission = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _scrollController.addListener(() {
      // Sembunyikan button zoom saat scroll melewati 50px
      if (_scrollController.offset > 50 && _isZoomButtonVisible) {
        setState(() => _isZoomButtonVisible = false);
      } else if (_scrollController.offset <= 50 && !_isZoomButtonVisible) {
        setState(() => _isZoomButtonVisible = true);
      }
    });

    _animationController.forward();
    _checkSubmissionStatus();
  }

  Future<void> _checkSubmissionStatus() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      setState(() => _isLoadingSubmission = false);
      return;
    }

    try {
      // Get user role
      final userProfile = await supabase
          .from('users')
          .select('role')
          .eq('id', currentUser.id)
          .maybeSingle();
      
      _userRole = userProfile?['role'] as String?;

      // Check if already submitted to this event
      final submission = await supabase
          .from('event_submissions')
          .select('*, artworks(title, media_url)')
          .eq('event_id', widget.event['id'])
          .eq('artist_id', currentUser.id)
          .maybeSingle();

      setState(() {
        _submissionStatus = submission;
        _isLoadingSubmission = false;
      });
    } catch (e) {
      debugPrint('Error checking submission: $e');
      setState(() => _isLoadingSubmission = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _shareEvent() {
    String eventDateFormatted = 'Tanggal belum ditentukan';

    if (widget.event['event_date'] != null) {
      try {
        final eventDate = DateTime.parse(widget.event['event_date']);
        final monthNames = [
          '',
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        final day = eventDate.day;
        final month = monthNames[eventDate.month];
        final year = eventDate.year;
        final hour = eventDate.hour.toString().padLeft(2, '0');
        final minute = eventDate.minute.toString().padLeft(2, '0');

        eventDateFormatted = '$day $month $year, $hour:$minute';
      } catch (e) {
        eventDateFormatted = 'Tanggal belum ditentukan';
      }
    }

    final shareText =
        '''
🎨 ${widget.event['title']}

📅 $eventDateFormatted
📍 ${widget.event['location'] ?? 'Lokasi belum ditentukan'}

${widget.event['content'] ?? ''}

#UNPArtSpace #EventSeni
    ''';

    Share.share(shareText, subject: widget.event['title']);
  }

  void _showArtworkSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ArtworkSelectionSheet(
        eventId: widget.event['id'],
        onSubmitted: () {
          Navigator.pop(context);
          _checkSubmissionStatus(); // Refresh status
        },
      ),
    );
  }

  Future<void> _submitArtwork(int artworkId) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      await supabase.from('event_submissions').insert({
        'event_id': widget.event['id'],
        'artwork_id': artworkId,
        'artist_id': currentUser.id,
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Karya berhasil didaftarkan!'),
            backgroundColor: Colors.green,
          ),
        );
        _checkSubmissionStatus(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendaftar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatEventDate(DateTime? eventDate) {
    if (eventDate == null) return 'Tanggal belum ditentukan';

    try {
      final dayNames = [
        '',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final monthNames = [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      final dayName = dayNames[eventDate.weekday];
      final day = eventDate.day;
      final month = monthNames[eventDate.month];
      final year = eventDate.year;
      final hour = eventDate.hour.toString().padLeft(2, '0');
      final minute = eventDate.minute.toString().padLeft(2, '0');

      return '$dayName, $day $month $year\nAt $hour:$minute WIB';
    } catch (e) {
      return eventDate.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.5;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Layer 1: Dark Gradient Background (Full Screen)
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F2027), // Deep Blue Dark
                  Color(0xFF203A43),
                  Color(0xFF2C5364),
                ],
              ),
            ),
          ),

          // Layer 2: Hero Image with Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                if (widget.event['image_url'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _FullScreenImageView(
                        imageUrl: widget.event['image_url'],
                        heroTag: 'event_${widget.event['id']}',
                      ),
                    ),
                  );
                }
              },
              behavior: HitTestBehavior.translucent,
              child: SizedBox(
                height: imageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Hero Image
                    Hero(
                      tag: 'event_${widget.event['id']}',
                      child: widget.event['image_url'] != null
                          ? CustomNetworkImage(
                              imageUrl: widget.event['image_url'],
                              fit: BoxFit.cover,
                              borderRadius: 0,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF1E3A8A),
                                    const Color(0xFF9333EA),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.event,
                                size: 120,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                    ),
                    // Gradient Overlay (Smooth blend to dark background)
                    IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                              const Color(0xFF0F2027).withOpacity(0.8),
                              const Color(0xFF0F2027),
                            ],
                            stops: const [0.0, 0.5, 0.85, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Layer 3: Scrollable Content with TabBar
          Column(
            children: [
              // Spacing untuk foto - konten dimulai tepat di bawah foto
              SizedBox(height: imageHeight),

              // Content with Animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // TabBar with Premium Glass Effect & Shadow
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicator: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                                  ),
                                  borderRadius: BorderRadius.circular(9),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B5CF6).withOpacity(0.6),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                dividerColor: Colors.transparent,
                                indicatorSize: TabBarIndicatorSize.tab,
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.white.withOpacity(0.6),
                                labelStyle: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                                tabs: [
                                  Tab(
                                    height: 38,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.info_outline_rounded, size: 16),
                                        const SizedBox(width: 6),
                                        Text('Detail'),
                                      ],
                                    ),
                                  ),
                                  Tab(
                                    height: 38,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.photo_library_rounded, size: 16),
                                        const SizedBox(width: 6),
                                        Text('Showcase'),
                                      ],
                                    ),
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

              // TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Detail Event
                    _buildDetailTab(),
                    // Tab 2: Showcase Karya
                    _buildShowcaseTab(),
                  ],
                ),
              ),
            ],
          ),

          // Top Navigation: Back & Share Buttons (Glass Circles)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button (Glass)
                  _buildGlassCircleButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                  // Share Button (Glass)
                  _buildGlassCircleButton(
                    icon: Icons.share_rounded,
                    onTap: _shareEvent,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sticky Action Bar (Glass) - Updated with submission logic
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: _buildActionButton(),
                ),
              ),
            ),
          ),

          // Zoom Button (Di pojok kanan bawah foto)
          Positioned(
            top: imageHeight - 60,
            right: 20,
            child: AnimatedOpacity(
              opacity: _isZoomButtonVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_isZoomButtonVisible,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (widget.event['image_url'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _FullScreenImageView(
                              imageUrl: widget.event['image_url'],
                              heroTag: 'event_${widget.event['id']}_button',
                            ),
                          ),
                        );
                      }
                    },
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.zoom_out_map,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build action button based on user role and submission status
  Widget _buildActionButton() {
    // Loading state
    if (_isLoadingSubmission) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    // If user is artist and hasn't submitted
    if (_userRole == 'artist' && _submissionStatus == null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showArtworkSelectionSheet,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF10B981), // Green
                  Color(0xFF059669),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_photo_alternate_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Text(
                  'Daftarkan Karya Saya',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If already submitted, show status
    if (_submissionStatus != null) {
      final status = _submissionStatus!['status'] as String;
      Color statusColor;
      IconData statusIcon;
      String statusText;

      switch (status) {
        case 'approved':
          statusColor = const Color(0xFF10B981);
          statusIcon = Icons.check_circle_rounded;
          statusText = 'Lolos Seleksi';
          break;
        case 'rejected':
          statusColor = const Color(0xFFEF4444);
          statusIcon = Icons.cancel_rounded;
          statusText = 'Tidak Lolos';
          break;
        default:
          statusColor = const Color(0xFFF59E0B);
          statusIcon = Icons.schedule_rounded;
          statusText = 'Menunggu Kurasi';
      }

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(statusIcon, color: statusColor, size: 24),
            const SizedBox(width: 12),
            Text(
              statusText,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ],
        ),
      );
    }

    // Default: Share button for non-artists or viewers
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _shareEvent,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF8B5CF6),
                Color(0xFF3B82F6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.share_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Text(
                'Bagikan Event Ini',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tab 1: Detail Event
  Widget _buildDetailTab() {
    final eventDate = widget.event['event_date'] != null
        ? DateTime.parse(widget.event['event_date'])
        : null;

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Glass Card
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event['title'] ?? 'Untitled Event',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Artist Info (if available)
                  if (widget.event['artist_name'] != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          backgroundImage:
                              widget.event['artist_avatar'] != null
                                  ? NetworkImage(
                                      widget.event['artist_avatar'],
                                    )
                                  : null,
                          child: widget.event['artist_avatar'] == null
                              ? const Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Colors.white70,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Diselenggarakan oleh',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.white60,
                                ),
                              ),
                              Text(
                                widget.event['artist_name'],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Date & Time Glass Card
            _buildInfoGlassCard(
              icon: Icons.calendar_month_rounded,
              iconGradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
              ),
              title: 'Tanggal & Waktu',
              content: _formatEventDate(eventDate),
            ),

            const SizedBox(height: 12),

            // Location Glass Card
            _buildInfoGlassCard(
              icon: Icons.location_on_rounded,
              iconGradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              ),
              title: 'Lokasi Event',
              content: widget.event['location'] ?? 'Lokasi belum ditentukan',
            ),

            const SizedBox(height: 16),

            // Description Glass Card
            _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF10B981),
                              Color(0xFF34D399),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Tentang Event',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.event['content'] ?? 'Tidak ada deskripsi',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      height: 1.8,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
    );
  }

  // Tab 2: Showcase Karya
  Widget _buildShowcaseTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('event_submissions')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.poppins(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Filter submissions for this event and approved status
        final allSubmissions = snapshot.data ?? [];
        final submissions = allSubmissions.where((s) => 
          s['event_id'] == widget.event['id'] && 
          s['status'] == 'approved'
        ).toList();

        if (submissions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 100,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Belum Ada Karya yang Dipamerkan',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Karya yang lolos kurasi akan ditampilkan di sini',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Fetch detailed data
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchApprovedArtworks(submissions),
          builder: (context, detailSnapshot) {
            if (detailSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                ),
              );
            }

            if (detailSnapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error loading artworks: ${detailSnapshot.error}',
                    style: GoogleFonts.poppins(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final artworks = detailSnapshot.data ?? [];

            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: artworks.length,
              itemBuilder: (context, index) {
                return _buildShowcaseArtworkCard(artworks[index]);
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchApprovedArtworks(
      List<Map<String, dynamic>> submissions) async {
    List<Map<String, dynamic>> artworks = [];

    for (var submission in submissions) {
      try {
        // Fetch artwork details
        final artworkResponse = await supabase
            .from('artworks')
            .select()
            .eq('id', submission['artwork_id'])
            .single();

        // Fetch artist profile
        final profileResponse = await supabase
            .from('profiles')
            .select()
            .eq('id', submission['artist_id'])
            .single();

        artworks.add({
          'artwork': artworkResponse,
          'profile': profileResponse,
        });
      } catch (e) {
        debugPrint('Error fetching artwork details: $e');
      }
    }

    return artworks;
  }

  Widget _buildShowcaseArtworkCard(Map<String, dynamic> data) {
    final artwork = data['artwork'] as Map<String, dynamic>?;
    final profile = data['profile'] as Map<String, dynamic>?;

    if (artwork == null) return const SizedBox.shrink();

    final artworkTitle = artwork['title'] ?? 'Untitled';
    final artworkMedia = artwork['media_url'] as String?;
    final artistName = profile?['username'] ?? 'Unknown Artist';

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to ArtworkDetailPage
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detail karya: $artworkTitle'),
            backgroundColor: const Color(0xFF8B5CF6),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Image
              if (artworkMedia != null && artworkMedia.isNotEmpty)
                CustomNetworkImage(
                  imageUrl: artworkMedia,
                  fit: BoxFit.cover,
                  borderRadius: 16,
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1E3A8A),
                        const Color(0xFF9333EA),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.white54,
                    ),
                  ),
                ),

              // Gradient overlay with info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.9),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        artworkTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_rounded,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              artistName,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Approved badge
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Lolos',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Glass Card Builder
  Widget _buildGlassCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // Info Glass Card with Icon
  Widget _buildInfoGlassCard({
    required IconData icon,
    required Gradient iconGradient,
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: iconGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: iconGradient.colors.first.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white60,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        content,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: Colors.white,
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
  }

  // Glass Circle Button (Back/Share)
  Widget _buildGlassCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

// Full Screen Image View Widget
class _FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _FullScreenImageView({required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Interactive Viewer for Zoom & Pan
          Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CustomNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  borderRadius: 0,
                ),
              ),
            ),
          ),

          // Close Button (Glass Circle)
          SafeArea(
            child: Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Artwork Selection Bottom Sheet
class _ArtworkSelectionSheet extends StatefulWidget {
  final dynamic eventId;
  final VoidCallback onSubmitted;

  const _ArtworkSelectionSheet({
    required this.eventId,
    required this.onSubmitted,
  });

  @override
  State<_ArtworkSelectionSheet> createState() =>
      _ArtworkSelectionSheetState();
}

class _ArtworkSelectionSheetState extends State<_ArtworkSelectionSheet> {
  int? _selectedArtworkId;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pilih Karya Untuk Didaftarkan',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilih salah satu karya Anda atau upload karya baru',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white60,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Artworks Grid
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchUserArtworks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.poppins(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final artworks = snapshot.data ?? [];

                if (artworks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Belum Ada Karya',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload karya baru untuk mendaftar event',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white60,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: artworks.length,
                  itemBuilder: (context, index) {
                    final artwork = artworks[index];
                    final isSelected = _selectedArtworkId == artwork['id'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedArtworkId = artwork['id'] as int;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF10B981)
                                : Colors.white.withOpacity(0.2),
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981)
                                        .withOpacity(0.5),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // Image
                              if (artwork['media_url'] != null)
                                CustomNetworkImage(
                                  imageUrl: artwork['media_url'],
                                  fit: BoxFit.cover,
                                  borderRadius: 16,
                                )
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF1E3A8A),
                                        const Color(0xFF9333EA),
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 50,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),

                              // Gradient overlay
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
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
                                  child: Text(
                                    artwork['title'] ?? 'Untitled',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),

                              // Selected indicator
                              if (isSelected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
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
              },
            ),
          ),

          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Submit button
                if (_selectedArtworkId != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSubmitting ? null : _submitArtwork,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF10B981),
                              Color(0xFF059669),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _isSubmitting
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send_rounded,
                                      color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Kirim Pendaftaran',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Upload new artwork button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Fitur upload karya baru akan segera tersedia'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Upload Karya Baru',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUserArtworks() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return [];

    try {
      final result = await supabase
          .from('artworks')
          .select()
          .eq('artist_id', currentUser.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result as List);
    } catch (e) {
      debugPrint('Error fetching artworks: $e');
      return [];
    }
  }

  Future<void> _submitArtwork() async {
    if (_selectedArtworkId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      await supabase.from('event_submissions').insert({
        'event_id': widget.eventId,
        'artwork_id': _selectedArtworkId,
        'artist_id': currentUser.id,
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Karya berhasil didaftarkan!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSubmitted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendaftar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
