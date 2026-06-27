/// Audio quality options for streaming
class QualityOption {
  final String id;
  final String label;
  final int bitrate; // in kbps
  final String format; // "AAC", "MP3", "FLAC", etc.

  QualityOption({
    required this.id,
    required this.label,
    required this.bitrate,
    required this.format,
  });

  factory QualityOption.fromJson(Map<String, dynamic> json) {
    return QualityOption(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      bitrate: (json['bitrate'] as num?)?.toInt() ?? 128,
      format: json['format'] as String? ?? 'AAC',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'bitrate': bitrate,
      'format': format,
    };
  }

  @override
  String toString() => '$label ($bitrate kbps $format)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QualityOption &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          bitrate == other.bitrate;

  @override
  int get hashCode => id.hashCode ^ bitrate.hashCode;
}
