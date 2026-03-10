import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';
import 'video_preview_page.dart';
import 'video_recording_page.dart';

/// Video Selection Page
/// 
/// This page allows users to select a video from their device
/// or record a new video using the camera.
class VideoSelectionPage extends StatelessWidget {
  /// Callback when a video is selected
  final void Function(String videoPath)? onVideoSelected;

  const VideoSelectionPage({
    super.key,
    this.onVideoSelected,
  });

  /// Pick video from gallery
  Future<void> _pickVideoFromGallery(BuildContext context) async {
    final picker = ImagePicker();

    try {
      final pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );

      if (pickedFile != null) {
        _handleVideoSelected(context, pickedFile.path);
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Erreur lors de la sélection: $e');
    }
  }

  /// Pick video using file picker (for more formats)
  Future<void> _pickVideoFromFiles(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          _handleVideoSelected(context, path);
        }
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Erreur lors de la sélection: $e');
    }
  }

  /// Open camera to record a new video
  Future<void> _recordNewVideo(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => VideoRecordingPage(
          onVideoRecorded: (path) {
            // Video recorded, will be returned from page
          },
        ),
      ),
    );

    if (result != null) {
      _handleVideoSelected(context, result);
    }
  }

  /// Handle video selection
  void _handleVideoSelected(BuildContext context, String videoPath) {
    // Navigate to video preview page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPreviewPage(
          videoPath: videoPath,
          onConfirm: (path) {
            onVideoSelected?.call(path);
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Ajouter une vidéo',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Comment souhaitez-vous ajouter votre vidéo ?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingL),
              Text(
                'Choisissez une option pour ajouter une vidéo de votre mouvement à analyser.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingXl),

              // Options
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Record new video option
                    _VideoOptionCard(
                      icon: Icons.videocam_rounded,
                      title: 'Enregistrer une vidéo',
                      description:
                          'Utilisez la caméra pour filmer votre mouvement en temps réel.',
                      color: AppColors.primary,
                      onTap: () => _recordNewVideo(context),
                    ),
                    const SizedBox(height: AppConstants.spacingL),

                    // Import from gallery option
                    _VideoOptionCard(
                      icon: Icons.photo_library_rounded,
                      title: 'Importer depuis la galerie',
                      description:
                          'Sélectionnez une vidéo existante depuis votre galerie photo.',
                      color: AppColors.secondary,
                      onTap: () => _pickVideoFromGallery(context),
                    ),
                    const SizedBox(height: AppConstants.spacingL),

                    // Import from files option
                    _VideoOptionCard(
                      icon: Icons.folder_rounded,
                      title: 'Importer depuis les fichiers',
                      description:
                          'Parcourez vos dossiers pour sélectionner un fichier vidéo.',
                      color: AppColors.accent,
                      onTap: () => _pickVideoFromFiles(context),
                    ),
                  ],
                ),
              ),

              // Supported formats info
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                  border: Border.all(color: AppColors.navBarBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: AppConstants.spacingS),
                    Expanded(
                      child: Text(
                        'Formats supportés: MP4, MOV, AVI, MKV (max 10 min)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Video option card widget
class _VideoOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _VideoOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
