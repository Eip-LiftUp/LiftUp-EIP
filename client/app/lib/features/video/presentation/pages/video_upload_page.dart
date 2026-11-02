import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/models/review_record.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/review_history_provider.dart';
import 'package:app/core/services/video_analysis_service.dart';
import 'package:app/core/widgets/ui/ui.dart';
import 'package:app/features/movement_analysis/presentation/pages/video_analysis_results_page.dart';

enum _UploadState { idle, uploading, failed, cancelled }

/// Sends the video to the analysis service, records the verdict for the
/// planning, then shows the results.
class VideoUploadPage extends ConsumerStatefulWidget {
  final String videoPath;

  /// Called with the analysis id once the analysis succeeded.
  final void Function(String? analysisId)? onUploadComplete;

  const VideoUploadPage({super.key, required this.videoPath, this.onUploadComplete});

  @override
  ConsumerState<VideoUploadPage> createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends ConsumerState<VideoUploadPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _analysisService = VideoAnalysisService();

  String _selectedExercise = 'squat';
  _UploadState _state = _UploadState.idle;
  double _progress = 0;
  String? _errorMessage;
  int _fileSizeBytes = 0;
  String _fileName = '';

  /// Bumped on cancel so a late response from an abandoned upload is ignored.
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _loadVideoInfo();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadVideoInfo() async {
    try {
      final file = File(widget.videoPath);
      if (await file.exists()) {
        final stat = await file.stat();
        setState(() {
          _fileSizeBytes = stat.size;
          _fileName = widget.videoPath.split(Platform.pathSeparator).last;
          _titleController.text = _fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
        });
      }
    } catch (_) {
      // The file info is only informative.
    }
  }

  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} Go';
  }

  Future<void> _startUpload() async {
    if (!_formKey.currentState!.validate()) return;
    final attempt = ++_attempt;
    setState(() {
      _state = _UploadState.uploading;
      _progress = 0;
      _errorMessage = null;
    });

    try {
      final result = await _analysisService.analyzeVideo(
        videoPath: widget.videoPath,
        exerciseType: _selectedExercise,
        onProgress: (progress) {
          if (mounted && attempt == _attempt) setState(() => _progress = progress);
        },
      );
      if (!mounted || attempt != _attempt) return;

      final userId = ref.read(authProvider).userId;
      if (userId != null) {
        await ref.read(reviewHistoryProvider(userId).notifier).add(
              ReviewRecord(
                day: DateTime.now(),
                exercise: _selectedExercise == 'other' ? result.detectedExercise : _selectedExercise,
                score: result.qualityScore.round().clamp(0, 100),
              ),
            );
      }
      widget.onUploadComplete?.call(result.analysisId);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VideoAnalysisResultsPage(result: result, videoPath: widget.videoPath),
        ),
      );
    } on VideoAnalysisException catch (e) {
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _state = _UploadState.failed;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _state = _UploadState.failed;
        _errorMessage = 'L\'analyse a échoué : $e';
      });
    }
  }

  void _cancelUpload() {
    _attempt++;
    setState(() {
      _state = _UploadState.cancelled;
      _progress = 0;
    });
  }

  void _retry() {
    setState(() {
      _state = _UploadState.idle;
      _progress = 0;
      _errorMessage = null;
    });
  }

  Future<void> _confirmCancel() async {
    final cancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler l\'analyse ?'),
        content: const Text('La vidéo en cours d\'envoi ne sera pas analysée.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Continuer')),
          AppButton(
            label: 'Annuler l\'analyse',
            variant: AppButtonVariant.destructive,
            size: AppButtonSize.sm,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (cancel == true) _cancelUpload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Envoyer la vidéo',
        showBack: true,
        onBack: () => _state == _UploadState.uploading ? _confirmCancel() : Navigator.of(context).pop(),
      ),
      body: PageListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          switch (_state) {
            _UploadState.idle => _buildForm(),
            _UploadState.uploading => _buildProgress(),
            _UploadState.failed => _buildOutcome(
                icon: LucideIcons.circleAlert,
                color: AppColors.error,
                title: 'Échec de l\'analyse',
                message: _errorMessage ?? 'Une erreur est survenue pendant l\'envoi.',
              ),
            _UploadState.cancelled => _buildOutcome(
                icon: LucideIcons.circleX,
                color: AppColors.warning,
                title: 'Analyse annulée',
                message: 'La vidéo n\'a pas été analysée.',
              ),
          },
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Row(
              children: [
                const IconTile(icon: LucideIcons.fileVideo, size: 48, iconSize: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName.isEmpty ? 'Vidéo sélectionnée' : _fileName,
                        style: AppText.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_fileSizeBytes > 0) Text(_formatFileSize(_fileSizeBytes), style: AppText.caption),
                    ],
                  ),
                ),
                const Icon(LucideIcons.circleCheck, color: AppColors.success),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'Titre de la vidéo',
            hint: 'Entre le titre de ta vidéo',
            controller: _titleController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Le titre est obligatoire';
              if (value.length > 100) return 'Le titre ne doit pas dépasser 100 caractères';
              return null;
            },
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Description (facultatif)',
            hint: 'Décris le mouvement à analyser…',
            controller: _descriptionController,
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          const Text('Type de mouvement', style: AppText.bodyMedium),
          const SizedBox(height: 4),
          const Text('Sert de référence pour comparer ta forme à la forme idéale.', style: AppText.caption),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final MapEntry(key: code, value: label) in kAnalysisExercises.entries)
                AppChip(
                  label: label,
                  selected: _selectedExercise == code,
                  onTap: () => setState(() => _selectedExercise = code),
                ),
            ],
          ),
          const SizedBox(height: 32),
          AppButton(
            label: 'Lancer l\'analyse',
            icon: LucideIcons.cloudUpload,
            size: AppButtonSize.lg,
            fullWidth: true,
            onPressed: _startUpload,
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    final analysing = _progress >= 1;
    final percentage = (_progress * 100).toInt();
    return Column(
      children: [
        const SizedBox(height: 48),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: analysing ? null : _progress,
                strokeWidth: 8,
                backgroundColor: AppColors.surface2,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(analysing ? LucideIcons.sparkles : LucideIcons.cloudUpload, color: AppColors.primary, size: 40),
                const SizedBox(height: 8),
                if (!analysing) Text('$percentage %', style: AppText.metric),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(analysing ? 'Analyse du mouvement…' : 'Envoi en cours…', style: AppText.h2),
        const SizedBox(height: 8),
        Text(
          analysing
              ? 'Ton coach IA examine ta technique.'
              : '${_formatFileSize((_fileSizeBytes * _progress).toInt())} / ${_formatFileSize(_fileSizeBytes)}',
          style: AppText.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        AppButton(
          label: 'Annuler',
          icon: LucideIcons.x,
          variant: AppButtonVariant.secondary,
          onPressed: _confirmCancel,
        ),
      ],
    );
  }

  Widget _buildOutcome({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Column(
      children: [
        const SizedBox(height: 48),
        IconTile(icon: icon, color: color, size: 80, iconSize: 36),
        const SizedBox(height: 24),
        Text(title, style: AppText.metric, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(message, style: AppText.body.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Retour',
                variant: AppButtonVariant.secondary,
                fullWidth: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Réessayer',
                icon: LucideIcons.rotateCcw,
                fullWidth: true,
                onPressed: _retry,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
