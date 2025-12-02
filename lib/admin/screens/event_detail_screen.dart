import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../app/shared/widgets/custom_network_image.dart';
import '../models/event_model.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventDetailScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isProcessing = false;
  late EventModel _currentEvent;
  Map<String, dynamic>? _organizerDetails;
  bool _isLoadingOrganizer = true;
  int _submissionsCount = 0;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _loadOrganizerDetails();
    _loadSubmissionsCount();
  }

  Future<void> _loadOrganizerDetails() async {
    if (_currentEvent.organizerId == null) {
      setState(() => _isLoadingOrganizer = false);
      return;
    }

    try {
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('name, email, profile_image_url, bio, specialization')
          .eq('id', _currentEvent.organizerId!)
          .maybeSingle();

      setState(() {
        _organizerDetails = userResponse;
        _isLoadingOrganizer = false;
      });
    } catch (e) {
      setState(() => _isLoadingOrganizer = false);
    }
  }

  Future<void> _loadSubmissionsCount() async {
    try {
      final response = await Supabase.instance.client
          .from('event_submissions')
          .select('id')
          .eq('event_id', _currentEvent.id);

      setState(() {
        _submissionsCount = (response as List).length;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _updateEventStatus(String newStatus, {String? rejectionReason}) async {
    setState(() => _isProcessing = true);

    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
      };

      if (rejectionReason != null) {
        updateData['rejection_reason'] = rejectionReason;
      }

      await Supabase.instance.client
          .from('events')
          .update(updateData)
          .eq('id', _currentEvent.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event berhasil ${newStatus == 'approved' ? 'disetujui' : 'ditolak'}'),
            backgroundColor: newStatus == 'approved' ? const Color(0xFF4CAF50) : const Color(0xFFFF6584),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate status changed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF6584),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showRejectDialog() {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E1E2C).withOpacity(0.95),
                const Color(0xFF2D2D3A).withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6584), Color(0xFFFFA726)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.cancel, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Tolak Event',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Alasan Penolakan',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonController,
                  maxLines: 4,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Masukkan alasan penolakan event ini...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.3),
                    ),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GlassButton(
                      text: 'Tolak Event',
                      onPressed: () {
                        Navigator.pop(context);
                        _updateEventStatus('rejected', rejectionReason: reasonController.text);
                      },
                      type: GlassButtonType.danger,
                      icon: Icons.cancel,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tanggal tidak tersedia';
    try {
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      // Fallback jika locale Indonesia tidak tersedia
      return DateFormat('EEEE, dd MMMM yyyy').format(date);
    }
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('HH:mm').format(date);
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? const Color(0xFF6366F1)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? const Color(0xFF6366F1),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: GlassAppBar(
        title: 'Detail Event',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1400 : double.infinity,
            ),
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            child: isDesktop
                ? _buildDesktopLayout()
                : _buildMobileLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column - Image & Details
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEventImage(),
              const SizedBox(height: 24),
              _buildEventContent(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right Column - Info & Actions
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 16),
              _buildEventInfoCard(),
              const SizedBox(height: 16),
              _buildOrganizerCard(),
              const SizedBox(height: 16),
              _buildStatsCard(),
              if (_currentEvent.isPending) ...[
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
              if (_currentEvent.rejectionReason != null) ...[
                const SizedBox(height: 16),
                _buildRejectionReasonCard(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildEventImage(),
        const SizedBox(height: 16),
        _buildStatusCard(),
        const SizedBox(height: 16),
        _buildEventInfoCard(),
        const SizedBox(height: 16),
        _buildEventContent(),
        const SizedBox(height: 16),
        _buildOrganizerCard(),
        const SizedBox(height: 16),
        _buildStatsCard(),
        if (_currentEvent.isPending) ...[
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
        if (_currentEvent.rejectionReason != null) ...[
          const SizedBox(height: 16),
          _buildRejectionReasonCard(),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEventImage() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: CustomNetworkImage(
            imageUrl: _currentEvent.imageUrl ?? '',
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;

    if (_currentEvent.isPending) {
      statusColor = const Color(0xFFFFA726);
      statusIcon = Icons.pending_actions;
    } else if (_currentEvent.isApproved) {
      statusColor = const Color(0xFF4CAF50);
      statusIcon = Icons.check_circle;
    } else {
      statusColor = const Color(0xFFFF6584);
      statusIcon = Icons.cancel;
    }

    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Event',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentEvent.statusDisplayText,
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfoCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Informasi Event',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            Icons.event,
            'Tanggal Event',
            _formatDate(_currentEvent.eventDate),
          ),
          if (_currentEvent.eventDate != null)
            _buildInfoRow(
              Icons.access_time,
              'Waktu',
              _formatTime(_currentEvent.eventDate),
            ),
          _buildInfoRow(
            Icons.location_on,
            'Lokasi',
            _currentEvent.location ?? 'Tidak ada lokasi',
          ),
          _buildInfoRow(
            Icons.calendar_today,
            'Dibuat pada',
            _formatDate(_currentEvent.createdAt),
            iconColor: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildEventContent() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentEvent.title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Deskripsi',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentEvent.content ?? 'Tidak ada deskripsi',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Penyelenggara',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoadingOrganizer)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            )
          else if (_organizerDetails != null) ...[
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: CustomNetworkImage(
                    imageUrl: _organizerDetails!['profile_image_url'] ?? '',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _organizerDetails!['name'] ?? _currentEvent.organizerName ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_organizerDetails!['email'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _organizerDetails!['email'],
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (_organizerDetails!['specialization'] != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _organizerDetails!['specialization'],
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF6366F1),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (_organizerDetails!['bio'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _organizerDetails!['bio'],
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ] else
            Text(
              _currentEvent.organizerName ?? 'Unknown Organizer',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Statistik',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1).withOpacity(0.1),
                  const Color(0xFF8B5CF6).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.send,
                  'Submissions',
                  _submissionsCount.toString(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6366F1), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRejectionReasonCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6584), Color(0xFFFFA726)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Alasan Penolakan',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6584).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF6584).withOpacity(0.3),
              ),
            ),
            child: Text(
              _currentEvent.rejectionReason!,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tindakan',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GlassButton(
            text: 'Setujui Event',
            onPressed: _isProcessing ? () {} : () => _updateEventStatus('approved'),
            type: GlassButtonType.success,
            icon: Icons.check_circle,
            isLoading: _isProcessing,
            isFullWidth: true,
          ),
          const SizedBox(height: 12),
          GlassButton(
            text: 'Tolak Event',
            onPressed: _isProcessing ? () {} : _showRejectDialog,
            type: GlassButtonType.danger,
            icon: Icons.cancel,
            isLoading: _isProcessing,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}
