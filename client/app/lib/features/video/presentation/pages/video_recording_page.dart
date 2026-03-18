import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';

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
        _errorMessage = 'Les autorisations caméra et microphone sont requises';
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
        _errorMessage = 'Impossible d\'initialiser la caméra: $e';
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
        _errorMessage = 'Impossible de configurer la caméra: $e';
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
  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
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
        _errorMessage = 'Impossible de démarrer l\'enregistrement: $e';
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
        _errorMessage = 'Impossible d\'arrêter l\'enregistrement: $e';
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
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
            const Icon(
              Icons.videocam_off_rounded,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              'Permissions requises',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Veuillez autoriser l\'accès à la caméra et au microphone pour enregistrer des vidéos.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingL),
            ElevatedButton(
              onPressed: () async {
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingXl,
                  vertical: AppConstants.spacingM,
                ),
              ),
              child: const Text('Ouvrir les paramètres'),
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
              icon: Icons.close,
              semanticLabel: 'Fermer la caméra',
              tooltip: 'Fermer',
              onPressed: () => Navigator.of(context).pop(),
            ),

            // Flash button
            if (_isInitialized)
              _buildControlButton(
                icon: _getFlashIcon(),
                semanticLabel: 'Modifier le mode flash',
                tooltip: 'Flash',
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
              icon: Icons.cameraswitch_rounded,
              semanticLabel: 'Changer de caméra',
              tooltip: 'Changer de caméra',
              onPressed: _cameras.length > 1 ? _switchCamera : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordButton() {
    return Semantics(
      button: true,
      label: _isRecording ? 'Arrêter l\'enregistrement' : 'Démarrer l\'enregistrement',
      child: GestureDetector(
        onTap: _isRecording ? _stopRecording : _startRecording,
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
              color: _isRecording ? Colors.red : Colors.red.withOpacity(0.8),
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
    required String semanticLabel,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          tooltip: tooltip,
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
        ),
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
            color: Colors.red.withOpacity(0.8),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Text(
                _formatDuration(_recordingDuration),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
      child: Semantics(
        liveRegion: true,
        label: 'Erreur: $_errorMessage',
        child: Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.8),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          ),
          child: Text(
            _errorMessage!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
