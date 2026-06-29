import 'package:elsfm/data/models/recommendation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recommendation_provider.dart';

/// Recommendations screen (Release Radar, Discover Weekly, etc.)
class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredAsync = ref.watch(featuredRecommendationsProvider);
    final moodAsync = ref.watch(moodPlaylistsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('For You'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(featuredRecommendationsProvider);
          ref.invalidate(moodPlaylistsProvider);
        },
        child: ListView(
          children: [
            // Featured Recommendations
            featuredAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $error'),
              ),
              data: (recommendations) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Featured',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  ...recommendations.map((rec) {
                    return _buildRecommendationCard(context, rec);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Mood Playlists
            moodAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
              data: (moods) => moods.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Mood Playlists',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: moods.length,
                            itemBuilder: (context, index) {
                              final mood = moods[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _buildMoodCard(context, mood),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, Recommendation recommendation) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.playlist_play),
        ),
        title: Text(recommendation.title),
        subtitle: Text('${recommendation.tracks.length} songs'),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          // Open recommendation playlist
        },
      ),
    );
  }

  Widget _buildMoodCard(BuildContext context, Recommendation mood) {
    return GestureDetector(
      onTap: () {
        // Open mood playlist
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mood, size: 48),
            const SizedBox(height: 8),
            Text(
              mood.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
