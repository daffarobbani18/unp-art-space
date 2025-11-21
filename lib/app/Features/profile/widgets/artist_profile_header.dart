import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/widgets/custom_network_image.dart';

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
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: CustomNetworkImage(
                imageUrl: 'https://picsum.photos/seed/${widget.artistId}/800/400',
                fit: BoxFit.cover,
                borderRadius: 0,
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
                child: GestureDetector(
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
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
        if (widget.isOwnProfile)
          Padding(
            padding: const EdgeInsets.only(right: 140.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Material(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                color: Colors.white,
                child: InkWell(
                  onTap: () {
                    if (_kDebugCameraArea) debugPrint('Camera button tapped!');
                    if (!_isProcessing) _showAvatarOptions();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isProcessing)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.grey,
                          ),
                        //const SizedBox(width: 8),
                        // Text(
                        //   _isProcessing ? 'Memproses...' : '',
                        //   style: GoogleFonts.poppins(
                        //     fontSize: 14,
                        //     fontWeight: FontWeight.w500,
                        //     color: Colors.grey[800],
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
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

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _showFullImage() async {
    if (_profileImageUrl == null || !mounted) return;
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
                  child: CustomNetworkImage(
                    imageUrl: _profileImageUrl!,
                    fit: BoxFit.contain,
                    borderRadius: 0,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
