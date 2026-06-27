import 'image_helper.dart';

class Artist {
  final int id;
  final String name;
  /// Image URL — BeMusic returns `image_small` in list/embedded contexts.
  /// Falls back to `image` for full detail responses.
  final String? image;
  /// `views` comes as a string from the API (e.g. "711").
  final int views;
  /// `plays` comes as a string from the API (e.g. "1712").
  final int plays;

  Artist({
    required this.id,
    required this.name,
    this.image,
    required this.views,
    required this.plays,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    // BeMusic returns `image_small` in embedded artist objects and list endpoints.
    // `image` may appear in full artist detail responses.
    final imageRaw = json['image_small'] ?? json['image'];
    // `views` and `plays` come as strings from the API (e.g. "711", "1712").
    return Artist(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      image: resolveImageUrl(imageRaw as String?),
      views: int.tryParse(json['views']?.toString() ?? '0') ?? 0,
      plays: int.tryParse(json['plays']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'views': views,
      'plays': plays,
    };
  }
}
