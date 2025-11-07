import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'upload_event_screen.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // all, pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadMyEvents();
  }

  Future<void> _loadMyEvents() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User tidak terautentikasi');
      }

      print('🔍 Loading events for user: ${user.id}');

      var baseQuery = Supabase.instance.client
          .from('events')
          .select('*')
          .eq('artist_id', user.id);

      // Filter by status if not 'all'
      final query = _filterStatus != 'all'
          ? baseQuery.eq('status', _filterStatus)
          : baseQuery;

      final response = await query.order('created_at', ascending: false);

      final eventsList = List<Map<String, dynamic>>.from(response as List);
      print('✅ Found ${eventsList.length} events');

      setState(() {
        _events = eventsList;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading events: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'disetujui':
        return const Color(0xFF059669);
      case 'rejected':
      case 'ditolak':
        return const Color(0xFFDC2626);
      case 'pending':
      case 'menunggu_persetujuan':
      case 'menunggu':
        return const Color(0xFFEA580C);
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'disetujui':
        return 'Disetujui';
      case 'rejected':
      case 'ditolak':
        return 'Ditolak';
      case 'pending':
      case 'menunggu_persetujuan':
      case 'menunggu':
        return 'Menunggu';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'disetujui':
        return Icons.check_circle;
      case 'rejected':
      case 'ditolak':
        return Icons.cancel;
      case 'pending':
      case 'menunggu_persetujuan':
      case 'menunggu':
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _navigateToUploadEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadEventScreen()),
    );

    if (result == true) {
      _loadMyEvents(); // Refresh list setelah upload
    }
  }

  String _formatCreatedDate(dynamic createdAt) {
    if (createdAt == null) return '-';
    
    try {
      final date = DateTime.parse(createdAt.toString());
      final monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final day = date.day.toString().padLeft(2, '0');
      final month = monthNames[date.month];
      final year = date.year;
      
      return '$day $month $year';
    } catch (e) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Event Saya', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _loadMyEvents,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Semua', 'all', Colors.grey[700]!),
                  const SizedBox(width: 8),
                  _buildFilterChip('Menunggu', 'pending', const Color(0xFFEA580C)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Disetujui', 'approved', const Color(0xFF059669)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Ditolak', 'rejected', const Color(0xFFDC2626)),
                ],
              ),
            ),
          ),

          // Event List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_outlined, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _filterStatus == 'all' 
                                  ? 'Belum ada event' 
                                  : 'Tidak ada event dengan status "${_getStatusLabel(_filterStatus)}"',
                              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Klik tombol + untuk mengajukan event baru',
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMyEvents,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _events.length,
                          itemBuilder: (context, index) => _buildEventCard(_events[index]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToUploadEvent,
        backgroundColor: const Color(0xFF9333EA),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Ajukan Event', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = _filterStatus == value;
    return InkWell(
      onTap: () {
        setState(() => _filterStatus = value);
        _loadMyEvents();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final status = event['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final statusIcon = _getStatusIcon(status);

    String eventDate = 'Tanggal belum ditentukan';
    if (event['event_date'] != null) {
      try {
        final date = DateTime.parse(event['event_date']);
        final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        final monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        
        final dayName = dayNames[date.weekday];
        final day = date.day.toString().padLeft(2, '0');
        final month = monthNames[date.month];
        final year = date.year;
        final hour = date.hour.toString().padLeft(2, '0');
        final minute = date.minute.toString().padLeft(2, '0');
        
        eventDate = '$dayName, $day $month $year\n$hour:$minute WIB';
      } catch (e) {
        eventDate = 'Tanggal belum ditentukan';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (event['image_url'] != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    event['image_url'],
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: Icon(Icons.event, size: 64, color: Colors.grey[400]),
                    ),
                  ),
                ),
                // Status Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  event['title'] ?? 'Untitled Event',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Date & Time
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        eventDate,
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Location
                if (event['location'] != null)
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event['location'],
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                // Description
                if (event['content'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    event['content'],
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Rejection Reason
                if (status.toLowerCase() == 'rejected' || status.toLowerCase() == 'ditolak')
                  if (event['rejection_reason'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.red[700]),
                              const SizedBox(width: 6),
                              Text(
                                'Alasan Penolakan:',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            event['rejection_reason'],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                // Created Date
                const SizedBox(height: 12),
                Text(
                  'Diajukan: ${_formatCreatedDate(event['created_at'])}',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
