import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'event_detail_screen.dart';

class EventModerationScreen extends StatefulWidget {
  const EventModerationScreen({super.key});

  @override
  State<EventModerationScreen> createState() => _EventModerationScreenState();
}

class _EventModerationScreenState extends State<EventModerationScreen> {
  String _selectedFilter = 'pending';
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  Set<String> _processingEvents = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      print('🔍 Loading events with status: $_selectedFilter');
      
      // Map status baru ke status lama (backward compatibility)
      final statusMapping = {
        'pending': ['pending', 'menunggu_persetujuan', 'menunggu'],
        'approved': ['approved', 'disetujui'],
        'rejected': ['rejected', 'ditolak'],
      };
      
      final statusVariants = statusMapping[_selectedFilter] ?? [_selectedFilter];
      print('🔎 Searching for status variants: $statusVariants');
      
      // Query semua events dulu untuk debugging
      final allEvents = await Supabase.instance.client
          .from('events')
          .select('id, title, status, artist_id, created_at')
          .order('created_at', ascending: false);
      
      print('📊 Total events in database: ${(allEvents as List).length}');
      for (var event in allEvents) {
        print('  - ${event['title']}: status="${event['status']}", artist_id=${event['artist_id']}');
      }
      
      // Query events dengan multiple status
      final response = await Supabase.instance.client
          .from('events')
          .select('*')
          .inFilter('status', statusVariants)
          .order('created_at', ascending: false);

      print('📦 Filtered response for status variants $statusVariants: $response');
      
      // Ambil data events
      final eventsList = List<Map<String, dynamic>>.from(response as List);
      print('✅ Found ${eventsList.length} events matching status filter');

      // Untuk setiap event, ambil data artist
      for (var event in eventsList) {
        print('🎉 Processing event: ${event['title']} (ID: ${event['id']})');
        if (event['artist_id'] != null) {
          try {
            final userResponse = await Supabase.instance.client
                .from('users')
                .select('name')
                .eq('id', event['artist_id'])
                .maybeSingle();

            if (userResponse != null && userResponse['name'] != null) {
              event['artist_name'] = userResponse['name'];
              print('👤 Artist (from users): ${event['artist_name']}');
            } else {
              final profileResponse = await Supabase.instance.client
                  .from('profiles')
                  .select('username')
                  .eq('id', event['artist_id'])
                  .maybeSingle();

              if (profileResponse != null) {
                event['artist_name'] = profileResponse['username'];
                print('👤 Artist (from profiles): ${event['artist_name']}');
              } else {
                event['artist_name'] = 'Unknown Artist';
                print('⚠️ Profile not found for artist_id: ${event['artist_id']}');
              }
            }
          } catch (e) {
            event['artist_name'] = 'Unknown Artist';
            print('❌ Error fetching profile: $e');
          }
        } else {
          event['artist_name'] = 'Unknown Artist';
          print('⚠️ No artist_id in event');
        }
      }

      setState(() {
        _events = eventsList;
        _isLoading = false;
      });
      
