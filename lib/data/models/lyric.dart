class Lyric {
  final int id;
  final String text;

  Lyric({required this.id, required this.text});

  factory Lyric.fromJson(Map<String, dynamic> json) {
    return Lyric(
      id: (json['id'] as num).toInt(),
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'text': text};
}
