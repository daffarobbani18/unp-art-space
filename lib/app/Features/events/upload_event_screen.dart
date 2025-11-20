import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/app_animations.dart';

class UploadEventScreen extends StatefulWidget {
  const UploadEventScreen({super.key});

  @override
  State<UploadEventScreen> createState() => _UploadEventScreenState();
}

class _UploadEventScreenState extends State<UploadEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  File? _imageFile;
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A8A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A8A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih gambar event')),
      );
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih tanggal dan waktu event')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User tidak terautentikasi');
      }

      // Gabungkan tanggal dan waktu
      final eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Upload gambar ke Supabase Storage
      final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath =
          '${user.id}/$fileName'; // Simplified path: {user_id}/{filename}

      print('📤 Uploading to storage path: $storagePath');

      String imageUrl;
      try {
        // Try upload to 'artworks' bucket with user folder structure
        await Supabase.instance.client.storage
            .from('artworks')
            .upload(
              storagePath,
              _imageFile!,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: true,
              ),
            );

        // Dapatkan URL publik
        imageUrl = Supabase.instance.client.storage
            .from('artworks')
            .getPublicUrl(storagePath);

        print('✅ Upload successful to artworks bucket');
        print('🖼️ Image URL: $imageUrl');
      } catch (storageError) {
        print('❌ Storage error: $storageError');

        // Fallback: gunakan placeholder image URL atau throw error
        if (storageError.toString().contains('403') ||
            storageError.toString().contains('Unauthorized') ||
            storageError.toString().contains('row-level security')) {
          throw Exception(
            'Gagal upload gambar: Akses ditolak oleh sistem.\n'
            'Silakan hubungi admin untuk mengaktifkan Storage Policy.\n\n'
            'Error: ${storageError.toString()}',
          );
        } else {
          throw Exception('Gagal upload gambar: ${storageError.toString()}');
        }
      }

      // Insert data event ke database
      await Supabase.instance.client.from('events').insert({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'event_date': eventDateTime.toIso8601String(),
        'location': _locationController.text.trim(),
        'image_url': imageUrl,
        'artist_id': user.id,
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Event berhasil diajukan! Menunggu persetujuan admin.',
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Return true untuk refresh my_events_screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupload event: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Upload Event',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamily: 'Playfair Display',
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Info Banner - Glass Card
                      FadeInAnimation(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spaceMd),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  width: 1.5,
                                ),
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
                                      'Event akan direview admin terlebih dahulu',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.white.withOpacity(
                                              0.9,
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
                      const SizedBox(height: AppTheme.spaceLg),

                      // Image Picker Section - Glass Container
                      FadeSlideAnimation(
                        delay: const Duration(milliseconds: 100),
                        child: BounceAnimation(
                          onTap: _isUploading ? null : _pickImage,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _imageFile != null
                                        ? Colors.green.withOpacity(0.5)
                                        : Colors.white.withOpacity(0.15),
                                    width: 1.5,
                                  ),
                                ),
                                child: _imageFile != null
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Image.file(
                                                _imageFile!,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: AppTheme.spaceSm,
                                            right: AppTheme.spaceSm,
                                            child: Container(
                                              padding: const EdgeInsets.all(
                                                AppTheme.spaceXs,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(
                                                  0.9,
                                                ),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green
                                                        .withOpacity(0.5),
                                                    blurRadius: 10,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(
                                              AppTheme.spaceMd,
                                            ),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white.withOpacity(
                                                0.15,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.add_photo_alternate_rounded,
                                              size: 56,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: AppTheme.spaceMd,
                                          ),
                                          Text(
                                            'Tap untuk pilih gambar event',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(
                                            height: AppTheme.spaceXs,
                                          ),
                                          Text(
                                            'Ukuran maksimal 5MB',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTheme.spaceLg),

                      // Title Field - Glass Input
                      FadeSlideAnimation(
                        delay: const Duration(milliseconds: 150),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Judul Event',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: AppTheme.spaceXs),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: _titleController,
                                    enabled: !_isUploading,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Contoh: Pameran Seni Rupa UNP 2024',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(16),
                                      prefixIcon: Icon(
                                        Icons.title_rounded,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Judul event wajib diisi';
                                      }
                                      if (value.trim().length < 5) {
                                        return 'Judul minimal 5 karakter';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.spaceMd),

                      // Content Field - Glass Input
                      FadeSlideAnimation(
                        delay: const Duration(milliseconds: 200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deskripsi Event',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: AppTheme.spaceXs),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: _contentController,
                                    enabled: !_isUploading,
                                    maxLines: 4,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Jelaskan tentang event ini, kegiatan yang akan dilakukan, dll.',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(16),
                                      prefixIcon: Icon(
                                        Icons.description_rounded,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Deskripsi event wajib diisi';
                                      }
                                      if (value.trim().length < 20) {
                                        return 'Deskripsi minimal 20 karakter';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.spaceMd),

                      // Date & Time Row - Glass Style
                      FadeSlideAnimation(
                        delay: const Duration(milliseconds: 250),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tanggal',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                  ),
                                  const SizedBox(height: AppTheme.spaceXs),
                                  BounceAnimation(
                                    onTap: _isUploading ? null : _selectDate,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10,
                                          sigmaY: 10,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(
                                            AppTheme.spaceMd,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: _selectedDate != null
                                                  ? Colors.purple.withOpacity(
                                                      0.5,
                                                    )
                                                  : Colors.white.withOpacity(
                                                      0.15,
                                                    ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_rounded,
                                                size: 20,
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: AppTheme.spaceSm,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  _selectedDate != null
                                                      ? DateFormat(
                                                          'dd MMM yyyy',
                                                        ).format(_selectedDate!)
                                                      : 'Pilih tanggal',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color:
                                                            _selectedDate !=
                                                                null
                                                            ? Colors.white
                                                            : Colors.white
                                                                  .withOpacity(
                                                                    0.5,
                                                                  ),
                                                        fontWeight:
                                                            _selectedDate !=
                                                                null
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceSm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Waktu',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                  ),
                                  const SizedBox(height: AppTheme.spaceXs),
                                  BounceAnimation(
                                    onTap: _isUploading ? null : _selectTime,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10,
                                          sigmaY: 10,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(
                                            AppTheme.spaceMd,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.05,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: _selectedTime != null
                                                  ? Colors.purple.withOpacity(
                                                      0.5,
                                                    )
                                                  : Colors.white.withOpacity(
                                                      0.15,
                                                    ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                size: 20,
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: AppTheme.spaceSm,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  _selectedTime != null
                                                      ? _selectedTime!.format(
                                                          context,
                                                        )
                                                      : 'Pilih waktu',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color:
                                                            _selectedTime !=
                                                                null
                                                            ? Colors.white
                                                            : Colors.white
                                                                  .withOpacity(
                                                                    0.5,
                                                                  ),
                                                        fontWeight:
                                                            _selectedTime !=
                                                                null
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.spaceMd),

                      // Location Field - Glass Input
                      FadeSlideAnimation(
                        delay: const Duration(milliseconds: 300),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lokasi',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: AppTheme.spaceXs),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: _locationController,
                                    enabled: !_isUploading,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Contoh: Galeri Seni FBS UNP, Padang',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(16),
                                      prefixIcon: Icon(
                                        Icons.location_on_rounded,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Lokasi event wajib diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.spaceLg * 2),

                      // Submit Button - Gradient
                      ScaleInAnimation(
                        delay: const Duration(milliseconds: 350),
                        child: BounceAnimation(
                          onTap: _isUploading ? null : _submitEvent,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spaceMd + 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: _isUploading
                                  ? LinearGradient(
                                      colors: [
                                        Colors.grey.shade600,
                                        Colors.grey.shade700,
                                      ],
                                    )
                                  : const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF6B3FA0),
                                        Color(0xFF3A7BD5),
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _isUploading
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: AppTheme.spaceSm),
                                      Text(
                                        'Mengupload...',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cloud_upload_rounded,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: AppTheme.spaceXs),
                                      Text(
                                        'Upload Event',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceMd),
                    ],
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