      print('✨ Loading complete. Total events: ${_events.length}');
    } catch (e) {
      print('❌ Error loading events: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateEventStatus(String eventId, String newStatus, {String? rejectionReason}) async {
    if (_processingEvents.contains(eventId)) {
      print('⚠️ Event $eventId is already being processed');
      return;
    }

    setState(() => _processingEvents.add(eventId));

    try {
      print('🔄 Updating event $eventId to status: $newStatus');
      
      final dynamic idValue = int.tryParse(eventId) ?? eventId;
      
      final updateData = {
        'status': newStatus,
        if (rejectionReason != null) 'rejection_reason': rejectionReason,
      };
      
      final response = await Supabase.instance.client
          .from('events')
          .update(updateData)
          .eq('id', idValue)
          .select();

      print('✅ Update response: $response');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event berhasil ${newStatus == 'approved' ? 'disetujui' : 'ditolak'}'),
            backgroundColor: newStatus == 'approved' ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        
        await _loadEvents();
      }
    } catch (e) {
      print('❌ Error updating event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupdate event: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingEvents.remove(eventId));
      }
    }
  }

  Future<void> _showRejectDialog(String eventId) async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tolak Event', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Berikan alasan penolakan:', style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Contoh: Tanggal event sudah lewat, informasi tidak lengkap, dll.',
                hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Tolak Event', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (result == true && reasonController.text.trim().isNotEmpty) {
      await _updateEventStatus(eventId, 'rejected', rejectionReason: reasonController.text.trim());
    } else if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alasan penolakan wajib diisi'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    if (_processingEvents.contains(eventId)) {
      print('⚠️ Event $eventId is already being processed');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Event', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Apakah Anda yakin ingin menghapus event ini secara permanen?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Hapus', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _processingEvents.add(eventId));

      try {
        print('🗑️ Deleting event: $eventId');
        
        final dynamic idValue = int.tryParse(eventId) ?? eventId;
        
        final response = await Supabase.instance.client
            .from('events')
            .delete()
            .eq('id', idValue)
            .select();

        print('✅ Delete response: $response');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event berhasil dihapus'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          await _loadEvents();
        }
      } catch (e) {
        print('❌ Error deleting event: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus event: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _processingEvents.remove(eventId));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Moderasi Event', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
                        Text('Kelola dan review event yang diusulkan artist', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final all = await Supabase.instance.client.from('events').select('*');
                              if (mounted) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Debug: All Events', style: GoogleFonts.poppins()),
                                    content: SingleChildScrollView(
                                      child: Text('Total: ${(all as List).length}\n\n${all.map((e) => 'Title: ${e['title']}\nStatus: ${e['status']}\nDate: ${e['event_date']}\n---').join('\n')}'),
                                    ),
                                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                          icon: const Icon(Icons.bug_report, size: 18),
                          label: Text('Debug', style: GoogleFonts.poppins(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _loadEvents,
                          icon: const Icon(Icons.refresh_rounded),
                          style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Filter Tabs
                Row(
                  children: [
                    _buildFilterChip('Menunggu', 'pending', const Color(0xFFEA580C)),
                    const SizedBox(width: 8),
                    _buildFilterChip('Disetujui', 'approved', const Color(0xFF059669)),
                    const SizedBox(width: 8),
                    _buildFilterChip('Ditolak', 'rejected', const Color(0xFFDC2626)),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Tidak ada event dengan status "$_selectedFilter"', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
                            const SizedBox(height: 8),
                            Text('Klik tombol Debug untuk melihat semua data', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _events.length,
                        itemBuilder: (context, index) => _buildEventCard(_events[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = value);
        _loadEvents();
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
    final eventId = event['id'].toString();
    final isProcessing = _processingEvents.contains(eventId);
    final eventDate = event['event_date'] != null 
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(event['event_date']))
        : 'Tanggal belum ditentukan';

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(
              event: event,
              onEventUpdated: _loadEvents,
            ),
          ),
        );
        
        if (result == true) {
          _loadEvents(); // Refresh list jika ada perubahan
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan gambar
            if (event['image_url'] != null)
              Stack(
                children: [
                  Hero(
                    tag: 'event_${event['id']}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        event['image_url'],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Icon(Icons.event, size: 64, color: Colors.grey[400]),
                        ),
                      ),
                    ),
                  ),
                  if (isProcessing)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  event['title'] ?? 'Untitled Event',
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Artist & Date Info
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'By: ${event['artist_name'] ?? 'Unknown'}',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        eventDate,
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Location
                if (event['location'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event['location'],
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Content Preview
                if (event['content'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    event['content'],
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Rejection Reason (if rejected)
                if (_selectedFilter == 'rejected' && event['rejection_reason'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
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
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          event['rejection_reason'],
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.red[900]),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action Buttons
                if (_selectedFilter == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isProcessing ? null : () => _updateEventStatus(eventId, 'approved'),
                          icon: isProcessing
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_outline, size: 18),
                          label: Text('Setujui', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isProcessing ? null : () => _showRejectDialog(eventId),
                          icon: isProcessing
                              ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[600]))
                              : const Icon(Icons.cancel_outlined, size: 18),
                          label: Text('Tolak', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  ElevatedButton.icon(
                    onPressed: isProcessing ? null : () => _deleteEvent(eventId),
                    icon: isProcessing
                        ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[600]))
                        : const Icon(Icons.delete_outline, size: 18),
                    label: Text('Hapus Event', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
