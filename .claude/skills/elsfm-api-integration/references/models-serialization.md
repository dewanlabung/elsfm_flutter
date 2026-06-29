# Model Serialization

Pattern for creating Dart models with JSON serialization.

## Track Model (Real Example)

```dart
class Track {
  final int id;
  final String name;
  final String? image;
  final Duration duration;
  final String src;
  final Album? album;
  final List<Artist> artists;
  final int plays;
  final DateTime? createdAt;

  Track({
    required this.id,
    required this.name,
    this.image,
    required this.duration,
    required this.src,
    this.album,
    required this.artists,
    required this.plays,
    this.createdAt,
  });

  // Backend returns duration in milliseconds
  factory Track.fromJson(Map<String, dynamic> json) {
    final durationMs = (json['duration'] as num?)?.toInt() ?? 0;
    return Track(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      duration: Duration(milliseconds: durationMs),
      src: json['src'] as String? ?? json['url'] as String? ?? '',
      album: json['album'] != null
          ? Album.fromJson(json['album'] as Map<String, dynamic>)
          : null,
      artists: (json['artists'] as List<dynamic>?)
              ?.map((e) => Artist.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      plays: int.tryParse(json['plays']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'duration': duration.inMilliseconds,
    'src': src,
    'album': album?.toJson(),
    'artists': artists.map((e) => e.toJson()).toList(),
    'plays': plays,
    'created_at': createdAt?.toIso8601String(),
  };
}
```

## Album Model

```dart
class Album {
  final int id;
  final String name;
  final String? image;
  final List<Artist> artists;
  final int trackCount;
  final DateTime? releaseDate;

  Album({
    required this.id,
    required this.name,
    this.image,
    required this.artists,
    required this.trackCount,
    this.releaseDate,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      artists: (json['artists'] as List<dynamic>?)
              ?.map((e) => Artist.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      trackCount: json['track_count'] as int? ?? 0,
      releaseDate: json['release_date'] != null
          ? DateTime.tryParse(json['release_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'artists': artists.map((e) => e.toJson()).toList(),
    'track_count': trackCount,
    'release_date': releaseDate?.toIso8601String(),
  };
}
```

## Artist Model

```dart
class Artist {
  final int id;
  final String name;
  final String? image;
  final String? bio;
  final int followerCount;

  Artist({
    required this.id,
    required this.name,
    this.image,
    this.bio,
    required this.followerCount,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      bio: json['bio'] as String?,
      followerCount: int.tryParse(json['follower_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': image,
    'bio': bio,
    'follower_count': followerCount,
  };
}
```

## Playlist Model

```dart
class Playlist {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final User? owner;
  final int trackCount;
  final List<Track> tracks;
  final DateTime? createdAt;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.owner,
    required this.trackCount,
    required this.tracks,
    this.createdAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      image: json['image'] as String?,
      owner: json['owner'] != null
          ? User.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
      trackCount: json['track_count'] as int? ?? 0,
      tracks: (json['tracks'] as List<dynamic>?)
              ?.map((e) => Track.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'image': image,
    'owner': owner?.toJson(),
    'track_count': trackCount,
    'tracks': tracks.map((e) => e.toJson()).toList(),
    'created_at': createdAt?.toIso8601String(),
  };
}
```

## User Model

```dart
class User {
  final int id;
  final String name;
  final String email;
  final String? image;
  final bool isEmailVerified;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.image,
    required this.isEmailVerified,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      image: json['image'] as String?,
      isEmailVerified: json['email_verified_at'] != null,
      createdAt: DateTime.tryParse(json['created_at'] as String) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'image': image,
    'email_verified_at': isEmailVerified ? DateTime.now().toIso8601String() : null,
    'created_at': createdAt.toIso8601String(),
  };
}
```

## Response Wrappers

```dart
class BackendResponse<T> {
  final T data;
  final String? message;

  BackendResponse({required this.data, this.message});

  factory BackendResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return BackendResponse(
      data: fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String?,
    );
  }
}

class PaginationMeta {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;

  PaginationMeta({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      total: json['total'] as int,
      perPage: json['per_page'] as int,
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
    );
  }

  bool get hasNextPage => currentPage < lastPage;
}

class PaginationResponse<T> {
  final List<T> data;
  final PaginationMeta? pagination;

  PaginationResponse({
    required this.data,
    this.pagination,
  });

  factory PaginationResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return PaginationResponse(
      data: (json['data'] as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: json['pagination'] != null
          ? PaginationMeta.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}
```

## Key Patterns

1. **Type Coercion:** `(json['duration'] as num?)?.toInt()` — handles string/int/null variations from API
2. **Nullable Fields:** `image: json['image'] as String?` — API may not include field
3. **DateTime Parsing:** `DateTime.tryParse()` — safe parsing with fallback
4. **Nested Models:** Recursively call `fromJson()` for relationships
5. **Default Values:** Provide sensible defaults when data missing (`?? ''`, `?? 0`, `?? []`)
6. **Snake Case Conversion:** `track_count` → `trackCount` (Dart convention)
