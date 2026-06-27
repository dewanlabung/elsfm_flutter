import 'image_helper.dart';

class Genre {
  final int id;
  final String name;
  final String? displayName;
  final String? image;

  Genre({
    required this.id,
    required this.name,
    this.displayName,
    this.image,
  });

  String get label => displayName ?? name;

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      displayName: json['display_name'] as String?,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'image': image,
    };
  }
}
