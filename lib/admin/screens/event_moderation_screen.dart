import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../app/shared/widgets/custom_network_image.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';
import '../models/event_model.dart';
import 'event_detail_screen.dart';

class EventModerationScreen extends StatefulWidget {
  const EventModerationScreen({super.key});

  @override
  State<EventModerationScreen> createState() => _EventModerationScreenState();
}

class _EventModerationScreenState extends State<EventModerationScreen> {
  String _selectedFilter = 'pending';
  List<EventModel> _events = [];
  bool _isLoading = true;
  final Set<String> _processingEvents = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final statusMapping = {
        'pending': ['pending', 'menunggu_persetujuan', 'menunggu'],
        'approved': ['approved', 'disetujui'],
        'rejected': ['rejected', 'ditolak'],
      };
      
      final statusVariants = statusMapping[_selectedFilter] ?? [_selectedFilter];
      
      final response = await Supabase.instance.client
          .from('events')
          .select('*')
          .inFilter('status', statusVariants)
          .order('created_at', ascending: false);

      final eventsList = List<Map<String, dynamic>>.from(response as List);

      for (var event in eventsList) {
        if (event['organizer_id'] != null) {
          try {
            final userResponse = await Supabase.instance.client
                .from('users')
                .select('name')
                .eq('id', event['organizer_id'])
                .maybeSingle();

            if (userResponse != null && userResponse['name'] != null) {
              event['organizer_name'] = userResponse['name'];
            } else {
              final profileResponse = await Supabase.instance.client
                  .from('profiles')
                  .select('username')
                  .eq('id', event['organizer_id'])
                  .maybeSingle();

              event['organizer_name'] = profileResponse?['username'] ?? 'Unknown Organizer';
            }
          } catch (e) {
            event['organizer_name'] = 'Unknown Organizer';
          }
        } else {
          event['organizer_name'] = 'Unknown Organizer';
        }
      }

      setState(() {
        _events = eventsList.map((e) => EventModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateEventStatus(String eventId, String newStatus) async {
    if (_processingEvents.contains(eventId)) return;

    setState(() => _processingEvents.add(eventId));

    try {
      await Supabase.instance.client
          .from('events')
          .update({'status': newStatus})
          .eq('id', eventId)
          .select();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event berhasil ${newStatus == 'approved' ? 'disetujui' : 'ditolak'}'),
            backgroundColor: newStatus == 'approved' ? Colors.green : Colors.red,
          ),
        );
        
        await _loadEvents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingEvents.remove(eventId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: 'Moderasi Event',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: _FilterTab(
                      label: 'Pending',
                      icon: Icons.pending_actions,
                      isSelected: _selectedFilter == 'pending',
                      onTap: () => setState(() {
                        _selectedFilter = 'pending';
                        _loadEvents();
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterTab(
                      label: 'Approved',
                      icon: Icons.check_circle,
                      isSelected: _selectedFilter == 'approved',
                      onTap: () => setState(() {
                        _selectedFilter = 'approved';
                        _loadEvents();
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterTab(
                      label: 'Rejected',
                      icon: Icons.cancel,
                      isSelected: _selectedFilter == 'rejected',
                      onTap: () => setState(() {
                        _selectedFilter = 'rejected';
                        _loadEvents();
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Events Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                  )
                : _events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 80,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada event $_selectedFilter',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = constraints.maxWidth > 1400
                              ? 4
                              : constraints.maxWidth > 1000
                                  ? 3
                                  : constraints.maxWidth > 600
                                      ? 2
                                      : 1;
                          return GridView.builder(
                            padding: const EdgeInsets.all(24),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: _events.length,
                            itemBuilder: (context, index) {
                              final event = _events[index];
                              final isProcessing = _processingEvents.contains(event.id);

                              return _EventCard(
                                event: event,
                                isProcessing: isProcessing,
                                showActions: _selectedFilter == 'pending',
                                onApprove: () => _updateEventStatus(event.id, 'approved'),
                                onReject: () => _updateEventStatus(event.id, 'rejected'),
                                onTap: () => _openEventDetail(event),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEventDetail(EventModel event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(event: event),
      ),
    );

    // Reload events if status was changed
    if (result == true) {
      _loadEvents();
    }
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                )
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatefulWidget {
  final EventModel event;
  final bool isProcessing;
  final bool showActions;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.isProcessing,
    required this.showActions,
    required this.onApprove,
    required this.onReject,
    required this.onTap,
  });

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _isHovered = false;

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tanggal tidak tersedia';
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  Color _getStatusColor() {
    if (widget.event.isPending) return const Color(0xFFFFA726);
    if (widget.event.isApproved) return const Color(0xFF4CAF50);
    return const Color(0xFFFF6584);
  }

  IconData _getStatusIcon() {
    if (widget.event.isPending) return Icons.pending_actions;
    if (widget.event.isApproved) return Icons.check_circle;
    return Icons.cancel;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: widget.onTap,
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomNetworkImage(
                      imageUrl: widget.event.imageUrl ?? '',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Title
                Text(
                  widget.event.title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                // Organizer
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: Colors.white54,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.event.organizerName ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                // Date
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white54,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _formatDate(widget.event.eventDate),
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                // Location
                if (widget.event.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white54,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.event.location!,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                
                if (widget.showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GlassButton(
                          text: 'Approve',
                          onPressed: widget.isProcessing ? () {} : widget.onApprove,
                          type: GlassButtonType.success,
                          icon: Icons.check,
                          isLoading: widget.isProcessing,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GlassButton(
                          text: 'Reject',
                          onPressed: widget.isProcessing ? () {} : widget.onReject,
                          type: GlassButtonType.danger,
                          icon: Icons.close,
                          isLoading: widget.isProcessing,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _getStatusColor().withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getStatusIcon(), color: _getStatusColor(), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          widget.event.statusDisplayText,
                          style: GoogleFonts.poppins(
                            color: _getStatusColor(),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
