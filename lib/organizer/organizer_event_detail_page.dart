import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'organizer_event_curation_page.dart';
import 'organizer_analytics_page.dart';
import '../app/Features/event/services/pdf_label_generator.dart';

/// Halaman Detail Event untuk Organizer
/// Menampilkan semua fitur event management dalam tab-based navigation
class OrganizerEventDetailPage extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const OrganizerEventDetailPage({
    Key? key,
    required this.eventId,
    required this.eventTitle,
  }) : super(key: key);

  @override
  State<OrganizerEventDetailPage> createState() =>
      _OrganizerEventDetailPageState();
}

class _OrganizerEventDetailPageState extends State<OrganizerEventDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? _eventData;
  bool _isLoading = true;
  int _totalSubmissions = 0;
  int _approvedCount = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadEventData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEventData() async {
    setState(() => _isLoading = true);

    try {
      // Load event details
      final eventResponse = await supabase
          .from('events')
          .select('*')
          .eq('id', widget.eventId)
          .single();

      // Load submission statistics
      final submissions = await supabase
          .from('event_submissions')
          .select('status')
          .eq('event_id', widget.eventId);

      final approved = submissions.where((s) => s['status'] == 'approved').length;
      final pending = submissions.where((s) => s['status'] == 'pending').length;

      if (mounted) {
        setState(() {
          _eventData = eventResponse;
          _totalSubmissions = submissions.length;
          _approvedCount = approved;
          _pendingCount = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading event data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar dengan Event Info
              _buildCustomAppBar(),

              // Tab Bar
              _buildTabBar(),

              // Tab Bar View
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildCurationTab(),
                          _buildAnalyticsTab(),
                          _buildSettingsTab(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button & Title
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Event',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.eventTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Quick Stats
          if (!_isLoading) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildQuickStat(
                  icon: Icons.upload_file,
                  label: 'Total Submisi',
                  value: _totalSubmissions.toString(),
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 12),
                _buildQuickStat(
                  icon: Icons.check_circle,
                  label: 'Disetujui',
                  value: _approvedCount.toString(),
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 12),
                _buildQuickStat(
                  icon: Icons.pending,
                  label: 'Pending',
                  value: _pendingCount.toString(),
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white70,
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
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFF9333EA),
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.info_outline),
            text: 'Overview',
          ),
          Tab(
            icon: Icon(Icons.palette),
            text: 'Kurasi Karya',
          ),
          Tab(
            icon: Icon(Icons.analytics),
            text: 'Dashboard',
          ),
          Tab(
            icon: Icon(Icons.settings),
            text: 'Pengaturan',
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9333EA)),
      ),
    );
  }

  // ==================== TAB CONTENTS ====================

  /// Tab 1: Overview - Informasi umum event
  Widget _buildOverviewTab() {
    if (_eventData == null) {
      return const Center(
        child: Text(
          'Data event tidak tersedia',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // Null-safe date parsing
    DateTime? startDate;
    DateTime? endDate;
    try {
      if (_eventData!['start_date'] != null) {
        startDate = DateTime.parse(_eventData!['start_date']);
      }
      if (_eventData!['end_date'] != null) {
        endDate = DateTime.parse(_eventData!['end_date']);
      }
    } catch (e) {
      debugPrint('Error parsing dates: $e');
    }

    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Banner/Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF9333EA).withOpacity(0.3),
                    const Color(0xFF3B82F6).withOpacity(0.3),
                  ],
                ),
              ),
              child: _eventData!['image_url'] != null
                  ? Image.network(
                      _eventData!['image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
          ),

          const SizedBox(height: 24),

          // Event Information Cards
          _buildInfoCard(
            title: 'Informasi Event',
            children: [
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Tanggal Mulai',
                value: startDate != null ? dateFormat.format(startDate) : '-',
              ),
              const Divider(color: Colors.white10, height: 24),
              _buildInfoRow(
                icon: Icons.event,
                label: 'Tanggal Selesai',
                value: endDate != null ? dateFormat.format(endDate) : '-',
              ),
              const Divider(color: Colors.white10, height: 24),
              _buildInfoRow(
                icon: Icons.location_on,
                label: 'Lokasi',
                value: _eventData!['location']?.toString() ?? '-',
              ),
              const Divider(color: Colors.white10, height: 24),
              _buildInfoRow(
                icon: Icons.info,
                label: 'Status',
                value: _getStatusLabel(_eventData!['status']?.toString() ?? 'unknown'),
                valueColor: _getStatusColor(_eventData!['status']?.toString() ?? 'unknown'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildInfoCard(
            title: 'Deskripsi',
            children: [
              Text(
                _eventData!['description']?.toString() ?? 'Tidak ada deskripsi',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.6,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildInfoCard(
            title: 'Statistik Submisi',
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      label: 'Total Submisi',
                      value: _totalSubmissions.toString(),
                      icon: Icons.upload_file,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      label: 'Disetujui',
                      value: _approvedCount.toString(),
                      icon: Icons.check_circle,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      label: 'Pending',
                      value: _pendingCount.toString(),
                      icon: Icons.pending,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatItem(
                      label: 'Ditolak',
                      value: (_totalSubmissions - _approvedCount - _pendingCount).toString(),
                      icon: Icons.cancel,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.white.withOpacity(0.05),
      child: const Center(
        child: Icon(
          Icons.image,
          size: 64,
          color: Colors.white24,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF9333EA)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Terbuka';
      case 'closed':
        return 'Ditutup';
      case 'upcoming':
        return 'Akan Datang';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return const Color(0xFF10B981);
      case 'closed':
        return const Color(0xFFEF4444);
      case 'upcoming':
        return const Color(0xFF3B82F6);
      default:
        return Colors.white70;
    }
  }

  /// Tab 2: Kurasi Karya - Menggunakan widget yang sudah ada
  Widget _buildCurationTab() {
    return OrganizerEventCurationPage(
      eventId: widget.eventId,
      eventTitle: widget.eventTitle,
    );
  }

  /// Tab 3: Analytics/Dashboard - Menggunakan widget yang sudah ada
  Widget _buildAnalyticsTab() {
    return OrganizerAnalyticsPage(
      eventId: widget.eventId,
      eventTitle: widget.eventTitle,
    );
  }

  /// Tab 4: Pengaturan - Export PDF, Edit, Delete
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengaturan Event',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kelola event Anda dengan berbagai opsi berikut',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 24),

          // Export/Print Section
          _buildSettingCard(
            icon: Icons.qr_code_2,
            title: 'Export QR Code',
            subtitle: 'Cetak PDF berisi QR code semua karya yang disetujui',
            color: const Color(0xFF9333EA),
            onTap: _exportQRCodeLabels,
          ),

          const SizedBox(height: 12),

          _buildSettingCard(
            icon: Icons.picture_as_pdf,
            title: 'Export Katalog',
            subtitle: 'Unduh katalog lengkap event dalam format PDF',
            color: const Color(0xFF3B82F6),
            onTap: () {
              _showComingSoonDialog('Export Katalog');
            },
          ),

          const SizedBox(height: 24),

          // Divider
          Divider(color: Colors.white.withOpacity(0.1)),

          const SizedBox(height: 24),

          // Edit Section
          _buildSettingCard(
            icon: Icons.edit,
            title: 'Edit Event',
            subtitle: 'Ubah informasi, tanggal, atau deskripsi event',
            color: const Color(0xFF10B981),
            onTap: () {
              _showComingSoonDialog('Edit Event');
            },
          ),

          const SizedBox(height: 12),

          _buildSettingCard(
            icon: Icons.image,
            title: 'Ganti Banner',
            subtitle: 'Update gambar banner event',
            color: const Color(0xFFF59E0B),
            onTap: () {
              _showComingSoonDialog('Ganti Banner');
            },
          ),

          const SizedBox(height: 24),

          // Divider
          Divider(color: Colors.white.withOpacity(0.1)),

          const SizedBox(height: 24),

          // Danger Zone
          Text(
            'Zona Berbahaya',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 12),

          _buildSettingCard(
            icon: Icons.delete_forever,
            title: 'Hapus Event',
            subtitle: 'Hapus event secara permanen (tidak dapat dibatalkan)',
            color: const Color(0xFFEF4444),
            onTap: () {
              _showDeleteConfirmation();
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Export QR Code labels untuk semua artwork yang approved
  Future<void> _exportQRCodeLabels() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9333EA)),
              ),
              const SizedBox(height: 16),
              Text(
                'Memuat data artwork...',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );

      // Fetch approved artworks from event_submissions
      final response = await supabase
          .from('event_submissions')
          .select('''
            id,
            artwork_id,
            artworks!inner(
              id,
              title,
              year,
              category,
              profiles!inner(full_name)
            )
          ''')
          .eq('event_id', widget.eventId)
          .eq('status', 'approved');

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response.isEmpty) {
        // No approved artworks
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tidak Ada Data',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Belum ada karya yang disetujui untuk event ini. Silakan setujui beberapa karya terlebih dahulu.',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Tutup',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF9333EA),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Convert to ArtworkModel list
      final artworks = response.map((item) {
        final artwork = item['artworks'] as Map<String, dynamic>;
        final profile = artwork['profiles'] as Map<String, dynamic>;
        
        return ArtworkModel(
          id: artwork['id'].toString(),
          title: artwork['title'] ?? 'Untitled',
          artistName: profile['full_name'] ?? 'Unknown Artist',
          category: artwork['category'] ?? 'Uncategorized',
          year: artwork['year']?.toString() ?? '-',
        );
      }).toList();

      // Generate and preview PDF
      await PdfLabelGenerator.generateAndPreview(
        artworks: artworks,
        eventTitle: widget.eventTitle,
      );

    } catch (e) {
      // Close loading if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.error,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Error',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'Gagal membuat PDF: $e',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Tutup',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF9333EA).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.construction,
                color: Color(0xFF9333EA),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Coming Soon',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Fitur "$feature" sedang dalam pengembangan dan akan segera tersedia!',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: GoogleFonts.poppins(
                color: const Color(0xFF9333EA),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Hapus Event?',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus event ini? Semua data submisi dan statistik akan hilang secara permanen.\n\nTindakan ini tidak dapat dibatalkan!',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoonDialog('Hapus Event');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Hapus',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
