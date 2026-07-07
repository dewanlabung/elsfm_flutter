import 'album.dart';
import 'artist.dart';
import 'image_helper.dart';

class Track {
  final int id;
  final String name;
  final String? image;
  final Duration duration;
  /// Stream URL — not present in list/detail responses.
  /// Set externally when playback is requested via the stream endpoint.
  final String src;
  final Album? album;
  final List<Artist> artists;
  /// `plays` comes as a string from the API (e.g. "75").
  final int plays;
  final DateTime? createdAt;

  Track({
    required this.id,
    required this.name,
    this.image,
    required this.duration,
    required this.src,
    this.album,
    required this.artists,
    required this.plays,
    this.createdAt,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    // BeMusic stores duration in milliseconds (e.g. 348000 = 5m48s).
    final durationMs = (json['duration'] as num?)?.toInt() ?? 0;
    // BeMusic returns src as a relative path, e.g. "storage/track_media/xxx.mp3".
    // Matches elsfm-native: MediaItem.Builder().setUri(baseUrl + src)
    //   where baseUrl = "https://www.elsfm.com/" (trailing slash included).
    // Do NOT add "/storage/" prefix — the API path already starts with "storage/".
    final rawSrc = json['src'] as String? ?? json['url'] as String? ?? '';
    final src = rawSrc.startsWith('http') ? rawSrc
        : rawSrc.isNotEmpty ? 'https://www.elsfm.com/$rawSrc'
        : '';
    return Track(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      image: resolveImageUrl(json['image'] as String?),
      duration: Duration(milliseconds: durationMs),
      src: src,
      album: json['album'] != null
          ? Album.fromJson(json['album'] as Map<String, dynamic>)
          : null,
      artists: (json['artists'] as List<dynamic>?)
              ?.map((e) => Artist.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      // `plays` is returned as a string (e.g. "75"), not an int.
      plays: int.tryParse(json['plays']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'duration': duration.inMilliseconds,
      'src': src,
      'album': album?.toJson(),
      'artists': artists.map((e) => e.toJson()).toList(),
      'plays': plays,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
