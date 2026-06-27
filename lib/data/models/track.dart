import 'album.dart';
import 'artist.dart';

class Track {
  final int id;
  final String name;
  final Duration duration;
  final String src;
  final Album? album;
  final List<Artist> artists;
  final int views;
  final DateTime? createdAt;

  Track({
    required this.id,
    required this.name,
    required this.duration,
    required this.src,
    this.album,
    required this.artists,
    required this.views,
    this.createdAt,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      duration: Duration(
        seconds: (json['duration'] as num?)?.toInt() ?? 0,
      ),
      src: json['src'] as String? ?? '',
      album: json['album'] != null ? Album.fromJson(json['album'] as Map<String, dynamic>) : null,
      artists: (json['artists'] as List<dynamic>?)
              ?.map((e) => Artist.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      views: (json['views'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'duration': duration.inSeconds,
      'src': src,
      'album': album?.toJson(),
      'artists': artists.map((e) => e.toJson()).toList(),
      'views': views,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
