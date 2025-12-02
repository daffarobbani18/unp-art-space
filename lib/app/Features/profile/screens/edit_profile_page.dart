import 'dart:convert';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  String _userRole = 'viewer';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController behanceController = TextEditingController();

  String? _selectedSpecialization;
  bool _loadingProfile = false;
  bool _isSaving = false;
  String? _profileImageUrl;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _specializations = [
    'Pelukis', 'Fotografer', 'Ilustrator', 'Videografer', 'Desainer Grafis', 'Musisi'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        // No logged in user
        return;
      }

      // Ambil data user dari tabel users
      final data = await supabase
          .from('users')
          .select('name, bio, social_media, specialization, role, profile_image_url')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (data == null) return;

      // isi controller dari data
      final user = Map<String, dynamic>.from(data as Map);

      setState(() {
        _userRole = (user['role'] ?? 'viewer') as String;
        nameController.text = (user['name'] ?? '') as String;
        bioController.text = (user['bio'] ?? '') as String;
        _selectedSpecialization = (user['specialization'] ?? '') as String?;
        _profileImageUrl = user['profile_image_url'] as String?;
        final social = user['social_media'];

        if (social is Map) {
          instagramController.text = (social['instagram'] ?? '') as String;
          behanceController.text = (social['behance'] ?? '') as String;
        } else if (social is String && social.isNotEmpty) {
          try {
            final decoded = json.decode(social);
            if (decoded is Map) {
              instagramController.text = (decoded['instagram'] ?? '') as String;
              behanceController.text = (decoded['behance'] ?? '') as String;
            }
          } catch (_) {
            // ignore parse errors
          }
        }
      });
    } catch (e) {
      // ignore or log
    } finally {
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
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
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: const Color(0xFFFF6584),
          ),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_selectedImage == null) return _profileImageUrl;

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return null;

      final fileExt = _selectedImage!.path.split('.').last;
      final fileName = '${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'profile_images/$fileName';

      await supabase.storage.from('artworks').upload(
        filePath,
        _selectedImage!,
        fileOptions: const FileOptions(upsert: true),
      );

      final imageUrl = supabase.storage.from('artworks').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal upload gambar: $e'),
            backgroundColor: const Color(0xFFFF6584),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Tidak ada user yang login');
      }

      // Upload gambar jika ada
      String? uploadedImageUrl;
      if (_selectedImage != null) {
        uploadedImageUrl = await _uploadProfileImage();
        if (uploadedImageUrl == null) {
          throw Exception('Gagal upload gambar profil');
        }
      }

      final updates = <String, dynamic>{
        'name': nameController.text.trim(),
        'bio': bioController.text.trim(),
      };

      if (uploadedImageUrl != null) {
        updates['profile_image_url'] = uploadedImageUrl;
      }

      if (_userRole == 'artist') {
        updates['specialization'] = _selectedSpecialization;
        updates['social_media'] = {
          'instagram': instagramController.text.trim(),
          'behance': behanceController.text.trim(),
        };
      }

      await supabase.from('users').update(updates).eq('id', currentUser.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profil berhasil diperbarui',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memperbarui profil: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFFF6584),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    instagramController.dispose();
    behanceController.dispose();
    super.dispose();
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E2C).withOpacity(0.8),
            const Color(0xFF2D2D3A).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? minLines,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          minLines: minLines,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF6584), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF6584), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profil',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _loadingProfile
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            )
          : SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile Image Section
                        _buildGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF6366F1),
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF6366F1).withOpacity(0.3),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: _selectedImage != null
                                            ? Image.file(_selectedImage!, fit: BoxFit.cover)
                                            : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                                ? Image.network(_profileImageUrl!, fit: BoxFit.cover)
                                                : Container(
                                                    color: const Color(0xFF2D2D3A),
                                                    child: const Icon(
                                                      Icons.person,
                                                      size: 60,
                                                      color: Color(0xFF6366F1),
                                                    ),
                                                  ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: _pickImage,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF6366F1).withOpacity(0.5),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Foto Profil',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ketuk ikon kamera untuk mengubah',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Basic Information Section
                        _buildGlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.person, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Informasi Dasar',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  controller: nameController,
                                  label: 'Nama Lengkap',
                                  icon: Icons.person_outline,
                                  hint: 'Masukkan nama lengkap Anda',
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: bioController,
                                  label: 'Bio',
                                  icon: Icons.description_outlined,
                                  hint: 'Ceritakan tentang diri Anda',
                                  minLines: 4,
                                  maxLines: 6,
                                  keyboardType: TextInputType.multiline,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Artist-specific fields
                        if (_userRole == 'artist') ...[
                          const SizedBox(height: 24),
                          _buildGlassCard(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.palette, color: Colors.white, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Informasi Artist',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Spesialisasi',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: (_selectedSpecialization != null && 
                                               _selectedSpecialization!.isNotEmpty && 
                                               _specializations.contains(_selectedSpecialization))
                                            ? _selectedSpecialization
                                            : null,
                                        decoration: InputDecoration(
                                          hintText: 'Pilih spesialisasi Anda',
                                          hintStyle: GoogleFonts.poppins(
                                            color: Colors.white.withOpacity(0.3),
                                            fontSize: 14,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.brush,
                                            color: Color(0xFF6366F1),
                                            size: 20,
                                          ),
                                          filled: true,
                                          fillColor: Colors.black.withOpacity(0.3),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFFFF6584), width: 1.5),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        ),
                                        dropdownColor: const Color(0xFF2D2D3A),
                                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                                        items: _specializations.map((s) {
                                          return DropdownMenuItem(
                                            value: s,
                                            child: Text(s),
                                          );
                                        }).toList(),
                                        onChanged: (v) => setState(() => _selectedSpecialization = v),
                                        validator: (v) => (v == null || v.isEmpty) ? 'Pilih spesialisasi' : null,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: instagramController,
                                    label: 'Instagram',
                                    icon: Icons.camera_alt,
                                    hint: 'https://instagram.com/username',
                                    keyboardType: TextInputType.url,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: behanceController,
                                    label: 'Behance',
                                    icon: Icons.work_outline,
                                    hint: 'https://behance.net/username',
                                    keyboardType: TextInputType.url,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Save Button
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.save, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Simpan Perubahan',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}