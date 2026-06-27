import 'package:hive/hive.dart';

part 'download.g.dart';

@HiveType(typeId: 1)
enum DownloadStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  downloading,
  @HiveField(2)
  completed,
  @HiveField(3)
  failed,
}

@HiveType(typeId: 0)
class Download {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int trackId;

  @HiveField(2)
  final String trackName;

  @HiveField(3)
  final String downloadUrl;

  @HiveField(4)
  final DownloadStatus status;

  @HiveField(5)
  final double progress; // 0.0 to 1.0

  @HiveField(6)
  final int? fileSizeBytes;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime? completedAt;

  Download({
    required this.id,
    required this.trackId,
    required this.trackName,
    required this.downloadUrl,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.fileSizeBytes,
    required this.createdAt,
    this.completedAt,
  });

  Download copyWith({
    int? id,
    int? trackId,
    String? trackName,
    String? downloadUrl,
    DownloadStatus? status,
    double? progress,
    int? fileSizeBytes,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Download(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      trackName: trackName ?? this.trackName,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
