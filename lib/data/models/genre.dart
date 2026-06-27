class Genre {
  final int id;
  final String name;
  final String? image;

  Genre({
    required this.id,
    required this.name,
    this.image,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
    };
  }
}
