import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/widgets/ui/ui.dart';
import 'video_preview_page.dart';
import 'video_recording_page.dart';

/// First step of the video review: record a video or pick one.
class VideoSelectionPage extends StatelessWidget {
  /// Called with the video path once the user confirms it in the preview.
  final void Function(String videoPath)? onVideoSelected;

  const VideoSelectionPage({super.key, this.onVideoSelected});

  Future<void> _pickVideoFromGallery(BuildContext context) async {
    try {
      final pickedFile = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      if (pickedFile != null && context.mounted) _handleVideoSelected(context, pickedFile.path);
    } catch (e) {
      if (context.mounted) _showError(context, 'Erreur lors de la sélection : $e');
    }
  }

  Future<void> _pickVideoFromFiles(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video, allowMultiple: false);
      final path = result?.files.firstOrNull?.path;
      if (path != null && context.mounted) _handleVideoSelected(context, path);
    } catch (e) {
      if (context.mounted) _showError(context, 'Erreur lors de la sélection : $e');
    }
  }

  Future<void> _recordNewVideo(BuildContext context) async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const VideoRecordingPage()),
    );
    if (path != null && context.mounted) _handleVideoSelected(context, path);
  }

  void _handleVideoSelected(BuildContext context, String videoPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPreviewPage(videoPath: videoPath, onConfirm: onVideoSelected),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Analyser une vidéo', showBack: true),
      body: PageListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const Text('Filme ton mouvement', style: AppText.metric),
          const SizedBox(height: 8),
          Text(
            'Ton coach IA analyse ta technique et te donne un verdict : Parfait, Améliorable ou À corriger. '
            'Il apparaîtra dans ton planning.',
            style: AppText.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _OptionCard(
            icon: LucideIcons.video,
            color: AppColors.primary,
            title: 'Enregistrer une vidéo',
            description: 'Utilise la caméra pour filmer ton mouvement.',
            onTap: () => _recordNewVideo(context),
          ),
          const SizedBox(height: 12),
          _OptionCard(
            icon: LucideIcons.images,
            color: AppColors.success,
            title: 'Importer depuis la galerie',
            description: 'Sélectionne une vidéo existante.',
            onTap: () => _pickVideoFromGallery(context),
          ),
          const SizedBox(height: 12),
          _OptionCard(
            icon: LucideIcons.folderOpen,
            color: AppColors.accent,
            title: 'Importer depuis les fichiers',
            description: 'Parcours tes dossiers pour choisir un fichier vidéo.',
            onTap: () => _pickVideoFromFiles(context),
          ),
          const SizedBox(height: 24),
          const AppCard(
            elevated: true,
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 20, color: AppColors.textSecondary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Formats supportés : MP4, MOV, AVI, MKV (10 min max)',
                    style: AppText.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          IconTile(icon: icon, color: color, size: 48, iconSize: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodyMedium),
                const SizedBox(height: 2),
                Text(description, style: AppText.caption),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
