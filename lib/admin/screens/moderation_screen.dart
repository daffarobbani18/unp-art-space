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

  @override
  void initState() {
    super.initState();
    _loadArtworks();
  }

  Future<void> _loadArtworks() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('artworks')
          .select('*, profiles!inner(username)')
          .eq('status', _selectedFilter)
          .order('created_at', ascending: false);

      setState(() {
        _artworks = List<Map<String, dynamic>>.from(response as List);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateArtworkStatus(String artworkId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('artworks')
          .update({'status': newStatus})
          .eq('id', artworkId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Karya berhasil ${newStatus == 'approved' ? 'disetujui' : 'ditolak'}'),
            backgroundColor: newStatus == 'approved' ? Colors.green : Colors.red,
          ),
        );
        _loadArtworks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteArtwork(String artworkId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Karya', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Apakah Anda yakin ingin menghapus karya ini?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('artworks').delete().eq('id', artworkId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Karya berhasil dihapus'), backgroundColor: Colors.green),
          );
          _loadArtworks();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                    IconButton(
                      onPressed: _loadArtworks,
                      icon: const Icon(Icons.refresh_rounded),
                      style: IconButton.styleFrom(backgroundColor: Colors.grey[100]),
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
                            Text('Tidak ada karya', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 1,
              child: artwork['media_url'] != null
                  ? Image.network(artwork['media_url'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: Icon(Icons.image, size: 48, color: Colors.grey[400])))
                  : Container(color: Colors.grey[200], child: Icon(Icons.image, size: 48, color: Colors.grey[400])),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(artwork['title'] ?? 'Untitled', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('By: ${artwork['profiles']?['username'] ?? 'Unknown'}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  if (_selectedFilter == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateArtworkStatus(artwork['id'], 'approved'),
                            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF059669), padding: const EdgeInsets.symmetric(vertical: 8)),
                            child: Text('Setujui', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateArtworkStatus(artwork['id'], 'rejected'),
                            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFDC2626), padding: const EdgeInsets.symmetric(vertical: 8)),
                            child: Text('Tolak', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
                          ),
                        ),
                      ],
                    )
                  else
                    ElevatedButton(
                      onPressed: () => _deleteArtwork(artwork['id']),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 32)),
                      child: Text('Hapus', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white)),
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
