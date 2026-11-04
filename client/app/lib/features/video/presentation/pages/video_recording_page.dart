import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/ui/ui.dart';

/// Video Recording Page
/// 
/// This page provides a camera interface for recording videos.
/// It handles camera initialization, permission requests, and
/// video recording controls.
class VideoRecordingPage extends StatefulWidget {
  /// Callback when a video is recorded successfully
  final void Function(String videoPath)? onVideoRecorded;

  const VideoRecordingPage({
    super.key,
    this.onVideoRecorded,
  });

  @override
  State<VideoRecordingPage> createState() => _VideoRecordingPageState();
}

class _VideoRecordingPageState extends State<VideoRecordingPage>
    with WidgetsBindingObserver {
  /// Camera controller for managing camera operations
  CameraController? _controller;

  /// List of available cameras on the device
  List<CameraDescription> _cameras = [];

  /// Currently selected camera index
  int _selectedCameraIndex = 0;

  /// Whether the camera is initialized
  bool _isInitialized = false;

  /// Whether currently recording
  bool _isRecording = false;

  /// Recording duration timer
  Timer? _recordingTimer;

  /// Current recording duration in seconds
  int _recordingDuration = 0;

  /// Flash mode
  FlashMode _flashMode = FlashMode.off;

  /// Error message to display
  String? _errorMessage;

  /// Permission status
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  /// Initialize the camera
  Future<void> _initializeCamera() async {
    // Request camera and microphone permissions
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();

    if (!cameraStatus.isGranted || !microphoneStatus.isGranted) {
      setState(() {
        _hasPermission = false;
        _errorMessage = 'L\'accès à la caméra et au micro est nécessaire';
      });
      return;
    }

    setState(() {
      _hasPermission = true;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'Aucune caméra disponible sur cet appareil';
        });
        return;
      }

      await _setupCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible d\'initialiser la caméra : $e';
      });
    }
  }

  /// Setup camera controller with the given camera
  Future<void> _setupCameraController(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = controller;

    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de configurer la caméra : $e';
      });
    }
  }

  /// Switch between front and back camera
  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    setState(() {
      _isInitialized = false;
    });

    await _controller?.dispose();
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  /// Toggle flash mode
  Future<void> _toggleFlash() async {
    if (_controller == null) return;

    FlashMode newMode;
    switch (_flashMode) {
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        newMode = FlashMode.off;
        break;
    }

    try {
      await _controller!.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
      });
    } catch (e) {
      // Flash not supported
    }
  }

  /// Get flash icon based on current mode
  String _flashLabel() => switch (_flashMode) {
        FlashMode.off => 'Flash désactivé',
        FlashMode.auto => 'Flash automatique',
        FlashMode.always => 'Flash activé',
        FlashMode.torch => 'Lampe allumée',
      };

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return LucideIcons.zapOff;
      case FlashMode.auto:
        return LucideIcons.zap;
      case FlashMode.always:
        return LucideIcons.zap;
      case FlashMode.torch:
        return LucideIcons.flashlight;
    }
  }

  /// Start recording video
  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
      });

      // Start timer to track recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de démarrer l\'enregistrement : $e';
      });
    }
  }

  /// Stop recording video
  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;

    _recordingTimer?.cancel();

    try {
      final file = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });

      // Call the callback with the video path
      widget.onVideoRecorded?.call(file.path);

      // Navigate to video preview
      if (mounted) {
        Navigator.of(context).pop(file.path);
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _errorMessage = 'Impossible d\'arrêter l\'enregistrement : $e';
      });
    }
  }

  /// Format recording duration to MM:SS
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            _buildCameraPreview(),

            // Top controls
            _buildTopControls(),

            // Bottom controls
            _buildBottomControls(),

            // Recording indicator
            if (_isRecording) _buildRecordingIndicator(),

            // Error message
            if (_errorMessage != null) _buildErrorMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_hasPermission) {
      return _buildPermissionRequest();
    }

    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: CameraPreview(_controller!),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const IconTile(
              icon: LucideIcons.videoOff,
              color: AppColors.textSecondary,
              background: AppColors.surface2,
              size: 80,
              iconSize: 36,
            ),
            const SizedBox(height: AppConstants.spacingL),
            const Text('Autorisations requises', style: AppText.metric, textAlign: TextAlign.center),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Autorise l\'accès à la caméra et au micro pour filmer ton mouvement.',
              style: AppText.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingL),
            AppButton(
              label: 'Ouvrir les paramètres',
              icon: LucideIcons.settings,
              onPressed: openAppSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: AppConstants.spacingM,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button
            _buildControlButton(
              icon: LucideIcons.x,
              tooltip: 'Fermer',
              onPressed: () => Navigator.of(context).pop(),
            ),

            // Flash button
            if (_isInitialized)
              _buildControlButton(
                icon: _getFlashIcon(),
                tooltip: _flashLabel(),
                onPressed: _toggleFlash,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: AppConstants.spacingXl,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Placeholder for alignment
            const SizedBox(width: 60),

            // Record button
            _buildRecordButton(),

            // Switch camera button
            _buildControlButton(
              icon: LucideIcons.switchCamera,
              tooltip: 'Changer de caméra',
              onPressed: _cameras.length > 1 ? _switchCamera : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordButton() {
    final onTap = _isRecording ? _stopRecording : _startRecording;
    return Semantics(
      button: true,
      label: _isRecording ? 'Arrêter l\'enregistrement' : 'Démarrer l\'enregistrement',
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _isRecording ? AppColors.error : AppColors.error.withValues(alpha: 0.85),
              shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: _isRecording ? BorderRadius.circular(8) : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: AppColors.textPrimary),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Positioned(
      top: AppConstants.spacingM + 60,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.onPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              // Dark text: white only reaches 3:1 on this red.
              Text(
                _formatDuration(_recordingDuration),
                style: AppText.bodyMedium.copyWith(
                  color: AppColors.onPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Positioned(
      bottom: 150,
      left: AppConstants.spacingL,
      right: AppConstants.spacingL,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _errorMessage!,
          style: AppText.body.copyWith(fontSize: 14, color: AppColors.onPrimary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
