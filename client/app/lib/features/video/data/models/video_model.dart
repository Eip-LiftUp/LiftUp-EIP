import '../../domain/entities/video_entity.dart';

/// Data model for VideoEntity with JSON serialization support.
/// 
/// This model extends the VideoEntity and provides methods for
/// converting to/from JSON for local storage and API communication.
class VideoModel extends VideoEntity {
  const VideoModel({
    required super.id,
    required super.localPath,
    required super.title,
    super.description,
    required super.durationInSeconds,
    required super.sizeInBytes,
    super.thumbnailPath,
    super.uploadStatus,
    super.uploadProgress,
    super.remoteUrl,
    required super.createdAt,
  });

  /// Create a VideoModel from a JSON map
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] as String,
      localPath: json['localPath'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      durationInSeconds: json['durationInSeconds'] as int,
      sizeInBytes: json['sizeInBytes'] as int,
      thumbnailPath: json['thumbnailPath'] as String?,
      uploadStatus: VideoUploadStatus.values.firstWhere(
        (e) => e.name == json['uploadStatus'],
        orElse: () => VideoUploadStatus.pending,
      ),
      uploadProgress: (json['uploadProgress'] as num?)?.toDouble() ?? 0.0,
      remoteUrl: json['remoteUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert the VideoModel to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localPath': localPath,
      'title': title,
      'description': description,
      'durationInSeconds': durationInSeconds,
      'sizeInBytes': sizeInBytes,
      'thumbnailPath': thumbnailPath,
      'uploadStatus': uploadStatus.name,
      'uploadProgress': uploadProgress,
      'remoteUrl': remoteUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a VideoModel from a VideoEntity
  factory VideoModel.fromEntity(VideoEntity entity) {
    return VideoModel(
      id: entity.id,
      localPath: entity.localPath,
      title: entity.title,
      description: entity.description,
      durationInSeconds: entity.durationInSeconds,
      sizeInBytes: entity.sizeInBytes,
      thumbnailPath: entity.thumbnailPath,
      uploadStatus: entity.uploadStatus,
      uploadProgress: entity.uploadProgress,
      remoteUrl: entity.remoteUrl,
      createdAt: entity.createdAt,
    );
  }
}
