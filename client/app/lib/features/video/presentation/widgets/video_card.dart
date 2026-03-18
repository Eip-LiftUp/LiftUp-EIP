/// Video Card Widget
/// 
/// A card widget that displays video information with
/// thumbnail preview, title, duration, and upload status.

import 'package:flutter/material.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';
import '../../domain/entities/video_entity.dart';

class VideoCard extends StatelessWidget {
  /// The video entity to display
  final VideoEntity video;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Callback when the delete button is pressed
  final VoidCallback? onDelete;

  /// Callback when the upload button is pressed
  final VoidCallback? onUpload;

  const VideoCard({
    super.key,
    required this.video,
    this.onTap,
    this.onDelete,
    this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Vidéo ${video.title}, durée ${video.formattedDuration}, statut ${_statusSemanticText(video.uploadStatus)}',
      hint: 'Appuyer pour ouvrir les détails de la vidéo',
      child: Card(
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
          side: const BorderSide(color: AppColors.navBarBorder),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Row(
              children: [
                // Thumbnail
                _buildThumbnail(),
                const SizedBox(width: AppConstants.spacingM),

                // Info
                Expanded(
                  child: _buildVideoInfo(context),
                ),

                // Actions
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusSemanticText(VideoUploadStatus status) {
    switch (status) {
      case VideoUploadStatus.pending:
        return 'en attente';
      case VideoUploadStatus.uploading:
        return 'en cours de téléversement';
      case VideoUploadStatus.uploaded:
        return 'téléversée';
      case VideoUploadStatus.failed:
        return 'échec de téléversement';
      case VideoUploadStatus.cancelled:
        return 'téléversement annulé';
    }
  }

  Widget _buildThumbnail() {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Thumbnail image or placeholder
          if (video.thumbnailPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
              child: Image.asset(
                video.thumbnailPath!,
                semanticLabel: 'Aperçu de la vidéo ${video.title}',
                width: 80,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildThumbnailPlaceholder();
                },
              ),
            )
          else
            _buildThumbnailPlaceholder(),

          // Duration badge
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingXs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                video.formattedDuration,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
      ),
      child: const Icon(
        Icons.videocam,
        color: AppColors.primary,
        size: 32,
      ),
    );
  }

  Widget _buildVideoInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          video.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppConstants.spacingXs),

        // File size
        Text(
          video.formattedSize,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppConstants.spacingS),

        // Status badge
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String statusText;
    IconData statusIcon;

    switch (video.uploadStatus) {
      case VideoUploadStatus.pending:
        badgeColor = AppColors.textSecondary;
        statusText = 'En attente';
        statusIcon = Icons.schedule;
        break;
      case VideoUploadStatus.uploading:
        badgeColor = AppColors.primary;
        statusText = '${(video.uploadProgress * 100).toInt()}%';
        statusIcon = Icons.cloud_upload;
        break;
      case VideoUploadStatus.uploaded:
        badgeColor = AppColors.secondary;
        statusText = 'Téléversé';
        statusIcon = Icons.check_circle;
        break;
      case VideoUploadStatus.failed:
        badgeColor = Colors.red;
        statusText = 'Échec';
        statusIcon = Icons.error;
        break;
      case VideoUploadStatus.cancelled:
        badgeColor = AppColors.accent;
        statusText = 'Annulé';
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: badgeColor, size: 12),
          const SizedBox(width: AppConstants.spacingXs),
          Text(
            statusText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (video.uploadStatus == VideoUploadStatus.pending ||
            video.uploadStatus == VideoUploadStatus.failed ||
            video.uploadStatus == VideoUploadStatus.cancelled)
          IconButton(
            onPressed: onUpload,
            tooltip: 'Téléverser ${video.title}',
            icon: const Icon(
              Icons.cloud_upload,
              color: AppColors.primary,
            ),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        IconButton(
          onPressed: onDelete,
          tooltip: 'Supprimer ${video.title}',
          icon: const Icon(
            Icons.delete_outline,
            color: AppColors.textSecondary,
          ),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ],
    );
  }
}
