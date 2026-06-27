import 'package:flutter/material.dart';
import '../services/search_service.dart';
import '../models/search_state.dart';

/// Trending content display widget
class TrendingSection extends StatelessWidget {
  final TrendingResults trending;

  const TrendingSection({
    super.key,
    required this.trending,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (trending.songs.isNotEmpty) ...[
          const Text(
            'Trending Songs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...trending.songs.asMap().entries.map((entry) {
            final index = entry.key;
            final song = entry.value;
            return ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),
              title: Text(song.name),
              subtitle: Text(
                song.artists.map((a) => a.name).join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                // Play song
              },
            );
          }),
          const SizedBox(height: 24),
        ],
        if (trending.artists.isNotEmpty) ...[
          const Text(
            'Trending Artists',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: trending.artists.length,
              itemBuilder: (context, index) {
                final artist = trending.artists[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      // Open artist
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(Icons.person, size: 32),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 100,
                          child: Text(
                            artist.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
