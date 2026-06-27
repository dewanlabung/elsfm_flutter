import 'artist.dart';

class Album {
  final int id;
  final String name;
  final String? image;
  final int? releaseYear;
  final List<Artist> artists;
  final int views;

  Album({
    required this.id,
    required this.name,
    this.image,
    this.releaseYear,
    required this.artists,
    required this.views,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      releaseYear: json['release_year'] as int?,
      artists: (json['artists'] as List<dynamic>?)
              ?.map((e) => Artist.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      views: (json['views'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'release_year': releaseYear,
      'artists': artists.map((e) => e.toJson()).toList(),
      'views': views,
    };
  }
}
