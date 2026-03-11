import 'package:flutter/material.dart';
import 'package:app/core/constants/app_constants.dart';

class LMCommentsSection extends StatefulWidget {
  final VoidCallback onBackToCamera;

  const LMCommentsSection({
    super.key,
    required this.onBackToCamera,
  });

  @override
  State<LMCommentsSection> createState() => _LMCommentsSectionState();
}

class _LMCommentsSectionState extends State<LMCommentsSection> {
  // Placeholder for LM comments - will be replaced with actual LM integration
  final List<LMComment> _comments = [
    LMComment(
      id: '1',
      text: 'Great form on that squat! Keep your chest up.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      type: CommentType.positive,
    ),
    LMComment(
      id: '2',
      text: 'Your knees are going too far forward. Try to sit back more.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      type: CommentType.correction,
    ),
    LMComment(
      id: '3',
      text: 'Maintain that tempo! You\'re doing well.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      type: CommentType.encouragement,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with info
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: [
              Icon(
                Icons.smart_toy,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LM Coach Comments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'AI-powered feedback on your form',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Comments list
        Expanded(
          child: _comments.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  itemCount: _comments.length,
                  separatorBuilder: (context, index) => const SizedBox(
                    height: AppConstants.spacingM,
                  ),
                  itemBuilder: (context, index) {
                    return _buildCommentCard(context, _comments[index]);
                  },
                ),
        ),
        
        // Footer
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: widget.onBackToCamera,
                icon: const Icon(Icons.videocam),
                label: const Text('Back to Camera'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                'LM integration pending',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'No comments yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Start recording to get AI feedback',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(BuildContext context, LMComment comment) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CommentTypeIcon(type: comment.type),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  _getCommentTypeLabel(comment.type),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _getCommentColor(context, comment.type),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(comment.timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              comment.text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _getCommentTypeLabel(CommentType type) {
    switch (type) {
      case CommentType.positive:
        return 'Great!';
      case CommentType.correction:
        return 'Correction';
      case CommentType.encouragement:
        return 'Keep Going!';
      case CommentType.warning:
        return 'Warning';
    }
  }

  Color _getCommentColor(BuildContext context, CommentType type) {
    switch (type) {
      case CommentType.positive:
        return Colors.green;
      case CommentType.correction:
        return Colors.orange;
      case CommentType.encouragement:
        return Colors.blue;
      case CommentType.warning:
        return Colors.red;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class _CommentTypeIcon extends StatelessWidget {
  final CommentType type;

  const _CommentTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case CommentType.positive:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case CommentType.correction:
        icon = Icons.info;
        color = Colors.orange;
        break;
      case CommentType.encouragement:
        icon = Icons.favorite;
        color = Colors.blue;
        break;
      case CommentType.warning:
        icon = Icons.warning;
        color = Colors.red;
        break;
    }

    return Icon(icon, size: 20, color: color);
  }
}

// Data models for LM comments (placeholder until real LM integration)
class LMComment {
  final String id;
  final String text;
  final DateTime timestamp;
  final CommentType type;

  LMComment({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.type,
  });
}

enum CommentType {
  positive,
  correction,
  encouragement,
  warning,
}
