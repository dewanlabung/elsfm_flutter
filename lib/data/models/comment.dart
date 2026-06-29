import 'user.dart';

class Comment {
  final int id;
  final String content;
  final int position;
  final int depth;
  final bool deleted;
  final User? user;

  Comment({
    required this.id,
    required this.content,
    required this.position,
    required this.depth,
    required this.deleted,
    this.user,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: (json['id'] as num).toInt(),
      content: json['content'] as String? ?? '',
      position: (json['position'] as num?)?.toInt() ?? 0,
      depth: (json['depth'] as num?)?.toInt() ?? 0,
      deleted: json['deleted'] as bool? ?? false,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'position': position,
        'depth': depth,
        'deleted': deleted,
        'user': user?.toJson(),
      };
}
