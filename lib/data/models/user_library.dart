import 'track.dart';

/// User's library entry for a track (favorite, history, etc.)
class UserLibraryEntry {
  final int trackId;
  final String entryType; // "favorite", "history"
  final DateTime addedAt;
  final int? durationPlayedSeconds; // Only for history

  UserLibraryEntry({
    required this.trackId,
    required this.entryType,
    required this.addedAt,
    this.durationPlayedSeconds,
  });

  factory UserLibraryEntry.fromJson(Map<String, dynamic> json) {
    return UserLibraryEntry(
      trackId: (json['track_id'] as num?)?.toInt() ?? 0,
      entryType: json['entry_type'] as String? ?? 'favorite',
      addedAt: DateTime.tryParse(json['added_at'] as String? ?? '') ?? DateTime.now(),
      durationPlayedSeconds: (json['duration_played_seconds'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'track_id': trackId,
      'entry_type': entryType,
      'added_at': addedAt.toIso8601String(),
      'duration_played_seconds': durationPlayedSeconds,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserLibraryEntry &&
          runtimeType == other.runtimeType &&
          trackId == other.trackId &&
          entryType == other.entryType;

  @override
  int get hashCode => trackId.hashCode ^ entryType.hashCode;
}

/// User's complete library (favorites, history, statistics)
class UserLibrary {
  final List<Track> favorites;
  final List<Track> recentHistory;
  final Map<int, int> trackPlayCounts; // track_id -> play_count
  final DateTime lastUpdated;

  UserLibrary({
    required this.favorites,
    required this.recentHistory,
    required this.trackPlayCounts,
    required this.lastUpdated,
  });

  factory UserLibrary.fromJson(Map<String, dynamic> json) {
    return UserLibrary(
      favorites: (json['favorites'] as List<dynamic>?)
              ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentHistory: (json['recent_history'] as List<dynamic>?)
              ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      trackPlayCounts: Map<int, int>.from(
        (json['track_play_counts'] as Map?)?.cast<String, dynamic>().map(
              (k, v) => MapEntry(int.parse(k as String), (v as num).toInt()),
            ) ??
            {},
      ),
      lastUpdated: DateTime.tryParse(json['last_updated'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favorites': favorites.map((e) => e.toJson()).toList(),
      'recent_history': recentHistory.map((e) => e.toJson()).toList(),
      'track_play_counts': trackPlayCounts.map((k, v) => MapEntry(k.toString(), v)),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  bool isFavorite(int trackId) => favorites.any((t) => t.id == trackId);

  int getPlayCount(int trackId) => trackPlayCounts[trackId] ?? 0;

  @override
  String toString() =>
      'UserLibrary(favorites: ${favorites.length}, history: ${recentHistory.length})';
}
