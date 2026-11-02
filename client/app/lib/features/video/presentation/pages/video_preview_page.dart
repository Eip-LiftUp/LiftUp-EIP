import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/widgets/ui/ui.dart';
import 'video_upload_page.dart';

/// Plays back the selected or recorded video before sending it for review.
class VideoPreviewPage extends StatefulWidget {
  final String videoPath;

  /// Called with the video path once the analysis is done.
  final void Function(String videoPath)? onConfirm;

  const VideoPreviewPage({super.key, required this.videoPath, this.onConfirm});

  @override
  State<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      final file = File(widget.videoPath);
      if (!await file.exists()) {
        setState(() => _errorMessage = 'Le fichier vidéo n\'existe pas');
        return;
      }
      final controller = VideoPlayerController.file(file);
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      controller.addListener(() {
        if (mounted && _isPlaying != controller.value.isPlaying) {
          setState(() => _isPlaying = controller.value.isPlaying);
        }
      });
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Impossible de charger la vidéo : $e');
    }
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
  }

  void _seekBy(Duration offset) {
    final controller = _controller;
    if (controller == null) return;
    controller.seekTo(controller.value.position + offset);
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _proceedToUpload() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoUploadPage(
          videoPath: widget.videoPath,
          onUploadComplete: (_) => widget.onConfirm?.call(widget.videoPath),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Aperçu vidéo', showBack: true),
      body: Column(
        children: [
          Expanded(child: ColoredBox(color: Colors.black, child: _buildVideoPlayer())),
          if (_isInitialized && _controller != null) _buildControls(_controller!),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Annuler',
                      variant: AppButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: 'Continuer',
                      icon: LucideIcons.check,
                      fullWidth: true,
                      onPressed: _errorMessage == null ? _proceedToUpload : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconTile(icon: LucideIcons.circleAlert, color: AppColors.error, size: 64, iconSize: 32),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: AppText.body, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (!_isInitialized || controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          AnimatedOpacity(
            opacity: _isPlaying ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.play, color: AppColors.textPrimary, size: 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(VideoPlayerController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: EdgeInsets.zero,
              colors: const VideoProgressColors(
                playedColor: AppColors.primary,
                bufferedColor: AppColors.border,
                backgroundColor: AppColors.surface2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (context, value, _) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(value.position), style: AppText.caption),
                Text(_formatDuration(value.duration), style: AppText.caption),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Reculer de 10 s',
                onPressed: () => _seekBy(const Duration(seconds: -10)),
                icon: const Icon(LucideIcons.rotateCcw, size: 28),
              ),
              const SizedBox(width: 24),
              IconButton(
                tooltip: _isPlaying ? 'Pause' : 'Lecture',
                onPressed: _togglePlayback,
                icon: Icon(
                  _isPlaying ? LucideIcons.circlePause : LucideIcons.circlePlay,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                tooltip: 'Avancer de 10 s',
                onPressed: () => _seekBy(const Duration(seconds: 10)),
                icon: const Icon(LucideIcons.rotateCw, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
