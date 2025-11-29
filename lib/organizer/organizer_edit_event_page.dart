import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrganizerEditEventPage extends StatefulWidget {
  final String eventId;
  final String currentTitle;
  final String? currentContent;
  final DateTime? currentEventDate;
  final String? currentLocation;
  final String? currentImageUrl;

  const OrganizerEditEventPage({
    Key? key,
    required this.eventId,
    required this.currentTitle,
    this.currentContent,
    this.currentEventDate,
    this.currentLocation,
    this.currentImageUrl,
  }) : super(key: key);

  @override
  State<OrganizerEditEventPage> createState() => _OrganizerEditEventPageState();
}

class _OrganizerEditEventPageState extends State<OrganizerEditEventPage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _locationController;
  DateTime? _selectedDate;
  File? _newBannerImage;
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
    _contentController = TextEditingController(text: widget.currentContent ?? '');
    _locationController = TextEditingController(text: widget.currentLocation ?? '');
    _selectedDate = widget.currentEventDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _newBannerImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorDialog('Gagal memilih gambar: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF9333EA),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Show time picker
      if (!mounted) return;
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF9333EA),
                onPrimary: Colors.white,
                surface: Color(0xFF1E1E2E),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<String?> _uploadBanner() async {
    if (_newBannerImage == null) return null;

    setState(() => _isUploading = true);

    try {
      final fileName = 'event_${widget.eventId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'event_banners/$fileName';

      await supabase.storage.from('event_banners').upload(
            filePath,
            _newBannerImage!,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      final imageUrl = supabase.storage.from('event_banners').getPublicUrl(filePath);

      setState(() => _isUploading = false);
      return imageUrl;
    } catch (e) {
      setState(() => _isUploading = false);
      _showErrorDialog('Gagal upload banner: $e');
      return null;
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Upload banner baru jika ada
      String? newImageUrl;
      if (_newBannerImage != null) {
        newImageUrl = await _uploadBanner();
        if (newImageUrl == null) {
          setState(() => _isSaving = false);
          return; // Upload failed
        }
      }

      // Update event di database
      final updateData = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'location': _locationController.text.trim(),
        'event_date': _selectedDate?.toIso8601String(),
      };

      if (newImageUrl != null) {
        updateData['image_url'] = newImageUrl;
      }

      await supabase.from('events').update(updateData).eq('id', widget.eventId);

      setState(() => _isSaving = false);

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Berhasil',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'Event berhasil diperbarui!',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Return to detail page with refresh flag
                },
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorDialog('Gagal menyimpan perubahan: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: GoogleFonts.poppins(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Event',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Image Section
                  _buildBannerSection(),
                  const SizedBox(height: 24),

                  // Title Field
                  _buildTextField(
                    controller: _titleController,
                    label: 'Judul Event',
                    icon: Icons.event,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Judul event tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Content Field
                  _buildTextField(
                    controller: _contentController,
                    label: 'Deskripsi Event',
                    icon: Icons.description,
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Deskripsi tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date Field
                  _buildDateField(),
                  const SizedBox(height: 16),

                  // Location Field
                  _buildTextField(
                    controller: _locationController,
                    label: 'Lokasi',
                    icon: Icons.location_on,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Lokasi tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isSaving || _isUploading) ? null : _saveEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving || _isUploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Simpan Perubahan',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.image,
                    color: const Color(0xFF9333EA),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Banner Event',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Current or New Banner Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _newBannerImage != null
                    ? Image.file(
                        _newBannerImage!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : widget.currentImageUrl != null
                        ? Image.network(
                            widget.currentImageUrl!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
              ),
              const SizedBox(height: 12),
              // Change Banner Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickImage,
                  icon: const Icon(Icons.upload, size: 18),
                  label: Text(
                    _newBannerImage != null ? 'Ganti Banner Lagi' : 'Ganti Banner',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9333EA),
                    side: const BorderSide(color: Color(0xFF9333EA)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildPlaceholder() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.3),
            const Color(0xFF3B82F6).withOpacity(0.3),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          size: 60,
          color: Colors.white24,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
            validator: validator,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 14,
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF9333EA)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF9333EA),
                    size: 20,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal & Waktu Event',
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedDate != null
                              ? DateFormat('dd MMMM yyyy, HH:mm').format(_selectedDate!)
                              : 'Pilih tanggal',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white60,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
