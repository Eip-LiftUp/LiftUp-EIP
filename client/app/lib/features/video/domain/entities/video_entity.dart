import 'package:flutter/foundation.dart';

/// Represents a video entity in the application.
/// 
/// This entity contains metadata about the video including
/// its local path, title, duration, and upload status.
@immutable
class VideoEntity {
  /// Unique identifier for the video
  final String id;

  /// Local file path of the video
  final String localPath;

  /// Title/name of the video
  final String title;

  /// Description of the video content
  final String? description;

  /// Duration of the video in seconds
  final int durationInSeconds;

  /// Size of the video file in bytes
  final int sizeInBytes;

  /// Thumbnail path for the video preview
  final String? thumbnailPath;

  /// Current upload status of the video
  final VideoUploadStatus uploadStatus;

  /// Upload progress (0.0 - 1.0)
  final double uploadProgress;

  /// Remote URL after successful upload
  final String? remoteUrl;

  /// Creation timestamp
  final DateTime createdAt;

  const VideoEntity({
    required this.id,
    required this.localPath,
    required this.title,
    this.description,
    required this.durationInSeconds,
    required this.sizeInBytes,
    this.thumbnailPath,
    this.uploadStatus = VideoUploadStatus.pending,
    this.uploadProgress = 0.0,
    this.remoteUrl,
    required this.createdAt,
  });

  /// Get formatted duration string (MM:SS)
  String get formattedDuration {
    final minutes = durationInSeconds ~/ 60;
    final seconds = durationInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get formatted file size string
  String get formattedSize {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  VideoEntity copyWith({
    String? id,
    String? localPath,
    String? title,
    String? description,
    int? durationInSeconds,
    int? sizeInBytes,
    String? thumbnailPath,
    VideoUploadStatus? uploadStatus,
    double? uploadProgress,
    String? remoteUrl,
    DateTime? createdAt,
  }) {
    return VideoEntity(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      title: title ?? this.title,
      description: description ?? this.description,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Enum representing the upload status of a video
enum VideoUploadStatus {
  /// Video is pending upload
  pending,

  /// Video is currently being uploaded
  uploading,

  /// Video was successfully uploaded
  uploaded,

  /// Video upload failed
  failed,

  /// Video upload was cancelled
  cancelled,
}
