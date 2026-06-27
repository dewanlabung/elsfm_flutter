class Artist {
  final int id;
  final String name;
  final String? image;
  final int views;

  Artist({
    required this.id,
    required this.name,
    this.image,
    required this.views,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      views: (json['views'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'views': views,
    };
  }
}
