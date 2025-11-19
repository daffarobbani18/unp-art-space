import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Toggle this to true to show a visible debug border and console logs for the camera button
const bool _kDebugCameraArea = true;

class ArtistProfileHeader extends StatefulWidget {
  final String role;
  final String artistId;
  final String name;
  final String specialization;
  final String bio;
  final int artworkCount;
  final int likesReceived;
  final Map<String, dynamic> socialMedia;
  final bool isOwnProfile;
  final VoidCallback? onEditProfile;
  final VoidCallback onProfileUpdated;

  const ArtistProfileHeader({
    super.key,
    required this.role,
    required this.artistId,
    required this.name,
    required this.specialization,
    required this.bio,
    required this.artworkCount,
    required this.likesReceived,
    required this.socialMedia,
    this.isOwnProfile = false,
    this.onEditProfile,
    required this.onProfileUpdated,
    required Map userData,
  });

  static const Color deepBlue = Color(0xFF1E3A8A);
  static const Color vibrantPurple = Color(0xFF9333EA);

  @override
  State<ArtistProfileHeader> createState() => _ArtistProfileHeaderState();
}

class _ArtistProfileHeaderState extends State<ArtistProfileHeader> {
  late final SupabaseClient _supabase;
  bool _isProcessing = false;
  String? _profileImageUrl;
  final GlobalKey _cameraKey = GlobalKey();
  OverlayEntry? _cameraOverlayEntry;
  Offset? _cameraGlobalTopLeft;
  Size? _cameraGlobalSize;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    try {
      final res = await _supabase
          .from('users')
          .select('profile_image_url')
          .eq('id', widget.artistId)
          .single();
      if (res != null && res is Map<String, dynamic>) {
        final url = res['profile_image_url'] as String?;
        if (mounted) {
          setState(() => _profileImageUrl = url);
        }
      }
    } catch (_) {
      // ignore loading errors silently
    }
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    var normalizedUrl = urlString;
    if (!normalizedUrl.startsWith('http://') &&
        !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'https://$normalizedUrl';
    }
    final Uri url = Uri.parse(normalizedUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // ignore failure
    }
  }

  Future<void> _uploadAvatar() async {
    if (_kDebugCameraArea) debugPrint('uploadAvatar: started');
    setState(() => _isProcessing = true);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 600,
      );
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      final fileExt = pickedFile.path.split('.').last;
      final fileName = '${widget.artistId}/profile.$fileExt';

      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      await _supabase
          .from('users')
          .update({'profile_image_url': publicUrl})
          .eq('id', widget.artistId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diperbarui')),
      );
      await _loadProfileImage();
      widget.onProfileUpdated();
    } catch (e) {
      if (!mounted) return;
      if (_kDebugCameraArea) debugPrint('uploadAvatar: error $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengunggah foto: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteAvatar() async {
    if (_kDebugCameraArea) debugPrint('deleteAvatar: started');
    setState(() => _isProcessing = true);
    try {
      final res = await _supabase
          .from('users')
          .select('profile_image_url')
          .eq('id', widget.artistId)
          .single();
      String? currentUrl;
      if (res != null && res is Map<String, dynamic>) {
        currentUrl = res['profile_image_url'] as String?;
      }

      await _supabase
          .from('users')
          .update({'profile_image_url': null})
          .eq('id', widget.artistId);

      if (currentUrl != null && currentUrl.isNotEmpty) {
        final pathToRemove = currentUrl.split('/avatars/').last;
        await _supabase.storage.from('avatars').remove([pathToRemove]);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto profil dihapus')));
      setState(() => _profileImageUrl = null);
      widget.onProfileUpdated();
    } catch (e) {
      if (!mounted) return;
      if (_kDebugCameraArea) debugPrint('deleteAvatar: error $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menghapus foto: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showAvatarOptions() async {
    if (!mounted) return;
    if (_kDebugCameraArea)
      debugPrint(
        'showAvatarOptions: called, profileImageUrl=$_profileImageUrl',
      );
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Unggah Foto'),
              onTap: () {
                Navigator.of(context).pop();
                if (_kDebugCameraArea)
                  debugPrint('showAvatarOptions: Unggah Foto tapped');
                _uploadAvatar();
              },
            ),
            if (_profileImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Hapus Foto'),
                onTap: () {
                  Navigator.of(context).pop();
                  if (_kDebugCameraArea)
                    debugPrint('showAvatarOptions: Hapus Foto tapped');
                  _deleteAvatar();
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Batal'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_kDebugCameraArea)
      debugPrint(
        'ArtistProfileHeader.build: isOwnProfile=${widget.isOwnProfile} profileImageUrl=$_profileImageUrl',
      );
    if (_kDebugCameraArea) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final ctx = _cameraKey.currentContext;
          if (ctx != null) {
            final box = ctx.findRenderObject() as RenderBox?;
            if (box != null && box.hasSize) {
              final topLeft = box.localToGlobal(Offset.zero);
              final size = box.size;
              // store for overlay
              _cameraGlobalTopLeft = topLeft;
              _cameraGlobalSize = size;
              debugPrint('cameraRect: topLeft=$topLeft size=$size');
              _ensureCameraOverlay();
            } else {
              debugPrint('cameraRect: box null or has no size');
              _removeCameraOverlay();
            }
          } else {
            debugPrint('cameraRect: _cameraKey.currentContext is null');
            _removeCameraOverlay();
          }
        } catch (e) {
          debugPrint('cameraRect: error $e');
        }
      });
    } else {
      // Even if debug disabled, still update overlay position each frame so overlay stays aligned
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final ctx = _cameraKey.currentContext;
          if (ctx != null) {
            final box = ctx.findRenderObject() as RenderBox?;
            if (box != null && box.hasSize) {
              _cameraGlobalTopLeft = box.localToGlobal(Offset.zero);
              _cameraGlobalSize = box.size;
              _ensureCameraOverlay();
            } else {
              _removeCameraOverlay();
            }
          } else {
            _removeCameraOverlay();
          }
        } catch (_) {}
      });
    }
    return Column(
      children: [
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            if (_kDebugCameraArea)
              debugPrint(
                'ArtistProfileHeader.PointerDown at ${event.localPosition} global=${event.position}',
              );
          },
          onPointerUp: (event) {
            if (_kDebugCameraArea)
              debugPrint(
                'ArtistProfileHeader.PointerUp at ${event.localPosition} global=${event.position}',
              );
          },
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[200],
                child: Image.network(
                  'https://picsum.photos/seed/${widget.artistId}/800/400',
                  fit: BoxFit.cover,
                ),
              ),
              if (!widget.isOwnProfile)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.4),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              Positioned(
                top: 140,
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: _showFullImage,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : null,
                            child: _profileImageUrl == null
                                ? Text(
                                    widget.name.isNotEmpty
                                        ? widget.name[0].toUpperCase()
                                        : 'U',
                                    style: GoogleFonts.poppins(
                                      fontSize: 50,
                                      fontWeight: FontWeight.bold,
                                      color: ArtistProfileHeader.deepBlue,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      if (widget.isOwnProfile)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            key: _cameraKey,
                            // debug border to visualize the tappable area when enabled
                            decoration: _kDebugCameraArea
                                ? BoxDecoration(
                                    shape: BoxShape.circle,
                                    //border: Border.all(color: Colors.redAccent, width: 2),
                                  )
                                : null,
                            // keep original placeholder but ignore pointers so overlay handles taps
                            child: IgnorePointer(
                              ignoring: true,
                              child: Material(
                                elevation: 2,
                                shape: const CircleBorder(),
                                clipBehavior: Clip.antiAlias,
                                color: Colors.white,
                                child: SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Center(
                                    child: _isProcessing
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 70),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Text(
                widget.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.specialization,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              if (widget.role == 'artist')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${widget.artworkCount}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Karya',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 30,
                      child: VerticalDivider(color: Colors.white24),
                    ),
                    Column(
                      children: [
                        Text(
                          '${widget.likesReceived}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Suka Diterima',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              Text(
                widget.bio,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[300],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.role == 'artist' && widget.socialMedia.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.socialMedia['instagram'] != null)
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.instagram,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            _launchURL(widget.socialMedia['instagram']),
                      ),
                    if (widget.socialMedia['behance'] != null)
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.behance,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            _launchURL(widget.socialMedia['behance']),
                      ),
                    if (widget.socialMedia['youtube'] != null)
                      IconButton(
                        icon: const FaIcon(
                          FontAwesomeIcons.youtube,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            _launchURL(widget.socialMedia['youtube']),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _ensureCameraOverlay() {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    // If overlay exists and position hasn't changed, do nothing
    if (_cameraOverlayEntry != null) {
      // rebuild to update position
      _cameraOverlayEntry!.markNeedsBuild();
      return;
    }

    _cameraOverlayEntry = OverlayEntry(
      builder: (context) {
        if (_cameraGlobalTopLeft == null || _cameraGlobalSize == null)
          return const SizedBox.shrink();
        final topLeft = _cameraGlobalTopLeft!;
        final size = _cameraGlobalSize!;

        return Positioned(
          left: topLeft.dx,
          top: topLeft.dy,
          width: size.width,
          height: size.height,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 24,
              icon: const Icon(
                Icons.camera_alt,
                color: ArtistProfileHeader.deepBlue,
              ),
              onPressed: () {
                if (_kDebugCameraArea)
                  debugPrint('overlay camera IconButton.onPressed called');
                _showAvatarOptions();
              },
            ),
          ),
        );
      },
    );

    overlay.insert(_cameraOverlayEntry!);
  }

  void _removeCameraOverlay() {
    try {
      _cameraOverlayEntry?.remove();
    } catch (_) {}
    _cameraOverlayEntry = null;
  }

  @override
  void dispose() {
    _removeCameraOverlay();
    super.dispose();
  }

  Future<void> _showFullImage() async {
    if (_profileImageUrl == null || !mounted) return;
    // remove overlay so it doesn't stay visible above the dialog
    _removeCameraOverlay();
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      pageBuilder: (context, anim1, anim2) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Material(
            color: Colors.black,
            child: SafeArea(
              child: Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Image.network(
                    _profileImageUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, err, st) => const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // restore overlay after dialog is dismissed
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCameraOverlay();
    });
  }
}
