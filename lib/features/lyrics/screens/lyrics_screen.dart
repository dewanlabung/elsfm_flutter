import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/track.dart';
import '../../../data/providers/api_client_provider.dart';

final _lyricsProvider = FutureProvider.family<Map<String, dynamic>?, int>((ref, trackId) async {
  return ref.watch(apiClientProvider).getTrackLyrics(trackId);
});

class LyricsScreen extends ConsumerWidget {
  final Track track;
  const LyricsScreen({super.key, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyricsAsync = ref.watch(_lyricsProvider(track.id));
    final imageUrl = _resolveImg(track.image);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(track.name,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            if (track.artists.isNotEmpty)
              Text(
                track.artists.map((a) => a.name).join(', '),
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      body: lyricsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF689F38)),
        ),
        error: (e, _) => _NoLyrics(trackName: track.name),
        data: (data) {
          if (data == null) return _NoLyrics(trackName: track.name);
          final lyrics = data['lyrics'] as Map<String, dynamic>?;
          if (lyrics == null) return _NoLyrics(trackName: track.name);
          final text = lyrics['text'] as String? ?? '';
          if (text.trim().isEmpty) return _NoLyrics(trackName: track.name);
          return _LyricsView(text: text, imageUrl: imageUrl);
        },
      ),
    );
  }

  String _resolveImg(String? img) {
    if (img == null || img.isEmpty) return '';
    if (img.startsWith('http')) return img;
    return 'https://www.elsfm.com/$img';
  }
}

class _LyricsView extends StatelessWidget {
  final String text;
  final String imageUrl;
  const _LyricsView({required this.text, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    // Strip LRC timestamps if present: [00:01.23]
    final cleaned = text.replaceAll(RegExp(r'\[\d{2}:\d{2}[.:]\d{2,3}\]'), '').trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album art thumbnail
          if (imageUrl.isNotEmpty)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, width: 120, height: 120, fit: BoxFit.cover),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            cleaned,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 2.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoLyrics extends StatelessWidget {
  final String trackName;
  const _NoLyrics({required this.trackName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lyrics_outlined, size: 64, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No lyrics available',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            trackName,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
