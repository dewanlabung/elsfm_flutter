import 'user.dart';

class Playlist {
  final int id;
  final String name;
  final String? description;
  final User? owner;
  final String? image;
  final int trackCount;
  final bool collaborative;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.owner,
    this.image,
    required this.trackCount,
    required this.collaborative,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      owner: json['owner'] != null ? User.fromJson(json['owner'] as Map<String, dynamic>) : null,
      image: json['image'] as String?,
      trackCount: (json['track_count'] as num?)?.toInt() ?? 0,
      collaborative: json['collaborative'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'owner': owner?.toJson(),
      'image': image,
      'track_count': trackCount,
      'collaborative': collaborative,
    };
  }
}
