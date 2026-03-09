import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';
import 'video_upload_page.dart';

/// Video Preview Page
/// 
/// This page displays a preview of the selected/recorded video
/// and allows users to confirm or discard their selection.
class VideoPreviewPage extends StatefulWidget {
  /// Path to the video file
  final String videoPath;

  /// Callback when user confirms the video
  final void Function(String videoPath)? onConfirm;

  const VideoPreviewPage({
    super.key,
    required this.videoPath,
    this.onConfirm,
  });

  @override
  State<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage> {
  /// Video player controller
  VideoPlayerController? _controller;

  /// Whether the video is initialized
  bool _isInitialized = false;

  /// Whether the video is playing
  bool _isPlaying = false;

  /// Error message
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

  /// Initialize the video player
  Future<void> _initializeVideo() async {
    try {
      final file = File(widget.videoPath);
      if (!await file.exists()) {
        setState(() {
          _errorMessage = 'Le fichier vidéo n\'existe pas';
        });
        return;
      }

      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      await _controller!.setLooping(true);

      _controller!.addListener(() {
        if (mounted) {
          setState(() {
            _isPlaying = _controller!.value.isPlaying;
          });
        }
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger la vidéo: $e';
      });
    }
  }

  /// Toggle video playback
  void _togglePlayback() {
    if (_controller == null) return;

    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  /// Get formatted position/duration
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Navigate to upload page
  void _proceedToUpload() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoUploadPage(
          videoPath: widget.videoPath,
          onUploadComplete: (url) {
            widget.onConfirm?.call(widget.videoPath);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Aperçu vidéo',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video player
            Expanded(
              child: _buildVideoPlayer(),
            ),

            // Video info and controls
            _buildVideoInfo(),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),

          // Play/pause overlay
          AnimatedOpacity(
            opacity: _isPlaying ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoInfo() {
    if (!_isInitialized || _controller == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      color: AppColors.cardBackground,
      child: Column(
        children: [
          // Progress bar
          VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: AppColors.primary,
              bufferedColor: AppColors.textSecondary,
              backgroundColor: AppColors.navBarBorder,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),

          // Duration info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controller!,
                builder: (context, value, child) {
                  return Text(
                    _formatDuration(value.position),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  );
                },
              ),
              Text(
                _formatDuration(_controller!.value.duration),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),

          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Replay 10 seconds
              IconButton(
                onPressed: () {
                  final position = _controller!.value.position;
                  _controller!.seekTo(position - const Duration(seconds: 10));
                },
                icon: const Icon(
                  Icons.replay_10,
                  color: AppColors.textPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppConstants.spacingL),

              // Play/pause
              IconButton(
                onPressed: _togglePlayback,
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: AppColors.primary,
                  size: 56,
                ),
              ),
              const SizedBox(width: AppConstants.spacingL),

              // Forward 10 seconds
              IconButton(
                onPressed: () {
                  final position = _controller!.value.position;
                  _controller!.seekTo(position + const Duration(seconds: 10));
                },
                icon: const Icon(
                  Icons.forward_10,
                  color: AppColors.textPrimary,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      color: AppColors.background,
      child: Row(
        children: [
          // Discard button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Annuler'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.textSecondary),
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingM,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),

          // Confirm button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _proceedToUpload,
              icon: const Icon(Icons.check),
              label: const Text('Continuer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spacingM,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
