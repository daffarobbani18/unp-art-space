import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;

class InspirasiDuniaPage extends StatefulWidget {
  const InspirasiDuniaPage({super.key});

  @override
  State<InspirasiDuniaPage> createState() => _InspirasiDuniaPageState();
}

class _InspirasiDuniaPageState extends State<InspirasiDuniaPage> {
  late Future<List<Map<String, dynamic>>> _masterpiecesFuture;

  @override
  void initState() {
    super.initState();
    _masterpiecesFuture = _fetchArtworksFromAIC();
  }

  Future<List<Map<String, dynamic>>> _fetchArtworksFromAIC() async {
    // Kita cari karya-karya impresionis sebagai contoh
    final url = Uri.parse('https://api.artic.edu/api/v1/artworks/search?q=impressionism&fields=id,title,image_id,artist_title&limit=20');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      // API mengembalikan data dalam List, kita langsung gunakan
      return List<Map<String, dynamic>>.from(jsonData['data']);
    } else {
      throw Exception('Gagal mengambil data dari API.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspirasi Dunia'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _masterpiecesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada karya ditemukan.'));
          }

          final artworks = snapshot.data!;

          return MasonryGridView.count(
            padding: const EdgeInsets.all(8.0),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            itemCount: artworks.length,
            itemBuilder: (context, index) {
              final artwork = artworks[index];
              final imageId = artwork['image_id'];
              final imageUrl = imageId != null 
                  ? 'https://www.artic.edu/iiif/2/$imageId/full/843,/0/default.jpg'
                  : '';

                return InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Anda mengklik: ${artwork['title']}')),
                  );
                  // TODO: Navigasi ke halaman detail
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tampilkan gambar jika URL ada
                      if (imageUrl.isNotEmpty)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) => 
                              progress == null ? child : Container(height: 150, color: Colors.grey[200]),
                          // 
                          errorBuilder: (context, error, stackTrace) {
                            // LETAKKAN PRINT DI SINI
                            print('IMAGE LOAD ERROR: ${error.toString()}'); 
                            
                            // KEMUDIAN KEMBALIKAN WIDGET-NYA
                            return Container(
                              height: 150, 
                              color: Colors.grey[200], 
                              child: const Icon(Icons.broken_image)
                            );
                          },
                        ),
                      
                      // Tampilkan teks di bawah gambar
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(artwork['title'] ?? 'Tanpa Judul', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(artwork['artist_title'] ?? 'Anonim', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );

            },
          );
        },
      ),
    );
  }
}