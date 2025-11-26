import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/shared/widgets/custom_network_image.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';

class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  String _selectedFilter = 'pending';
  List<Map<String, dynamic>> _artworks = [];
  bool _isLoading = true;
  Set<String> _processingArtworks = {};

  @override
  void initState() {
    super.initState();
    _loadArtworks();
  }

  Future<void> _loadArtworks() async {
    setState(() => _isLoading = true);
    try {
      final statusMapping = {
        'pending': ['pending', 'menunggu_persetujuan', 'menunggu'],
        'approved': ['approved', 'disetujui'],
        'rejected': ['rejected', 'ditolak'],
      };
      
      final statusVariants = statusMapping[_selectedFilter] ?? [_selectedFilter];
      
      final response = await Supabase.instance.client
          .from('artworks')
          .select('*')
          .inFilter('status', statusVariants)
          .order('created_at', ascending: false);

      final artworksList = List<Map<String, dynamic>>.from(response as List);

      for (var artwork in artworksList) {
        if (artwork['artist_id'] != null) {
          try {
            final userResponse = await Supabase.instance.client
                .from('users')
                .select('name')
                .eq('id', artwork['artist_id'])
                .maybeSingle();

            if (userResponse != null && userResponse['name'] != null) {
              artwork['artist_username'] = userResponse['name'];
            } else {
              final profileResponse = await Supabase.instance.client
                  .from('profiles')
                  .select('username')
                  .eq('id', artwork['artist_id'])
                  .maybeSingle();

              artwork['artist_username'] = profileResponse?['username'] ?? 'Unknown Artist';
            }
          } catch (e) {
            artwork['artist_username'] = 'Unknown Artist';
          }
        } else {
          artwork['artist_username'] = 'Unknown Artist';
        }
      }

      setState(() {
        _artworks = artworksList;
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

  Future<void> _updateArtworkStatus(String artworkId, String newStatus) async {
    if (_processingArtworks.contains(artworkId)) return;

    setState(() => _processingArtworks.add(artworkId));

    try {
      final idValue = int.tryParse(artworkId) ?? artworkId;
      
      await Supabase.instance.client
          .from('artworks')
          .update({'status': newStatus})
          .eq('id', idValue)
          .select();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Karya berhasil ${newStatus == 'approved' ? 'disetujui' : 'ditolak'}'),
            backgroundColor: newStatus == 'approved' ? Colors.green : Colors.red,
          ),
        );
        
        await _loadArtworks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingArtworks.remove(artworkId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GlassAppBar(
        title: 'Moderasi Karya',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadArtworks,
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
                        _loadArtworks();
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
                        _loadArtworks();
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
                        _loadArtworks();
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Artworks Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                  )
                : _artworks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 80,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada karya ${_selectedFilter}',
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
                            itemCount: _artworks.length,
                            itemBuilder: (context, index) {
                              final artwork = _artworks[index];
                              final artworkId = artwork['id'].toString();
                              final isProcessing = _processingArtworks.contains(artworkId);

                              return _ArtworkCard(
                                artwork: artwork,
                                isProcessing: isProcessing,
                                showActions: _selectedFilter == 'pending',
                                onApprove: () => _updateArtworkStatus(artworkId, 'approved'),
                                onReject: () => _updateArtworkStatus(artworkId, 'rejected'),
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
            Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
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

class _ArtworkCard extends StatefulWidget {
  final Map<String, dynamic> artwork;
  final bool isProcessing;
  final bool showActions;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ArtworkCard({
    required this.artwork,
    required this.isProcessing,
    required this.showActions,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_ArtworkCard> createState() => _ArtworkCardState();
}

class _ArtworkCardState extends State<_ArtworkCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
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
                    imageUrl: widget.artwork['image_url'] ?? '',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Title
              Text(
                widget.artwork['title'] ?? 'Untitled',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Artist
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
                      widget.artwork['artist_username'] ?? 'Unknown',
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
