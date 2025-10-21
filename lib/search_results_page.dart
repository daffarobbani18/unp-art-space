import 'package:flutter/material.dart';
import 'Features/profile/screens/artist_detail_page.dart';
import 'Features/artwork/screens/artwork_detail_page.dart';

class SearchResultsPage extends StatelessWidget {
  final String query;
  final List<Map<String, dynamic>> artistResults;
  final List<Map<String, dynamic>> artworkResults;

  const SearchResultsPage({
    super.key,
    required this.query,
    required this.artistResults,
    required this.artworkResults,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hasil untuk "$query"'),
      ),
      body: ListView(
        children: [
          // Bagian Hasil Seniman
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Seniman Ditemukan', style: Theme.of(context).textTheme.titleLarge),
          ),
          if (artistResults.isEmpty)
            const ListTile(title: Text('Tidak ada seniman yang cocok.'))
          else
            ...artistResults.map((artist) => ListTile(
                  leading: CircleAvatar(child: Text(artist['name']?[0] ?? '')),
                  title: Text(artist['name'] ?? ''),
                  onTap: () {
                    Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ArtistDetailPage(artistId: artist['id']),
                    ),
                  );
                   },
                )),

          const Divider(),

          // Bagian Hasil Karya Seni
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Karya Ditemukan', style: Theme.of(context).textTheme.titleLarge),
          ),
          if (artworkResults.isEmpty)
            const ListTile(title: Text('Tidak ada karya yang cocok.'))
          else
            ...artworkResults.map((artwork) => ListTile(
                  leading: Image.network(artwork['media_url'] ?? artwork['image_url'] ?? '', width: 50, fit: BoxFit.cover),
                  title: Text(artwork['title'] ?? ''),
                  subtitle: Text(artwork['users']?['name'] ?? 'Seniman'),
                  onTap: () {
                    Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ArtworkDetailPage(artwork: artwork),
                    ),
                  );
                  },
                )),
        ],
      ),
    );
  }
}