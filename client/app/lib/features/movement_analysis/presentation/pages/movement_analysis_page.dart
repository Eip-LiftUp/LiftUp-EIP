import 'package:flutter/material.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';
import 'package:app/features/video/video.dart';

/// Movement Analysis Page
/// 
/// This page serves as the main entry point for video-based
/// movement analysis. Users can record or import videos
/// for AI-powered technique analysis.
class MovementAnalysisPage extends StatefulWidget {
  const MovementAnalysisPage({super.key});

  @override
  State<MovementAnalysisPage> createState() => _MovementAnalysisPageState();
}

class _MovementAnalysisPageState extends State<MovementAnalysisPage> {
  /// List of videos (mock data for frontend demo)
  final List<VideoEntity> _videos = [];

  /// Whether the page is loading
  bool _isLoading = false;

  /// Navigate to video selection page
  void _addVideo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoSelectionPage(
          onVideoSelected: (path) {
            // Video was selected and uploaded
            // In a real app, this would be handled by a state manager
            setState(() {
              _videos.add(
                VideoEntity(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  localPath: path,
                  title: 'Nouvelle vidéo',
                  durationInSeconds: 30,
                  sizeInBytes: 10 * 1024 * 1024,
                  uploadStatus: VideoUploadStatus.uploaded,
                  createdAt: DateTime.now(),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  /// Handle video tap
  void _onVideoTap(VideoEntity video) {
    // Navigate to video detail/analysis page
    // This would be implemented when backend integration is done
  }

  /// Handle video delete
  void _onVideoDelete(VideoEntity video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Supprimer la vidéo ?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${video.title}" ?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _videos.removeWhere((v) => v.id == video.id);
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Content
          Expanded(
            child: _videos.isEmpty
                ? _buildEmptyState()
                : _buildVideoListSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Analyse Mouvement',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (_videos.isNotEmpty)
            IconButton(
              onPressed: _addVideo,
              icon: const Icon(
                Icons.add_circle,
                color: AppColors.primary,
              ),
              iconSize: 32,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
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
                Icons.videocam_rounded,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              'Analyse de Mouvement',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Analysez vos mouvements avec l\'IA pour améliorer votre technique.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXl),
            ElevatedButton.icon(
              onPressed: _addVideo,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une vidéo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingXl,
                  vertical: AppConstants.spacingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoListSection() {
    return VideoList(
      videos: _videos,
      isLoading: _isLoading,
      onVideoTap: _onVideoTap,
      onVideoDelete: _onVideoDelete,
      onAddVideo: _addVideo,
    );
  }
}
