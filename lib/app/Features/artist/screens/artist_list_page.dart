import 'package:flutter/material.dart';
import '../../../../main/main_app.dart'; // Untuk akses supabase
import 'artist_detail_page.dart';

class ArtistListPage extends StatefulWidget {
  // Ganti 'category' menjadi 'specialization' agar konsisten dengan database
  final String specialization; 
  const ArtistListPage({super.key, required this.specialization});

  @override
  State<ArtistListPage> createState() => _ArtistListPageState();
}

class _ArtistListPageState extends State<ArtistListPage> {
  late final Future<List<Map<String, dynamic>>> _artistsFuture;

  @override
  void initState() {
    super.initState();
    // Memanggil fungsi untuk mengambil data berdasarkan spesialisasi yang diterima
    _artistsFuture = _fetchArtistsBySpecialization();
  }

  // Fungsi untuk mengambil data dari Supabase berdasarkan spesialisasi
  Future<List<Map<String, dynamic>>> _fetchArtistsBySpecialization() async {
    final response = await supabase
        .from('users')
        .select('id, name, specialization') // Ambil kolom yang relevan
        .eq('role', 'artist')
        .eq('specialization', widget.specialization); // Filter berdasarkan spesialisasi dari widget

    // Supabase v2 mengembalikan List, jadi kita bisa langsung cast
    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Judul AppBar sekarang dinamis sesuai spesialisasi yang dipilih
        title: Text(widget.specialization),
        elevation: 1,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _artistsFuture, // Gunakan future yang sudah diinisialisasi
        builder: (context, snapshot) {
          // Tampilkan loading indicator saat data sedang diambil
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Tampilkan pesan error jika terjadi masalah
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi error: ${snapshot.error}'));
          }
          // Ambil data dari snapshot
          final artists = snapshot.data ?? [];

          // Tampilkan pesan jika tidak ada seniman ditemukan
          if (artists.isEmpty) {
            return Center(
              child: Text(
                'Belum ada seniman dengan spesialisasi ini.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            );
          }

          // Tampilkan daftar seniman menggunakan ListView
          return ListView.builder(
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              final name = artist['name'] as String? ?? 'Tanpa Nama';
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U'),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(widget.specialization),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigasi ke halaman detail saat item di-tap
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ArtistDetailPage(artistId: artist['id']),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}