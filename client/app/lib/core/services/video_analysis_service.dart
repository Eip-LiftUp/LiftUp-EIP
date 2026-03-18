import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Video Analysis API Service
///
/// Handles communication with the Python AI service for
/// I3D-based video analysis and movement quality assessment.
class VideoAnalysisService {
  static final VideoAnalysisService _instance = VideoAnalysisService._internal();
  late final Dio _dio;

  /// Base URL for the AI/ML service (Python FastAPI)
  static String get aiServiceUrl {
    if (kIsWeb) {
      return 'http://localhost:8001';
    }

    try {
      if (Platform.isAndroid) {
        // Android Physical Device: Same IP as backend, port 8001
        return 'http://10.73.190.241:8001';
      } else if (Platform.isIOS) {
        return 'http://localhost:8001';
      } else {
        return 'http://localhost:8001';
      }
    } catch (e) {
      return 'http://localhost:8001';
    }
  }

  factory VideoAnalysisService() {
    return _instance;
  }

  VideoAnalysisService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: aiServiceUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120), // Longer for video processing
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => print('[VideoAnalysis API] $obj'),
      ),
    );
  }

  /// Analyze a video file using I3D model
  ///
  /// Returns analysis results including:
  /// - quality_score: Overall movement quality (0-100)
  /// - detected_exercise: Detected exercise type
  /// - form_scores: Scores for depth, alignment, stability, tempo, range_of_motion
  /// - feedback: List of detailed feedback comments
  ///
  /// [videoPath] Path to the local video file
  /// [exerciseType] Optional hint for expected exercise type
  /// [onProgress] Optional callback for upload progress (0.0 - 1.0)
  Future<VideoAnalysisResult> analyzeVideo({
    required String videoPath,
    String? exerciseType,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) {
        throw VideoAnalysisException('Video file not found: $videoPath');
      }

      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(
          videoPath,
          filename: videoPath.split(Platform.pathSeparator).last,
        ),
        if (exerciseType != null) 'exercise_type': exerciseType,
      });

      final response = await _dio.post(
        '/api/v1/video/analyze',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200) {
        return VideoAnalysisResult.fromJson(response.data);
      } else {
        throw VideoAnalysisException(
          'Analysis failed with status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final detail = e.response?.data['detail'] ?? e.message;
        throw VideoAnalysisException('Analysis failed: $detail');
      }
      throw VideoAnalysisException('Network error: ${e.message}');
    } catch (e) {
      if (e is VideoAnalysisException) rethrow;
      throw VideoAnalysisException('Unexpected error: $e');
    }
  }

  /// Analyze a video from a URL
  Future<VideoAnalysisResult> analyzeVideoUrl({
    required String videoUrl,
    String? exerciseType,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/video/analyze-url',
        data: {
          'video_url': videoUrl,
          if (exerciseType != null) 'exercise_type': exerciseType,
        },
      );

      if (response.statusCode == 200) {
        return VideoAnalysisResult.fromJson(response.data);
      } else {
        throw VideoAnalysisException(
          'Analysis failed with status ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      final detail = e.response?.data['detail'] ?? e.message;
      throw VideoAnalysisException('Analysis failed: $detail');
    }
  }

  /// Get list of supported exercises
  Future<List<String>> getSupportedExercises() async {
    try {
      final response = await _dio.get('/api/v1/video/supported-exercises');
      if (response.statusCode == 200) {
        return List<String>.from(response.data['exercises'] ?? []);
      }
      return [];
    } catch (e) {
      print('[VideoAnalysis] Failed to get supported exercises: $e');
      return [];
    }
  }

  /// Check if the AI service is healthy
  Future<bool> isServiceHealthy() async {
    try {
      final response = await _dio.get('/api/v1/video/health');
      return response.statusCode == 200 &&
          response.data['status'] == 'healthy';
    } catch (e) {
      return false;
    }
  }
}

/// Video analysis result model
class VideoAnalysisResult {
  final String analysisId;
  final String timestamp;
  final double qualityScore;
  final String detectedExercise;
  final double detectionConfidence;
  final FormScores formScores;
  final List<FeedbackComment> feedback;
  final AnalysisMetrics metrics;
  final String? annotatedVideoUrl;

  VideoAnalysisResult({
    required this.analysisId,
    required this.timestamp,
    required this.qualityScore,
    required this.detectedExercise,
    required this.detectionConfidence,
    required this.formScores,
    required this.feedback,
    required this.metrics,
    this.annotatedVideoUrl,
  });

