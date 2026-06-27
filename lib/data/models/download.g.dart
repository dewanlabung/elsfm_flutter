// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadStatusAdapter extends TypeAdapter<DownloadStatus> {
  @override
  final int typeId = 1;

  @override
  DownloadStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DownloadStatus.pending;
      case 1:
        return DownloadStatus.downloading;
      case 2:
        return DownloadStatus.completed;
      case 3:
        return DownloadStatus.failed;
      default:
        return DownloadStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, DownloadStatus obj) {
    switch (obj) {
      case DownloadStatus.pending:
        writer.writeByte(0);
        break;
      case DownloadStatus.downloading:
        writer.writeByte(1);
        break;
      case DownloadStatus.completed:
        writer.writeByte(2);
        break;
      case DownloadStatus.failed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DownloadAdapter extends TypeAdapter<Download> {
  @override
  final int typeId = 0;

  @override
  Download read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Download(
      id: fields[0] as int,
      trackId: fields[1] as int,
      trackName: fields[2] as String,
      downloadUrl: fields[3] as String,
      status: fields[4] as DownloadStatus? ?? DownloadStatus.pending,
      progress: fields[5] as double? ?? 0.0,
      fileSizeBytes: fields[6] as int?,
      createdAt: fields[7] as DateTime,
      completedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Download obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.trackId)
      ..writeByte(2)
      ..write(obj.trackName)
      ..writeByte(3)
      ..write(obj.downloadUrl)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.progress)
      ..writeByte(6)
      ..write(obj.fileSizeBytes)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
