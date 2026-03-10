import '../entities/video_entity.dart';

/// Abstract repository interface for video operations.
/// 
/// This repository defines the contract for video-related operations
/// including recording, importing, and uploading videos.
abstract class VideoRepository {
  /// Get all locally stored videos
  Future<List<VideoEntity>> getLocalVideos();

  /// Get a video by its ID
  Future<VideoEntity?> getVideoById(String id);

  /// Save a video entity to local storage
  Future<void> saveVideo(VideoEntity video);

  /// Delete a video by its ID
  Future<void> deleteVideo(String id);

  /// Upload a video to the remote server
  /// Returns a stream of upload progress (0.0 - 1.0)
  Stream<double> uploadVideo(VideoEntity video);

  /// Cancel an ongoing upload
  Future<void> cancelUpload(String videoId);

  /// Generate a thumbnail for a video
  Future<String?> generateThumbnail(String videoPath);

  /// Get video metadata (duration, size, etc.)
  Future<Map<String, dynamic>> getVideoMetadata(String videoPath);
}
