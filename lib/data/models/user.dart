import 'image_helper.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final bool emailVerified;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.emailVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final avatarRaw = json['avatar'] as String?;
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatar: (avatarRaw == null || avatarRaw.isEmpty)
          ? null
          : resolveImageUrl(avatarRaw),
      emailVerified: json['email_verified_at'] != null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'email_verified_at': emailVerified ? DateTime.now().toIso8601String() : null,
    };
  }
}
