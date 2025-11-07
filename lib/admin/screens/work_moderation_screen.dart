import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  String _selectedFilter = 'pending';
  List<Map<String, dynamic>> _artworks = [];
  bool _isLoading = true;
  Set<String> _processingArtworks = {}; // Track artworks being processed

  @override
  void initState() {
    super.initState();
    _loadArtworks();
  }

  Future<void> _loadArtworks() async {
    setState(() => _isLoading = true);
    try {
      print('🔍 Loading artworks with status: $_selectedFilter');
      
      // Map status baru ke status lama (backward compatibility)
      final statusMapping = {
        'pending': ['pending', 'menunggu_persetujuan', 'menunggu'],
        'approved': ['approved', 'disetujui'],
        'rejected': ['rejected', 'ditolak'],
      };
      
      final statusVariants = statusMapping[_selectedFilter] ?? [_selectedFilter];
      print('🔎 Searching for status variants: $statusVariants');
      
      // Query semua artworks dulu untuk debugging
      final allArtworks = await Supabase.instance.client
          .from('artworks')
          .select('id, title, status, artist_id, created_at')
          .order('created_at', ascending: false);
      
      print('📊 Total artworks in database: ${(allArtworks as List).length}');
      for (var art in allArtworks) {
        print('  - ${art['title']}: status="${art['status']}", artist_id=${art['artist_id']}');
      }
      
      // Query artworks dengan multiple status (support format lama dan baru)
      final response = await Supabase.instance.client
          .from('artworks')
          .select('*')
          .inFilter('status', statusVariants)
          .order('created_at', ascending: false);

      print('📦 Filtered response for status variants $statusVariants: $response');
      
      // Ambil data artworks
      final artworksList = List<Map<String, dynamic>>.from(response as List);
      print('✅ Found ${artworksList.length} artworks matching status filter');

      // Untuk setiap artwork, ambil data artist dari profiles
      for (var artwork in artworksList) {
        print('🎨 Processing artwork: ${artwork['title']} (ID: ${artwork['id']})');
        if (artwork['artist_id'] != null) {
          try {
            // Coba dulu dari tabel users (untuk kompatibilitas dengan aplikasi utama)
            final userResponse = await Supabase.instance.client
                .from('users')
                .select('name')
                .eq('id', artwork['artist_id'])
                .maybeSingle();

            if (userResponse != null && userResponse['name'] != null) {
              artwork['artist_username'] = userResponse['name'];
              print('👤 Artist (from users): ${artwork['artist_username']}');
            } else {
              // Jika tidak ada di users, coba dari profiles
              final profileResponse = await Supabase.instance.client
                  .from('profiles')
                  .select('username')
                  .eq('id', artwork['artist_id'])
                  .maybeSingle();

              if (profileResponse != null) {
                artwork['artist_username'] = profileResponse['username'];
                print('👤 Artist (from profiles): ${artwork['artist_username']}');
              } else {
                artwork['artist_username'] = 'Unknown Artist';
                print('⚠️ Profile not found in both users and profiles for artist_id: ${artwork['artist_id']}');
              }
            }
          } catch (e) {
            artwork['artist_username'] = 'Unknown Artist';
            print('❌ Error fetching profile: $e');
          }
        } else {
          artwork['artist_username'] = 'Unknown Artist';
          print('⚠️ No artist_id in artwork');
        }
      }

      setState(() {
        _artworks = artworksList;
        _isLoading = false;
      });
      
      print('✨ Loading complete. Total artworks: ${_artworks.length}');
    } catch (e) {
      print('❌ Error loading artworks: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateArtworkStatus(String artworkId, String newStatus) async {
    // Prevent multiple clicks
    if (_processingArtworks.contains(artworkId)) {
      print('⚠️ Artwork $artworkId is already being processed');
      return;
    }

    setState(() => _processingArtworks.add(artworkId));

    try {
      print('🔄 Updating artwork $artworkId to status: $newStatus');
      
      // Parse ID - handle both String and numeric IDs
      final dynamic idValue = int.tryParse(artworkId) ?? artworkId;
      
      final response = await Supabase.instance.client
          .from('artworks')
          .update({'status': newStatus})
          .eq('id', idValue)
          .select();

      print('✅ Update response: $response');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Karya berhasil ${newStatus == 'approved' ? 'disetujui' : 'ditolak'}'),
            backgroundColor: newStatus == 'approved' ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Reload data setelah update
        await _loadArtworks();
      }
    } catch (e) {
      print('❌ Error updating artwork: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupdate karya: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingArtworks.remove(artworkId));
      }
    }
  }

  Future<void> _deleteArtwork(String artworkId) async {
    // Prevent multiple clicks
    if (_processingArtworks.contains(artworkId)) {
      print('⚠️ Artwork $artworkId is already being processed');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Karya', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Apakah Anda yakin ingin menghapus karya ini secara permanen?', style: GoogleFonts.poppins()),
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
      setState(() => _processingArtworks.add(artworkId));

      try {
        print('🗑️ Deleting artwork: $artworkId');
        
        // Parse ID - handle both String and numeric IDs
        final dynamic idValue = int.tryParse(artworkId) ?? artworkId;
        
        final response = await Supabase.instance.client
            .from('artworks')
            .delete()
            .eq('id', idValue)
            .select();

        print('✅ Delete response: $response');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Karya berhasil dihapus'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Reload data setelah delete
          await _loadArtworks();
        }
      } catch (e) {
        print('❌ Error deleting artwork: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus karya: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _processingArtworks.remove(artworkId));
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
                        Text('Moderasi Karya', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
                        Text('Kelola dan review karya seni', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                    Row(
                      children: [
                        // Debug button
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final all = await Supabase.instance.client.from('artworks').select('*');
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Debug: All Artworks', style: GoogleFonts.poppins()),
                                  content: SingleChildScrollView(
                                    child: Text('Total: ${(all as List).length}\n\n${all.map((a) => 'Title: ${a['title']}\nStatus: ${a['status']}\nArtist ID: ${a['artist_id']}\n---').join('\n')}'),
                                  ),
                                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))],
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          },
                          icon: Icon(Icons.bug_report, size: 18),
                          label: Text('Debug', style: GoogleFonts.poppins(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _loadArtworks,
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
                    _buildFilterChip('Menunggu', 'pending', Color(0xFFEA580C)),
                    const SizedBox(width: 8),
                    _buildFilterChip('Disetujui', 'approved', Color(0xFF059669)),
                    const SizedBox(width: 8),
                    _buildFilterChip('Ditolak', 'rejected', Color(0xFFDC2626)),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _artworks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Tidak ada karya dengan status "$_selectedFilter"', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
                            const SizedBox(height: 8),
                            Text('Klik tombol Debug untuk melihat semua data', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _artworks.length,
                        itemBuilder: (context, index) => _buildArtworkCard(_artworks[index]),
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
        _loadArtworks();
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

  Widget _buildArtworkCard(Map<String, dynamic> artwork) {
    // Safe type casting - handle both int and String IDs
    final artworkId = artwork['id'].toString();
    final isProcessing = _processingArtworks.contains(artworkId);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with processing overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: artwork['media_url'] != null
                      ? Image.network(
                          artwork['media_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.image, size: 48, color: Colors.grey[400]),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.image, size: 48, color: Colors.grey[400]),
                        ),
                ),
              ),
              // Processing overlay
              if (isProcessing)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(artwork['title'] ?? 'Untitled', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('By: ${artwork['artist_username'] ?? 'Unknown'}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  if (_selectedFilter == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isProcessing ? null : () => _updateArtworkStatus(artworkId, 'approved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF059669),
                              disabledBackgroundColor: Colors.grey[300],
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: isProcessing
                                ? SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[600]),
                                  )
                                : Text('Setujui', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isProcessing ? null : () => _updateArtworkStatus(artworkId, 'rejected'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFDC2626),
                              disabledBackgroundColor: Colors.grey[300],
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: isProcessing
                                ? SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[600]),
                                  )
                                : Text('Tolak', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
                          ),
                        ),
                      ],
                    )
                  else
                    ElevatedButton(
                      onPressed: isProcessing ? null : () => _deleteArtwork(artworkId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        disabledBackgroundColor: Colors.grey[300],
                        minimumSize: const Size(double.infinity, 32),
                      ),
                      child: isProcessing
                          ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[600]),
                            )
                          : Text('Hapus', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
