import 'image_helper.dart';

class PlaylistEditor {
  final int id;
  final String name;
  final String? image;

  PlaylistEditor({required this.id, required this.name, this.image});

  factory PlaylistEditor.fromJson(Map<String, dynamic> json) {
    return PlaylistEditor(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      image: resolveImageUrl(json['image'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'image': image};
}

class Playlist {
  final int id;
  final String name;
  final bool isPublic;
  final bool collaborative;
  final String? image;
  /// `views` comes as a string from the API (e.g. "220").
  final int views;
  final int? ownerId;
  final List<PlaylistEditor> editors;

  Playlist({
    required this.id,
    required this.name,
    required this.isPublic,
    required this.collaborative,
    this.image,
    required this.views,
    this.ownerId,
    required this.editors,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      isPublic: json['public'] as bool? ?? false,
      collaborative: json['collaborative'] as bool? ?? false,
      image: resolveImageUrl(json['image'] as String?),
      // `views` is returned as a string (e.g. "220").
      views: int.tryParse(json['views']?.toString() ?? '0') ?? 0,
      ownerId: (json['owner_id'] as num?)?.toInt(),
      editors: (json['editors'] as List<dynamic>?)
              ?.map((e) => PlaylistEditor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'public': isPublic,
      'collaborative': collaborative,
      'image': image,
      'views': views,
      'owner_id': ownerId,
      'editors': editors.map((e) => e.toJson()).toList(),
    };
  }
}
