import 'track.dart';

/// Recommendation playlist (Release Radar, Discover Weekly, etc.)
class Recommendation {
  final String id;
  final String type; // "release_radar", "discover_weekly", "top_hits", etc.
  final String title;
  final String? description;
  final String? artwork;
  final List<Track> tracks;
  final DateTime createdAt;
  final DateTime? refreshedAt;

  Recommendation({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.artwork,
    required this.tracks,
    required this.createdAt,
    this.refreshedAt,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      artwork: json['artwork'] as String?,
      tracks: (json['tracks'] as List<dynamic>?)
              ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      refreshedAt: json['refreshed_at'] != null ? DateTime.tryParse(json['refreshed_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'artwork': artwork,
      'tracks': tracks.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'refreshed_at': refreshedAt?.toIso8601String(),
    };
  }

  @override
  String toString() => 'Recommendation($type: $title - ${tracks.length} tracks)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recommendation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;
}
