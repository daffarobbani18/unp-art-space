import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
            backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
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
        const SnackBar(
          content: Text('Harap pilih gambar karya terlebih dahulu.'),
          backgroundColor: Colors.orange,
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
          const SnackBar(
            content: Text('Karya berhasil diunggah dan sedang menunggu persetujuan.'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah karya: ${e.toString()}'),
            backgroundColor: Colors.red,
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
      appBar: AppBar(
        title: const Text('Unggah Karya Baru'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Judul Karya
              TextFormField(
                controller: _judulController,
                decoration: InputDecoration(
                  labelText: 'Judul Karya',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 18),
              // Deskripsi
              TextFormField(
                controller: _deskripsiController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Deskripsi wajib diisi' : null,
              ),
              const SizedBox(height: 18),
              // Link Eksternal
              TextFormField(
                controller: _linkController,
                decoration: InputDecoration(
                  labelText: 'Link Eksternal',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 18),
              // Kategori
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.category),
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
              const SizedBox(height: 24),
              // Preview Gambar
              // Buttons to pick image or video
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text('Pilih Gambar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.videocam),
                      label: const Text('Pilih Video'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Preview Media
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.deepPurple,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DottedBorder(
                  color: Colors.deepPurple,
                  strokeWidth: 2,
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(12),
                  dashPattern: const [8, 6],
                  child: Center(
                    child: _selectedMediaFile != null
                        ? (_selectedMediaType == 'image'
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _selectedMediaFile!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.videocam, size: 48, color: Colors.deepPurple),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedMediaFile!.path.split('/').last,
                                    style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Video dipilih (maks 30 detik)',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_a_photo, size: 48, color: Colors.deepPurple),
                              SizedBox(height: 8),
                              Text(
                                'Pilih Gambar atau Video',
                                style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Gunakan tombol di atas untuk memilih',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Tombol Unggah Karya
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadArtwork,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isUploading ? Colors.grey : Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: _isUploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Mengunggah...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        )
                      : const Text(
                          'Unggah Karya',
                          style: TextStyle(color: Colors.white),
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
