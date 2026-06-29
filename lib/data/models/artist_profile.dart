/// Full artist detail with profile, images, and links as returned by GET /artists/{id}
/// with `with=similar,genres,albums,topTracks`.
class ArtistProfile {
  final int id;
  final String description;
  final String? city;
  final String? country;

  ArtistProfile({
    required this.id,
    required this.description,
    this.city,
    this.country,
  });

  factory ArtistProfile.fromJson(Map<String, dynamic> json) {
    return ArtistProfile(
      id: (json['id'] as num).toInt(),
      description: json['description'] as String? ?? '',
      city: json['city'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'city': city,
        'country': country,
      };
}

class ArtistProfileImage {
  final int id;
  final String url;

  ArtistProfileImage({required this.id, required this.url});

  factory ArtistProfileImage.fromJson(Map<String, dynamic> json) {
    return ArtistProfileImage(
      id: (json['id'] as num).toInt(),
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'url': url};
}

class ArtistProfileLink {
  final int id;
  final String url;
  final String title;

  ArtistProfileLink({
    required this.id,
    required this.url,
    required this.title,
  });

  factory ArtistProfileLink.fromJson(Map<String, dynamic> json) {
    return ArtistProfileLink(
      id: (json['id'] as num).toInt(),
      url: json['url'] as String? ?? '',
      title: json['title'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'url': url, 'title': title};
}
