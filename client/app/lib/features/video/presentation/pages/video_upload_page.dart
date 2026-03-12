import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';
import 'package:app/core/services/video_analysis_service.dart';
import 'package:app/features/movement_analysis/presentation/pages/video_analysis_results_page.dart';
import '../../domain/entities/video_entity.dart';

/// Video Upload Page
/// 
/// This page handles the video upload process with:
/// - Video metadata input (title, description)
/// - Upload progress indication
/// - Upload status and error handling
class VideoUploadPage extends StatefulWidget {
  /// Path to the video file to upload
  final String videoPath;

  /// Callback when upload is complete
  final void Function(String? url)? onUploadComplete;

  const VideoUploadPage({
    super.key,
    required this.videoPath,
    this.onUploadComplete,
  });

  @override
  State<VideoUploadPage> createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends State<VideoUploadPage> {
  /// Text controllers for form fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  /// Form key for validation
  final _formKey = GlobalKey<FormState>();

  /// Current upload state
  _UploadState _uploadState = _UploadState.idle;

  /// Upload progress (0.0 - 1.0)
  double _uploadProgress = 0.0;

  /// Error message
  String? _errorMessage;

  /// Video file info
  int _fileSizeBytes = 0;
  String _fileName = '';

  /// Analysis result
  VideoAnalysisResult? _analysisResult;

  /// Video analysis service
  final _analysisService = VideoAnalysisService();

  /// Timer for simulating upload progress (frontend only)
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _loadVideoInfo();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  /// Load video file information
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
    } catch (e) {
      // Ignore errors loading file info
    }
  }

  /// Format file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Start the upload process
  Future<void> _startUpload() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _uploadState = _UploadState.uploading;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      // Actually upload and analyze the video using the AI service
      final result = await _analysisService.analyzeVideo(
        videoPath: widget.videoPath,
        exerciseType: _titleController.text.isNotEmpty ? _titleController.text : null,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      setState(() {
        _uploadState = _UploadState.success;
        _analysisResult = result;
      });

      widget.onUploadComplete?.call(result.analysisId);

      // Navigate to results page
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
        _uploadState = _UploadState.failed;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _uploadState = _UploadState.failed;
        _errorMessage = 'Analysis failed: $e';
      });
    }
  }

  /// Cancel the upload
  void _cancelUpload() {
    _progressTimer?.cancel();
    setState(() {
      _uploadState = _UploadState.cancelled;
      _uploadProgress = 0.0;
    });
  }

  /// Retry the upload
  void _retryUpload() {
    setState(() {
      _uploadState = _UploadState.idle;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Téléverser la vidéo',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (_uploadState == _UploadState.uploading) {
              _showCancelDialog();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_uploadState) {
      case _UploadState.idle:
        return _buildUploadForm();
      case _UploadState.uploading:
        return _buildUploadProgress();
      case _UploadState.success:
        return _buildSuccessState();
      case _UploadState.failed:
        return _buildFailedState();
      case _UploadState.cancelled:
        return _buildCancelledState();
    }
  }

  Widget _buildUploadForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // File info card
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
              border: Border.all(color: AppColors.navBarBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                  ),
                  child: const Icon(
                    Icons.video_file,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fileName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        _formatFileSize(_fileSizeBytes),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.check_circle,
                    color: AppColors.secondary,
                  ),
                  onPressed: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingXl),

          // Title field
          Text(
            'Titre de la vidéo',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          TextFormField(
            controller: _titleController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Entrez le titre de votre vidéo',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                borderSide: const BorderSide(color: AppColors.navBarBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                borderSide: const BorderSide(color: AppColors.navBarBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le titre est obligatoire';
              }
              if (value.length > 100) {
                return 'Le titre ne doit pas dépasser 100 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Description field
          Text(
            'Description (optionnel)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          TextFormField(
            controller: _descriptionController,
            style: const TextStyle(color: AppColors.textPrimary),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Décrivez le mouvement que vous souhaitez analyser...',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                borderSide: const BorderSide(color: AppColors.navBarBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                borderSide: const BorderSide(color: AppColors.navBarBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingXl),

          // Exercise type selector
          Text(
            'Type de mouvement',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          _ExerciseTypeSelector(),
          const SizedBox(height: AppConstants.spacingXl * 2),

          // Upload button
          ElevatedButton.icon(
            onPressed: _startUpload,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Téléverser la vidéo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.spacingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress() {
    final percentage = (_uploadProgress * 100).toInt();
    final uploadedBytes = (_fileSizeBytes * _uploadProgress).toInt();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppConstants.spacingXl * 2),

        // Upload animation
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                value: _uploadProgress,
                strokeWidth: 8,
                backgroundColor: AppColors.navBarBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            Column(
              children: [
                const Icon(
                  Icons.cloud_upload,
                  color: AppColors.primary,
                  size: 48,
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingXl),

        Text(
          'Téléversement en cours...',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppConstants.spacingM),

        Text(
          '${_formatFileSize(uploadedBytes)} / ${_formatFileSize(_fileSizeBytes)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppConstants.spacingXl * 2),

        // Cancel button
        OutlinedButton.icon(
          onPressed: _cancelUpload,
          icon: const Icon(Icons.cancel),
          label: const Text('Annuler'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingXl,
              vertical: AppConstants.spacingM,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppConstants.spacingXl * 2),

        // Success animation
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingXl),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: AppColors.secondary,
            size: 80,
          ),
        ),
        const SizedBox(height: AppConstants.spacingXl),

        Text(
          'Téléversement réussi !',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.spacingM),

        Text(
          'Votre vidéo a été téléversée avec succès.\nL\'analyse commencera bientôt.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingXl * 2),

        // Done button
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          icon: const Icon(Icons.home),
          label: const Text('Retour à l\'accueil'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingXl,
              vertical: AppConstants.spacingM,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFailedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppConstants.spacingXl * 2),

        Container(
          padding: const EdgeInsets.all(AppConstants.spacingXl),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error,
            color: Colors.red,
            size: 80,
          ),
        ),
        const SizedBox(height: AppConstants.spacingXl),

        Text(
          'Échec du téléversement',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.spacingM),

        Text(
          _errorMessage ?? 'Une erreur est survenue lors du téléversement.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingXl * 2),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.textSecondary),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                  vertical: AppConstants.spacingM,
                ),
              ),
              child: const Text('Annuler'),
            ),
            const SizedBox(width: AppConstants.spacingM),
            ElevatedButton.icon(
              onPressed: _retryUpload,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                  vertical: AppConstants.spacingM,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCancelledState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: AppConstants.spacingXl * 2),

        Container(
          padding: const EdgeInsets.all(AppConstants.spacingXl),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cancel,
            color: AppColors.accent,
            size: 80,
          ),
        ),
        const SizedBox(height: AppConstants.spacingXl),

        Text(
          'Téléversement annulé',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppConstants.spacingM),

        Text(
          'Le téléversement a été annulé.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.spacingXl * 2),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.textSecondary),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                  vertical: AppConstants.spacingM,
                ),
              ),
              child: const Text('Retour'),
            ),
            const SizedBox(width: AppConstants.spacingM),
            ElevatedButton.icon(
              onPressed: _retryUpload,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                  vertical: AppConstants.spacingM,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Annuler le téléversement ?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler le téléversement en cours ?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelUpload();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }
}

