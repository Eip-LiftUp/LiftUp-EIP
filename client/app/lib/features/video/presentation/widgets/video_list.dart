/// Video List Widget
/// 
/// A widget that displays a list of videos with
/// empty state handling and loading indicators.

import 'package:flutter/material.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';
import '../../domain/entities/video_entity.dart';
import 'video_card.dart';

class VideoList extends StatelessWidget {
  /// List of videos to display
  final List<VideoEntity> videos;

  /// Whether the list is loading
  final bool isLoading;

  /// Callback when a video is tapped
  final void Function(VideoEntity video)? onVideoTap;

  /// Callback when a video delete is pressed
  final void Function(VideoEntity video)? onVideoDelete;

  /// Callback when video upload is pressed
  final void Function(VideoEntity video)? onVideoUpload;

  /// Callback when add video button is pressed
  final VoidCallback? onAddVideo;

  const VideoList({
    super.key,
    required this.videos,
    this.isLoading = false,
    this.onVideoTap,
    this.onVideoDelete,
    this.onVideoUpload,
    this.onAddVideo,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (videos.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildVideoList();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: AppConstants.spacingL),
            Text(
              'Chargement des vidéos...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.video_library_outlined,
                color: AppColors.primary,
                size: 64,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              'Aucune vidéo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Ajoutez votre première vidéo pour commencer\nl\'analyse de vos mouvements.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXl),
            ElevatedButton.icon(
              onPressed: onAddVideo,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une vidéo'),
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
      ),
    );
  }

  Widget _buildVideoList() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      itemCount: videos.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppConstants.spacingM),
      itemBuilder: (context, index) {
        final video = videos[index];
        return VideoCard(
          video: video,
          onTap: () => onVideoTap?.call(video),
          onDelete: () => onVideoDelete?.call(video),
          onUpload: () => onVideoUpload?.call(video),
        );
      },
    );
  }
}
