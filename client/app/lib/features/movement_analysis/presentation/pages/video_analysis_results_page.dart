import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/models/review_record.dart';
import 'package:app/core/services/video_analysis_service.dart';
import 'package:app/core/utils/date_utils.dart';
import 'package:app/core/widgets/ui/ui.dart';

/// Results of a video review: score and verdict, annotated video, form
/// scores, feedback and analysis details.
class VideoAnalysisResultsPage extends StatefulWidget {
  final VideoAnalysisResult result;
  final String? videoPath;

  const VideoAnalysisResultsPage({super.key, required this.result, this.videoPath});

  @override
  State<VideoAnalysisResultsPage> createState() => _VideoAnalysisResultsPageState();
}

class _VideoAnalysisResultsPageState extends State<VideoAnalysisResultsPage> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final path = widget.result.annotatedVideoUrl;
    if (path == null) return;
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse('${VideoAnalysisService.aiServiceUrl}$path'),
      );
      _videoController = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      if (mounted) setState(() => _isVideoInitialized = true);
    } catch (_) {
      // The annotated video is optional: the page works without it.
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).popUntil((route) => route.isFirst);

  void _openPlanning() {
    final router = GoRouter.of(context);
    _close();
    router.push('/planning?date=${AppDateUtils.formatDateKey(DateTime.now())}');
  }

  static String _decimal(double value) => value.toStringAsFixed(1).replaceAll('.', ',');

  static Color _scoreColor(double score) => ReviewVerdict.fromScore(score.round()).color;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return Scaffold(
      appBar: AppTopBar(title: 'Résultats de l\'analyse', showBack: true, onBack: _close),
      body: PageListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          _buildScoreCard(result),
          const SizedBox(height: 16),
          if (_isVideoInitialized) ...[_buildAnnotatedVideo(), const SizedBox(height: 16)],
          _buildExerciseInfo(result),
          const SizedBox(height: 16),
          _buildFormScores(result.formScores),
          if (result.feedback.isNotEmpty) ...[const SizedBox(height: 16), _buildFeedback(result.feedback)],
          const SizedBox(height: 16),
          _buildMetrics(result.metrics),
          const SizedBox(height: 24),
          AppButton(
            label: 'Voir dans le planning',
            icon: LucideIcons.calendarDays,
            variant: AppButtonVariant.secondary,
            fullWidth: true,
            onPressed: _openPlanning,
          ),
          const SizedBox(height: 12),
          AppButton(label: 'Terminer', fullWidth: true, onPressed: _close),
        ],
      ),
    );
  }

  Widget _buildScoreCard(VideoAnalysisResult result) {
    final verdict = ReviewVerdict.fromScore(result.qualityScore.round());
    return AppCard(
      accentColor: verdict.color,
      child: Column(
        children: [
          const Text('Score global', style: AppText.caption),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _decimal(result.qualityScore),
                style: TextStyle(
                  color: verdict.color,
                  fontSize: 56,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text('/100', style: AppText.h2.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              VerdictBadge(verdict),
              Pill(text: 'Note : ${result.grade}', color: AppColors.primary, dense: true),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Ce verdict est ajouté à ton planning.', style: AppText.caption),
        ],
      ),
    );
  }

  Widget _buildAnnotatedVideo() {
    final controller = _videoController!;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                IconTile(icon: LucideIcons.video, color: AppColors.accent, size: 36, iconSize: 18),
                SizedBox(width: 12),
                Expanded(child: Text('Analyse du mouvement', style: AppText.bodyMedium)),
                Pill(text: 'Pose suivie', icon: LucideIcons.check, color: AppColors.success, dense: true),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: GestureDetector(
              onTap: () => setState(() {
                _isVideoPlaying ? controller.pause() : controller.play();
                _isVideoPlaying = !_isVideoPlaying;
              }),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(controller),
                  AnimatedOpacity(
                    opacity: _isVideoPlaying ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.play, color: AppColors.textPrimary, size: 40),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _legend(AppColors.success, 'Bonne forme'),
                _legend(AppColors.warning, 'À travailler'),
                _legend(AppColors.error, 'À corriger'),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 12,
                      child: CustomPaint(painter: DashedLinePainter(color: AppColors.primary)),
                    ),
                    const SizedBox(width: 6),
                    Text('Forme idéale (décalée)', style: AppText.caption.copyWith(color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppText.caption),
      ],
    );
  }

  Widget _buildExerciseInfo(VideoAnalysisResult result) {
    return AppCard(
      child: Row(
        children: [
          const IconTile(icon: LucideIcons.dumbbell, size: 48, iconSize: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(analysisExerciseLabel(result.detectedExercise), style: AppText.h3),
                Text(
                  'Exercice détecté • confiance ${_decimal(result.detectionConfidence)} %',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormScores(FormScores scores) {
    final rows = [
      ('Profondeur', scores.depth, LucideIcons.moveVertical),
      ('Alignement', scores.alignment, LucideIcons.ruler),
      ('Stabilité', scores.stability, LucideIcons.scale),
      ('Tempo', scores.tempo, LucideIcons.timer),
      ('Amplitude', scores.rangeOfMotion, LucideIcons.move),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Analyse de la forme'),
          for (final (label, score, icon) in rows) ...[
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: AppText.body.copyWith(fontSize: 14))),
                Text(
                  _decimal(score),
                  style: AppText.bodyMedium.copyWith(fontSize: 14, color: _scoreColor(score)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: AppColors.surface2,
                valueColor: AlwaysStoppedAnimation(_scoreColor(score)),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedback(List<FeedbackComment> feedback) {
    final sorted = [...feedback]..sort((a, b) => b.severity.compareTo(a.severity));
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Conseils'),
          for (final item in sorted) ...[
            _FeedbackItem(item),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildMetrics(AnalysisMetrics metrics) {
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppText.caption.copyWith(fontSize: 14))),
              Text(value, style: AppText.bodyMedium.copyWith(fontSize: 14)),
            ],
          ),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Détails de l\'analyse'),
          row('Temps de traitement', '${metrics.processingTimeSeconds.toStringAsFixed(2).replaceAll('.', ',')} s'),
          row('Images analysées', '${metrics.framesAnalyzed}'),
          row('Images par seconde', _decimal(metrics.videoFps)),
          row('Appareil de calcul', metrics.modelDevice),
        ],
      ),
    );
  }
}

class _FeedbackItem extends StatelessWidget {
  final FeedbackComment feedback;

  const _FeedbackItem(this.feedback);

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (feedback.type) {
      'positive' => (AppColors.success, LucideIcons.circleCheck),
      'encouragement' => (AppColors.primary, LucideIcons.trophy),
      'correction' => (AppColors.warning, LucideIcons.lightbulb),
      'warning' => (AppColors.error, LucideIcons.triangleAlert),
      _ => (AppColors.textSecondary, LucideIcons.info),
    };
    final category = feedback.category
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
                Text(category, style: AppText.caption.copyWith(color: color)),
                const SizedBox(height: 4),
                Text(feedback.text, style: AppText.body.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
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

/// Custom painter for dashed line in legend
class DashedLinePainter extends CustomPainter {
  final Color color;

  const DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;
    final y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
