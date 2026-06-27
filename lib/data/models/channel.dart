import 'image_helper.dart';

class Channel {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final String contentType;

  Channel({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.contentType,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      image: resolveImageUrl(json['image'] as String?),
      contentType: json['content_type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'content_type': contentType,
    };
  }
}
