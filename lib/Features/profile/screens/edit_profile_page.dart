import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          .select('name, bio, social_media, specialization, role')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (data == null) return;

      // isi controller dari data
      final user = Map<String, dynamic>.from(data as Map);

      setState(() {
        _userRole = (user['role'] ?? 'viewer') as String; // <-- TAMBAHKAN INI
        nameController.text = (user['name'] ?? '') as String;
        bioController.text = (user['bio'] ?? '') as String;
        _selectedSpecialization = (user['specialization'] ?? '') as String?;
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada user yang login')),
      );
      return;
    }

    final socialMedia = {
      'instagram': instagramController.text.trim(),
      'behance': behanceController.text.trim(),
      
    };

    final updates = {
      'name': nameController.text.trim(),
      'bio': bioController.text.trim(),
      'specialization': _selectedSpecialization,
      'social_media': socialMedia, // Supabase JSONB
      
    };

    if (_userRole == 'artist') {
      updates['specialization'] = _selectedSpecialization;
      updates['social_media'] = {
        'instagram': instagramController.text.trim(),
        'behance': behanceController.text.trim(),
      };
    }
    await supabase.from('users').update(updates).eq('id', currentUser.id);

      // Tampilkan progress indicator modal
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
  
      try {
        // Lakukan update pada row dengan id user yang sedang login
        final response = await supabase
            .from('users')
            .update(updates)
            .eq('id', currentUser.id)
            .select()
            .maybeSingle();
  
        // Jika widget sudah tidak mounted, batalkan operasi yang mengakses context
        if (!mounted) return;
  
        // Tutup dialog loading
        Navigator.of(context).pop();
  
        // response berisi data hasil update; jika null bisa dianggap error ringan
        if (response != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil berhasil diperbarui')),
          );
          Navigator.of(context).pop(); // kembali ke halaman sebelumnya
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Terjadi masalah saat memperbarui profil')),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // tutup loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui profil: $e')),
          );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        alignLabelWithHint: true, // Membuat label 'Bio' di atas
                        border: OutlineInputBorder(),
                        ),
                      minLines: 5,
                      maxLines: null, // <-- TAMBAHKAN INI (artinya bisa lebih dari 5 baris)
                      keyboardType: TextInputType.multiline, 
                    ),
                    const SizedBox(height: 12),
                    if (_userRole == 'artist') ...[
                      DropdownButtonFormField<String>(
                      value: (_selectedSpecialization != null && _selectedSpecialization != '' && _specializations.contains(_selectedSpecialization))
                          ? _selectedSpecialization
                          : null,
                      decoration: const InputDecoration(labelText: 'Spesialisasi'),
                      items: _specializations
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedSpecialization = v),
                      validator: (v) => (v == null || v.isEmpty) ? 'Pilih spesialisasi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: instagramController,
                      decoration: const InputDecoration(labelText: 'Link Instagram'),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: behanceController,
                      decoration: const InputDecoration(labelText: 'Link Behance'),
                      keyboardType: TextInputType.url,
                    ),
                    ],
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        child: const Text('Simpan Perubahan', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}