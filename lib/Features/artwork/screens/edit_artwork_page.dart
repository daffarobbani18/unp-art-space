import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project1/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditArtworkPage extends StatefulWidget {
  final Map<String, dynamic> artwork;
  const EditArtworkPage({super.key, required this.artwork});

  @override
  State<EditArtworkPage> createState() => _EditArtworkPageState();
}

class _EditArtworkPageState extends State<EditArtworkPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Isi controller dengan data dari widget
    _judulController.text = widget.artwork['title'] ?? '';
    _deskripsiController.text = widget.artwork['description'] ?? '';
    _linkController.text = widget.artwork['external_link'] ?? '';
    _selectedKategori = widget.artwork['category'];
  }

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

  // Untuk preview gambar
  File? _selectedImage;
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
          _selectedImage = File(pickedFile.path);
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

  // Fungsi untuk upload karya
  // Ganti fungsi _submitArtwork dengan fungsi ini
Future<void> _updateArtwork() async {
  if (!(_formKey.currentState?.validate() ?? false)) return;

  setState(() { _isUploading = true; });

  try {
    // Gunakan .update() untuk mengubah data yang ada
    await supabase
        .from('artworks')
        .update({
          'title': _judulController.text.trim(),
          'description': _deskripsiController.text.trim(),
          'external_link': _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
          'category': _selectedKategori,
          // Kita juga ubah statusnya kembali ke 'menunggu' setelah diedit
          'status': 'menunggu_persetujuan',
        })
        .eq('id', widget.artwork['id']); // Berdasarkan ID karya yang diedit

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Karya berhasil diperbarui.'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(); // Kembali ke halaman profil
    }

  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui: ${e.toString()}')),
      );
    }
  } finally {
    if (mounted) {
      setState(() { _isUploading = false; });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Karya'),
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
              // Preview media (prefer media_url)
              Image.network(widget.artwork['media_url'] ?? widget.artwork['image_url'] ?? ''),
              
              const SizedBox(height: 32),
              
              // Tombol Unggah Karya
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _updateArtwork,
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
                          'Simpan Perubahan',
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
