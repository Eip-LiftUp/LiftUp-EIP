import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/services/video_analysis_service.dart';

/// Video Analysis Results Page
///
/// Displays the I3D analysis results with:
/// - Overall quality score
/// - Form aspect scores (radar chart)
/// - Detailed feedback comments
/// - Metrics information
class VideoAnalysisResultsPage extends StatelessWidget {
  final VideoAnalysisResult result;
  final String? videoPath;

  const VideoAnalysisResultsPage({
    super.key,
    required this.result,
    this.videoPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Analysis Results',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScoreCard(),
            const SizedBox(height: 16),
            _buildExerciseInfo(),
            const SizedBox(height: 16),
            _buildFormScores(),
            const SizedBox(height: 16),
            _buildFeedbackSection(),
            const SizedBox(height: 16),
            _buildMetricsCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getScoreGradient(result.qualityScore),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getScoreColor(result.qualityScore).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Score',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                result.qualityScore.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '/100',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Grade: ${result.grade}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatExerciseName(result.detectedExercise),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confidence: ${result.detectionConfidence.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormScores() {
    final scores = [
      ('Depth', result.formScores.depth, Icons.height),
      ('Alignment', result.formScores.alignment, Icons.straighten),
      ('Stability', result.formScores.stability, Icons.balance),
      ('Tempo', result.formScores.tempo, Icons.timer),
      ('Range of Motion', result.formScores.rangeOfMotion, Icons.open_with),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Form Analysis',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...scores.map((score) => _buildScoreBar(
                score.$1,
                score.$2,
                score.$3,
              )),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, double score, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white54, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                score.toStringAsFixed(1),
                style: TextStyle(
                  color: _getScoreColor(score),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(_getScoreColor(score)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    // Sort feedback by severity (most important first)
    final sortedFeedback = List<FeedbackComment>.from(result.feedback)
      ..sort((a, b) => b.severity.compareTo(a.severity));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.feedback, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Feedback & Tips',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedFeedback.map((fb) => _buildFeedbackItem(fb)),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(FeedbackComment feedback) {
    final color = _getFeedbackColor(feedback.type);
    final icon = _getFeedbackIcon(feedback.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCategoryName(feedback.category),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feedback.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analysis Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildMetricRow('Processing Time', '${result.metrics.processingTimeSeconds.toStringAsFixed(2)}s'),
          _buildMetricRow('Frames Analyzed', '${result.metrics.framesAnalyzed}'),
          _buildMetricRow('Video FPS', '${result.metrics.videoFps.toStringAsFixed(1)}'),
          _buildMetricRow('Device', result.metrics.modelDevice),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  List<Color> _getScoreGradient(double score) {
    if (score >= 80) {
      return [Colors.green.shade700, Colors.green.shade400];
    }
    if (score >= 60) {
      return [Colors.orange.shade700, Colors.orange.shade400];
    }
    return [Colors.red.shade700, Colors.red.shade400];
  }

  Color _getFeedbackColor(String type) {
    switch (type) {
      case 'positive':
        return Colors.green;
      case 'encouragement':
        return Colors.blue;
      case 'correction':
        return Colors.orange;
      case 'warning':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getFeedbackIcon(String type) {
    switch (type) {
      case 'positive':
        return Icons.check_circle;
      case 'encouragement':
        return Icons.emoji_events;
      case 'correction':
        return Icons.tips_and_updates;
      case 'warning':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  String _formatExerciseName(String name) {
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatCategoryName(String name) {
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}


/// Video Analysis Page - Unified upload and analysis flow
class VideoAnalysisPage extends StatefulWidget {
  final String videoPath;
  final String? exerciseType;

  const VideoAnalysisPage({
    super.key,
    required this.videoPath,
    this.exerciseType,
  });

  @override
  State<VideoAnalysisPage> createState() => _VideoAnalysisPageState();
}

class _VideoAnalysisPageState extends State<VideoAnalysisPage> {
  final _analysisService = VideoAnalysisService();
  
  bool _isAnalyzing = false;
  double _progress = 0.0;
  String _statusMessage = 'Preparing video...';
  String? _errorMessage;
  VideoAnalysisResult? _result;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _progress = 0.0;
      _statusMessage = 'Uploading video...';
      _errorMessage = null;
    });

    try {
      final result = await _analysisService.analyzeVideo(
        videoPath: widget.videoPath,
        exerciseType: widget.exerciseType,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
            if (progress < 1.0) {
              _statusMessage = 'Uploading: ${(progress * 100).toInt()}%';
            } else {
              _statusMessage = 'Analyzing movement with AI...';
            }
          });
        },
      );

      setState(() {
        _result = result;
        _isAnalyzing = false;
      });

      // Navigate to results
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => VideoAnalysisResultsPage(
              result: result,
              videoPath: widget.videoPath,
            ),
          ),
        );
      }
    } on VideoAnalysisException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Analysis failed: $e';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Analyzing Video',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isAnalyzing) ...[
                const SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation(Colors.blue),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(Colors.blue),
                ),
              ],
              if (_errorMessage != null) ...[
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Analysis Failed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _startAnalysis,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
