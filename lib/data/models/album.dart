import 'artist.dart';
import 'image_helper.dart';

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
    // API returns `release_date` as an ISO-8601 datetime string, not `release_year`.
    int? releaseYear;
    final releaseDateRaw = json['release_date'] as String?;
    if (releaseDateRaw != null) {
      releaseYear = DateTime.tryParse(releaseDateRaw)?.year;
    } else {
      releaseYear = (json['release_year'] as num?)?.toInt();
    }
    return Album(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      image: resolveImageUrl(json['image'] as String?),
      releaseYear: releaseYear,
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
