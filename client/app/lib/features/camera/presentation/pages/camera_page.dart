import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/features/camera/presentation/widgets/camera_preview_widget.dart';
import 'package:app/features/camera/presentation/widgets/lm_comments_section.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  String? _error;
  bool _showComments = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        setState(() {
          _error = 'No cameras available';
        });
        return;
      }

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        actions: [
          IconButton(
            icon: Icon(_showComments ? Icons.videocam : Icons.comment),
            onPressed: _toggleComments,
            tooltip: _showComments ? 'Show Camera' : 'Show LM Comments',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingM),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                });
                _initializeCamera();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return _showComments
        ? LMCommentsSection(
            onBackToCamera: _toggleComments,
          )
        : CameraPreviewWidget(
            controller: _cameraController!,
            onShowComments: _toggleComments,
          );
  }
}