/// Upload state enum
enum _UploadState {
  idle,
  uploading,
  success,
  failed,
  cancelled,
}

/// Exercise type selector widget
class _ExerciseTypeSelector extends StatefulWidget {
  @override
  State<_ExerciseTypeSelector> createState() => _ExerciseTypeSelectorState();
}

class _ExerciseTypeSelectorState extends State<_ExerciseTypeSelector> {
  String _selectedType = 'squat';

  final _exerciseTypes = [
    {'id': 'squat', 'name': 'Squat', 'icon': Icons.accessibility_new},
    {'id': 'deadlift', 'name': 'Deadlift', 'icon': Icons.fitness_center},
    {'id': 'bench_press', 'name': 'Bench Press', 'icon': Icons.airline_seat_flat},
    {'id': 'overhead_press', 'name': 'Overhead Press', 'icon': Icons.upload},
    {'id': 'pull_up', 'name': 'Pull Up', 'icon': Icons.expand_less},
    {'id': 'other', 'name': 'Autre', 'icon': Icons.more_horiz},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppConstants.spacingS,
      runSpacing: AppConstants.spacingS,
      children: _exerciseTypes.map((type) {
        final isSelected = _selectedType == type['id'];
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type['icon'] as IconData,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: AppConstants.spacingXs),
              Text(type['name'] as String),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedType = type['id'] as String;
              });
            }
          },
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.cardBackground,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.navBarBorder,
            ),
          ),
        );
      }).toList(),
    );
  }
}