  factory VideoAnalysisResult.fromJson(Map<String, dynamic> json) {
    return VideoAnalysisResult(
      analysisId: json['analysis_id'] ?? '',
      timestamp: json['timestamp'] ?? '',
      qualityScore: (json['quality_score'] ?? 0).toDouble(),
      detectedExercise: json['detected_exercise'] ?? 'unknown',
      detectionConfidence: (json['detection_confidence'] ?? 0).toDouble(),
      formScores: FormScores.fromJson(json['form_scores'] ?? {}),
      feedback: (json['feedback'] as List? ?? [])
          .map((f) => FeedbackComment.fromJson(f))
          .toList(),
      metrics: AnalysisMetrics.fromJson(json['metrics'] ?? {}),
      annotatedVideoUrl: json['annotated_video_url'],
    );
  }

  /// Get the overall grade based on quality score
  String get grade {
    if (qualityScore >= 90) return 'A+';
    if (qualityScore >= 80) return 'A';
    if (qualityScore >= 70) return 'B';
    if (qualityScore >= 60) return 'C';
    if (qualityScore >= 50) return 'D';
    return 'F';
  }

  /// Get color for the quality score
  String get scoreColor {
    if (qualityScore >= 80) return 'green';
    if (qualityScore >= 60) return 'yellow';
    return 'red';
  }
}

/// Form scores for different aspects
class FormScores {
  final double depth;
  final double alignment;
  final double stability;
  final double tempo;
  final double rangeOfMotion;

  FormScores({
    required this.depth,
    required this.alignment,
    required this.stability,
    required this.tempo,
    required this.rangeOfMotion,
  });

  factory FormScores.fromJson(Map<String, dynamic> json) {
    return FormScores(
      depth: (json['depth'] ?? 0).toDouble(),
      alignment: (json['alignment'] ?? 0).toDouble(),
      stability: (json['stability'] ?? 0).toDouble(),
      tempo: (json['tempo'] ?? 0).toDouble(),
      rangeOfMotion: (json['range_of_motion'] ?? 0).toDouble(),
    );
  }

  /// Get the lowest scoring aspect
  String get weakestAspect {
    final scores = {
      'depth': depth,
      'alignment': alignment,
      'stability': stability,
      'tempo': tempo,
      'range_of_motion': rangeOfMotion,
    };
    return scores.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  /// Get the highest scoring aspect
  String get strongestAspect {
    final scores = {
      'depth': depth,
      'alignment': alignment,
      'stability': stability,
      'tempo': tempo,
      'range_of_motion': rangeOfMotion,
    };
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

/// Individual feedback comment
class FeedbackComment {
  final String id;
  final String type; // positive, correction, encouragement, warning
  final String category;
  final String text;
  final double score;
  final int severity;

  FeedbackComment({
    required this.id,
    required this.type,
    required this.category,
    required this.text,
    required this.score,
    required this.severity,
  });

  factory FeedbackComment.fromJson(Map<String, dynamic> json) {
    return FeedbackComment(
      id: json['id'] ?? '',
      type: json['type'] ?? 'correction',
      category: json['category'] ?? 'general',
      text: json['text'] ?? '',
      score: (json['score'] ?? 0).toDouble(),
      severity: json['severity'] ?? 1,
    );
  }

  bool get isPositive => type == 'positive' || type == 'encouragement';
  bool get needsAttention => severity >= 3;
}

/// Analysis processing metrics
class AnalysisMetrics {
  final double videoFps;
  final int totalFrames;
  final int framesAnalyzed;
  final double processingTimeSeconds;
  final String modelDevice;

  AnalysisMetrics({
    required this.videoFps,
    required this.totalFrames,
    required this.framesAnalyzed,
    required this.processingTimeSeconds,
    required this.modelDevice,
  });

  factory AnalysisMetrics.fromJson(Map<String, dynamic> json) {
    return AnalysisMetrics(
      videoFps: (json['video_fps'] ?? 0).toDouble(),
      totalFrames: json['total_frames'] ?? 0,
      framesAnalyzed: json['frames_analyzed'] ?? 0,
      processingTimeSeconds: (json['processing_time_seconds'] ?? 0).toDouble(),
      modelDevice: json['model_device'] ?? 'unknown',
    );
  }
}

/// Exception for video analysis errors
class VideoAnalysisException implements Exception {
  final String message;
  VideoAnalysisException(this.message);

  @override
  String toString() => 'VideoAnalysisException: $message';
}
