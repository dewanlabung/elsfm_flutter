class Artist {
  final int id;
  final String name;
  /// Image URL — BeMusic returns this as `image_small` in embedded/list contexts.
  final String? image;
  final int views;

  Artist({
    required this.id,
    required this.name,
    this.image,
    required this.views,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    // BeMusic returns `image_small` in embedded artist objects and list endpoints.
    // `image` may appear in full artist detail responses.
    final imageRaw = json['image_small'] ?? json['image'];
    // `views` and `plays` come as strings from the API (e.g. "711").
    return Artist(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      image: imageRaw as String?,
      views: int.tryParse(json['views']?.toString() ?? '') ?? 0,
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
