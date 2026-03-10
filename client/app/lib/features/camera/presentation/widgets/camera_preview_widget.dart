import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:app/core/constants/app_constants.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;
  final VoidCallback onShowComments;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    required this.onShowComments,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: CameraPreview(controller),
        ),
        
        // Overlay with guide lines
        Positioned.fill(
          child: CustomPaint(
            painter: _CameraOverlayPainter(),
          ),
        ),
        
        // Controls at the bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      context,
                      icon: Icons.comment,
                      label: 'LM Comments',
                      onTap: onShowComments,
                    ),
                    _buildControlButton(
                      context,
                      icon: Icons.camera,
                      label: 'Capture',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Capture feature coming soon'),
                          ),
                        );
                      },
                    ),
                    _buildControlButton(
                      context,
                      icon: Icons.flip_camera_android,
                      label: 'Flip',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Camera flip coming soon'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  'Position yourself in the frame',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw center crosshair
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final crosshairSize = 40.0;

    // Horizontal line
    canvas.drawLine(
      Offset(centerX - crosshairSize, centerY),
      Offset(centerX + crosshairSize, centerY),
      paint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(centerX, centerY - crosshairSize),
      Offset(centerX, centerY + crosshairSize),
      paint,
    );

    // Draw grid lines (rule of thirds)
    paint.color = Colors.white.withValues(alpha: 0.2);
    
    // Vertical lines
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(2 * size.width / 3, 0),
      Offset(2 * size.width / 3, size.height),
      paint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, 2 * size.height / 3),
      Offset(size.width, 2 * size.height / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
