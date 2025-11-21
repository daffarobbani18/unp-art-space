import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import '../../../shared/widgets/custom_network_image.dart';

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
    final url = Uri.parse('https://api.artic.edu/api/v1/artworks/search?q=impressionism&fields=id,title,image_id,artist_title,date_display&limit=30');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      // API mengembalikan data dalam List, kita langsung gunakan
      final artworks = List<Map<String, dynamic>>.from(jsonData['data']);
      // Filter hanya yang punya image_id
      return artworks.where((artwork) => artwork['image_id'] != null).toList();
    } else {
      throw Exception('Gagal mengambil data dari API.');
    }
  }

  void _showArtworkDetail(BuildContext context, Map<String, dynamic> artwork, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                // Image
                Flexible(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: CustomNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      borderRadius: 0,
                    ),
                  ),
                ),
                // Details
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artwork['title'] ?? 'Tanpa Judul',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seniman: ${artwork['artist_title'] ?? 'Anonim'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (artwork['date_display'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tahun: ${artwork['date_display']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Sumber: Art Institute of Chicago',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                  _showArtworkDetail(context, artwork, imageUrl);
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tampilkan gambar jika URL ada
                      if (imageUrl.isNotEmpty)
                        AspectRatio(
                          aspectRatio: 1.0,
                          child: CustomNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            borderRadius: 0,
                          ),
                        )
                      else
                        Container(
                          height: 150,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                          ),
                        ),
                      
                      // Tampilkan teks di bawah gambar
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artwork['title'] ?? 'Tanpa Judul',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              artwork['artist_title'] ?? 'Anonim',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (artwork['date_display'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  artwork['date_display'],
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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