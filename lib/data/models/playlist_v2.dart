import 'track.dart';
import 'user.dart';

/// Enhanced Playlist model for Phase 2 with full track list, timestamps, and offline support
class PlaylistV2 {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final User? owner;
  final String? artwork;
  final List<Track> tracks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOfflineEnabled;
  final bool isCollaborative;
  final bool isDeleted; // Soft delete support
  final int? version; // For version history

  PlaylistV2({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.owner,
    this.artwork,
    required this.tracks,
    required this.createdAt,
    required this.updatedAt,
    required this.isOfflineEnabled,
    required this.isCollaborative,
    required this.isDeleted,
    this.version,
  });

  int get trackCount => tracks.length;

  factory PlaylistV2.fromJson(Map<String, dynamic> json) {
    return PlaylistV2(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Untitled Playlist',
      description: json['description'] as String?,
      owner: json['owner'] != null ? User.fromJson(json['owner'] as Map<String, dynamic>) : null,
      artwork: json['artwork'] as String?,
      tracks: (json['tracks'] as List<dynamic>?)
              ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      isOfflineEnabled: json['is_offline_enabled'] as bool? ?? false,
      isCollaborative: json['is_collaborative'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      version: (json['version'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'owner': owner?.toJson(),
      'artwork': artwork,
      'tracks': tracks.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_offline_enabled': isOfflineEnabled,
      'is_collaborative': isCollaborative,
      'is_deleted': isDeleted,
      'version': version,
    };
  }

  PlaylistV2 copyWith({
    String? name,
    String? description,
    String? artwork,
    List<Track>? tracks,
    bool? isOfflineEnabled,
    bool? isCollaborative,
    bool? isDeleted,
  }) {
    return PlaylistV2(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      owner: owner,
      artwork: artwork ?? this.artwork,
      tracks: tracks ?? this.tracks,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isOfflineEnabled: isOfflineEnabled ?? this.isOfflineEnabled,
      isCollaborative: isCollaborative ?? this.isCollaborative,
      isDeleted: isDeleted ?? this.isDeleted,
      version: (version ?? 0) + 1,
    );
  }

  PlaylistV2 addTrack(Track track) {
    if (tracks.any((t) => t.id == track.id)) {
      return this; // Prevent duplicates
    }
    return copyWith(tracks: [...tracks, track]);
  }

  PlaylistV2 removeTrack(int trackId) {
    return copyWith(tracks: tracks.where((t) => t.id != trackId).toList());
  }

  PlaylistV2 reorderTrack(int oldIndex, int newIndex) {
    final List<Track> newTracks = [...tracks];
    final track = newTracks.removeAt(oldIndex);
    newTracks.insert(newIndex, track);
    return copyWith(tracks: newTracks);
  }

  @override
  String toString() => 'Playlist($name - ${tracks.length} tracks, v$version)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistV2 &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode;
}
