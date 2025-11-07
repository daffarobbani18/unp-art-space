import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/app_animations.dart';

class UploadArtworkPage extends StatefulWidget {
  const UploadArtworkPage({Key? key}) : super(key: key);

  @override
  State<UploadArtworkPage> createState() => _UploadArtworkPageState();
}

class _UploadArtworkPageState extends State<UploadArtworkPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  String? _selectedKategori;
  // List kategori yang diperbarui
  final List<String> _kategoriList = [
    'Lukisan',
    'Fotografi',
    'Patung',
    'Digital Art',
    'Kerajinan',
    'Musik',
    'Film',
    'Lainnya',
  ];

  // Untuk preview media
  File? _selectedMediaFile;
  File? _selectedThumbnailFile;
  String? _selectedMediaType; // 'image' or 'video'
  bool _isUploading = false;

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih gambar dari galeri
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedMediaFile = File(pickedFile.path);
          _selectedMediaType = 'image';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih gambar: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        );
      }
    }
  }

  // Fungsi untuk memilih video dari galeri
  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );

      if (pickedFile != null) {
        // Compress the picked video before using it
        final compressed = await _compressVideo(pickedFile.path);
        File chosenFile = compressed ?? File(pickedFile.path);

        // Generate thumbnail for the chosen file (compressed preferred)
        try {
          final String? thumbPath = await VideoThumbnail.thumbnailFile(
            video: chosenFile.path,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 512, // maintain reasonable size
            quality: 75,
          );

          setState(() {
            _selectedMediaFile = chosenFile;
            _selectedMediaType = 'video';
            _selectedThumbnailFile = thumbPath != null ? File(thumbPath) : null;
          });
        } catch (e) {
          // If thumbnail generation fails, still set the video file
          setState(() {
            _selectedMediaFile = chosenFile;
            _selectedMediaType = 'video';
            _selectedThumbnailFile = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih video: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        );
      }
    }
  }

  // Compress a video file at [filePath] and return a File? to the compressed file.
  // Uses VideoCompress.compressVideo with low quality to reduce file size.
  Future<File?> _compressVideo(String filePath) async {
    try {
      // ensure VideoCompress is ready
      await VideoCompress.setLogLevel(0);

      final MediaInfo? info = await VideoCompress.compressVideo(
        filePath,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info == null || info.path == null) return null;
      return File(info.path!);
    } catch (e) {
      debugPrint('Error compressing video: $e');
      return null;
    }
  }

  // Fungsi untuk upload karya
  Future<void> _uploadArtwork() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedMediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Harap pilih gambar karya terlebih dahulu.'),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // 1. Cek user authentication
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("User tidak login.");
      // 1.b Cek role user -- hanya 'artist' yang boleh mengunggah
      final roleRow = await Supabase.instance.client.from('users').select('role').eq('id', user.id).maybeSingle();
      final role = roleRow != null ? (roleRow['role'] as String?) : null;
      if (role != 'artist') {
        throw Exception('Akses ditolak: akun Anda bukan Artist.');
      }
      
      print('User ID: ${user.id}');
      print('User Email: ${user.email}');

      // 2. Upload media ke Supabase Storage
      final fileExt = _selectedMediaFile!.path.split('.').last;
      final fileName = '${user.id}${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final mediaBytes = await _selectedMediaFile!.readAsBytes();

      print('Uploading media: $fileName');
      // Store media under public/<userId>/ to keep consistent with deletion logic
      final storagePath = 'public/${user.id}/$fileName';
      await Supabase.instance.client.storage.from('artworks').uploadBinary(storagePath, mediaBytes);

      // Dapatkan URL publik untuk media utama
      final mediaUrl = Supabase.instance.client.storage.from('artworks').getPublicUrl(storagePath);
      print('Media URL: $mediaUrl');

      String? thumbnailUrl;
      if (_selectedMediaType == 'video' && _selectedThumbnailFile != null) {
        final thumbExt = _selectedThumbnailFile!.path.split('.').last;
        final thumbName = '${user.id}_thumb_${DateTime.now().millisecondsSinceEpoch}.$thumbExt';
        final thumbBytes = await _selectedThumbnailFile!.readAsBytes();
        final thumbPath = 'public/${user.id}/$thumbName';
        await Supabase.instance.client.storage.from('artworks').uploadBinary(thumbPath, thumbBytes);
        thumbnailUrl = Supabase.instance.client.storage.from('artworks').getPublicUrl(thumbPath);
        print('Thumbnail URL: $thumbnailUrl');
      }

    // 3. Ambil nama artist dari tabel 'users' (gunakan maybeSingle untuk menghindari exception bila row belum lengkap)
    print('Fetching user data...');
    final userResponse = await Supabase.instance.client.from('users').select('name').eq('id', user.id).maybeSingle();
    final artistName = (userResponse != null && userResponse['name'] != null) ? userResponse['name'] : 'Nama Tidak Ditemukan';
      print('Artist name: $artistName');

      // 4. Simpan semua data ke Supabase database
      print('Inserting artwork data...');
      final artworkData = {
        'title': _judulController.text.trim(),
        'description': _deskripsiController.text.trim(),
        'external_link': _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
        'category': _selectedKategori,
        'media_url': mediaUrl,
        'thumbnail_url': thumbnailUrl,
        'artwork_type': _selectedMediaType ?? 'image',
        'artist_id': user.id,
        'artist_name': artistName,
        'created_at': DateTime.now().toIso8601String(),
        'likes_count': 0,
        'status': 'pending',
      };
      
      print('Artwork data: $artworkData');
      await Supabase.instance.client.from('artworks').insert(artworkData);
      print('Artwork inserted successfully!');

      if (mounted) {
        Navigator.of(context).pop(); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Karya berhasil diunggah dan sedang menunggu persetujuan.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah karya: ${e.toString()}'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        title: Text(
          'Unggah Karya Baru',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Info
              FadeInAnimation(
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppTheme.shadowMd,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: AppTheme.spaceSm),
                      Expanded(
                        child: Text(
                          'Karya Anda akan ditinjau oleh admin sebelum dipublikasikan',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              
              // Judul Karya
              FadeSlideAnimation(
                delay: const Duration(milliseconds: 100),
                child: TextFormField(
                  controller: _judulController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Judul Karya',
                    labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(color: AppTheme.textTertiary.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(color: AppTheme.textTertiary.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(color: AppTheme.primary, width: 2),
                    ),
                    prefixIcon: Icon(Icons.title_rounded, color: AppTheme.primary),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Judul wajib diisi' : null,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              
              // Deskripsi
              FadeSlideAnimation(
                delay: const Duration(milliseconds: 150),
                child: TextFormField(
                  controller: _deskripsiController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi',
                    labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(color: AppTheme.textTertiary.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(color: AppTheme.textTertiary.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(color: AppTheme.primary, width: 2),
                    ),
                    prefixIcon: Icon(Icons.description_rounded, color: AppTheme.primary),
                  ),
                  maxLines: 4,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Deskripsi wajib diisi' : null,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              
              // Link Eksternal
              FadeSlideAnimation(
                delay: const Duration(milliseconds: 200),
                child: TextFormField(
                  controller: _linkController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Link Eksternal (Opsional)',
                    labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(color: AppTheme.textTertiary.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(color: AppTheme.textTertiary.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(color: AppTheme.primary, width: 2),
                    ),
                    prefixIcon: Icon(Icons.link_rounded, color: AppTheme.primary),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              
              // Kategori
              FadeSlideAnimation(
                delay: const Duration(milliseconds: 250),
                child: DropdownButtonFormField<String>(
                  value: _selectedKategori,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(color: AppTheme.textTertiary.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(color: AppTheme.textTertiary.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide(color: AppTheme.primary, width: 2),
                    ),
                    prefixIcon: Icon(Icons.category_rounded, color: AppTheme.primary),
                  ),
                  items: _kategoriList
                      .map((kategori) => DropdownMenuItem(
                            value: kategori,
                            child: Text(kategori),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedKategori = value;
                    });
                  },
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Pilih kategori' : null,
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),
              
              // Media Picker Section Title
              FadeSlideAnimation(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  'Pilih Media',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'Playfair Display',
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              
              // Buttons to pick image or video
              FadeSlideAnimation(
                delay: const Duration(milliseconds: 350),
                child: Row(
                  children: [
                    Expanded(
                      child: BounceAnimation(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
                          decoration: BoxDecoration(
                            gradient: AppTheme.secondaryGradient,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            boxShadow: AppTheme.shadowMd,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_library_rounded, color: Colors.white),
                              const SizedBox(width: AppTheme.spaceXs),
                              Text(
                                'Pilih Gambar',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMd),
                    Expanded(
                      child: BounceAnimation(
                        onTap: _pickVideo,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            boxShadow: AppTheme.shadowMd,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_rounded, color: Colors.white),
                              const SizedBox(width: AppTheme.spaceXs),
                              Text(
                                'Pilih Video',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              
              // Preview Media
              FadeSlideAnimation(
                delay: const Duration(milliseconds: 400),
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppTheme.shadowMd,
                  ),
                  child: DottedBorder(
                    color: AppTheme.primary,
                    strokeWidth: 2,
                    borderType: BorderType.RRect,
                    radius: Radius.circular(AppTheme.radiusLg),
                    dashPattern: const [8, 6],
                    child: Center(
                      child: _selectedMediaFile != null
                          ? (_selectedMediaType == 'image'
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                  child: Image.file(
                                    _selectedMediaFile!,
                                    height: 240,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(AppTheme.spaceMd),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.primary.withOpacity(0.1),
                                      ),
                                      child: Icon(
                                        Icons.videocam_rounded,
                                        size: 48,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spaceSm),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                                      child: Text(
                                        _selectedMediaFile!.path.split('/').last,
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spaceXs),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spaceSm,
                                        vertical: AppTheme.spaceXs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentGreen.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      ),
                                      child: Text(
                                        'Video dipilih (maks 30 detik)',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: AppTheme.accentGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.primary.withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.add_photo_alternate_rounded,
                                    size: 56,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spaceMd),
                                Text(
                                  'Pilih Gambar atau Video',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spaceXs),
                                Text(
                                  'Gunakan tombol di atas untuk memilih',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg * 2),
              // Upload Button
              ScaleInAnimation(
                delay: const Duration(milliseconds: 450),
                child: BounceAnimation(
                  onTap: _isUploading ? null : _uploadArtwork,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceMd + 2),
                    decoration: BoxDecoration(
                      gradient: _isUploading 
                          ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500])
                          : AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: _isUploading ? [] : AppTheme.shadowLg,
                    ),
                    child: _isUploading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceSm),
                              Text(
                                'Mengunggah...',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_rounded, color: Colors.white),
                              const SizedBox(width: AppTheme.spaceXs),
                              Text(
                                'Unggah Karya',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget DottedBorder (karena tidak bisa import package, kita buat manual sederhana)
class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final BorderType borderType;
  final Radius radius;
  final List<double> dashPattern;

  const DottedBorder({
    Key? key,
    required this.child,
    this.color = Colors.black,
    this.strokeWidth = 1,
    this.borderType = BorderType.RRect,
    this.radius = const Radius.circular(0),
    this.dashPattern = const [6, 3],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        radius: radius,
        dashPattern: dashPattern,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(radius),
        child: child,
      ),
    );
  }
}

enum BorderType { RRect }

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final Radius radius;
  final List<double> dashPattern;

  _DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashPattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      radius,
    );

    final Path path = Path()..addRRect(rrect);

    double dashOn = dashPattern[0];
    double dashOff = dashPattern[1];
    double distance = 0.0;
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      while (distance < metric.length) {
        final double next = distance + dashOn;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashOff;
      }
      distance = 0.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
