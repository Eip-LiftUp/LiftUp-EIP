import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/connectivity_provider.dart';
import 'package:app/core/providers/workout_provider.dart';
import 'package:app/core/sync/pending_operation.dart';
import 'package:app/core/widgets/ui/ui.dart';

String _changes(int count) => '$count modification${count > 1 ? 's' : ''}';

/// "à l'instant", "il y a 5 min", "aujourd'hui à 10:42", "le 2 nov. à 10:42".
String syncedAgo(DateTime at, DateTime now) {
  final minutes = now.difference(at).inMinutes;
  if (minutes < 1) return 'à l\'instant';
  if (minutes < 60) return 'il y a $minutes min';
  final time = DateFormat.Hm().format(at);
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  if (day == today) return 'aujourd\'hui à $time';
  if (day == today.subtract(const Duration(days: 1))) return 'hier à $time';
  return 'le ${DateFormat('d MMM').format(at)} à $time';
}

/// Thin strip above the tabs while the device is offline or holds changes
/// the server has not received; also shows the messages of each sync.
class SyncBanner extends ConsumerWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).userId;
    if (userId == null) return const SizedBox.shrink();
    final online = ref.watch(isOnlineProvider);
    final sync = ref.watch(apiWorkoutProvider(userId));

    ref.listen(apiWorkoutProvider(userId).select((s) => s.notices), (_, notices) {
      if (notices.isEmpty) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(notices.join('\n'), style: AppText.body)));
      ref.read(apiWorkoutProvider(userId).notifier).clearNotices();
    });

    final (IconData icon, Color color, String text)? status = switch (sync) {
      _ when sync.rejected.isNotEmpty => (
          LucideIcons.circleAlert,
          AppColors.warning,
          '${_changes(sync.rejected.length)} refusée${sync.rejected.length > 1 ? 's' : ''} par le serveur',
        ),
      _ when !online => (
          LucideIcons.wifiOff,
          AppColors.textSecondary,
          sync.pendingCount == 0
              ? 'Hors ligne · tes séances restent disponibles'
              : 'Hors ligne · ${_changes(sync.pendingCount)} en attente',
        ),
      _ when sync.pendingCount > 0 => (
          LucideIcons.refreshCw,
          AppColors.primary,
          sync.isSyncing ? 'Synchronisation de ${_changes(sync.pendingCount)}…' : '${_changes(sync.pendingCount)} en attente d\'envoi',
        ),
      _ => null,
    };
    if (status == null) return const SizedBox.shrink();
    final (icon, color, text) = status;

    return Semantics(
      container: true,
      liveRegion: true,
      button: sync.rejected.isNotEmpty,
      child: InkWell(
        onTap: sync.rejected.isEmpty ? null : () => context.go('/profile'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Flexible(child: Text(text, style: AppText.caption.copyWith(color: color))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma "Sync Status" card of the profile: state of the device copy, with
/// a manual sync and the changes the server refused.
class SyncStatusCard extends ConsumerWidget {
  final String userId;

  const SyncStatusCard({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);
    final sync = ref.watch(apiWorkoutProvider(userId));
    final notifier = ref.read(apiWorkoutProvider(userId).notifier);
    final syncedAt = sync.lastSyncedAt;

    final (IconData icon, Color color, String status) = switch (sync) {
      _ when sync.rejected.isNotEmpty => (
          LucideIcons.circleAlert,
          AppColors.warning,
          '${_changes(sync.rejected.length)} refusée${sync.rejected.length > 1 ? 's' : ''} par le serveur',
        ),
      _ when !online => (
          LucideIcons.wifiOff,
          AppColors.textSecondary,
          sync.pendingCount == 0
              ? 'Hors ligne · tout est enregistré sur l\'appareil'
              : 'Hors ligne · ${_changes(sync.pendingCount)} en attente',
        ),
      _ when sync.isSyncing => (LucideIcons.refreshCw, AppColors.primary, 'Synchronisation en cours…'),
      _ when sync.pendingCount > 0 => (
          LucideIcons.refreshCw,
          AppColors.primary,
          '${_changes(sync.pendingCount)} en attente d\'envoi',
        ),
      _ => (
          LucideIcons.circleCheck,
          AppColors.success,
          syncedAt == null ? 'Pas encore synchronisé' : 'À jour · synchronisé ${syncedAgo(syncedAt, DateTime.now())}',
        ),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconTile(icon: icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Synchronisation', style: AppText.bodyMedium),
                      const SizedBox(height: 2),
                      Text(status, style: AppText.caption),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Synchroniser maintenant',
                onPressed: online && !sync.isSyncing ? notifier.sync : null,
                icon: Icon(online ? LucideIcons.refreshCw : LucideIcons.wifiOff, size: 20),
              ),
            ],
          ),
          if (sync.rejected.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final operation in sync.rejected)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${describeOperation(operation, sync)} — ${operation.rejection}',
                  style: AppText.caption,
                ),
              ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton(
                  label: 'Réessayer',
                  icon: LucideIcons.rotateCcw,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.sm,
                  onPressed: online ? notifier.retryRejected : null,
                ),
                AppButton(
                  label: 'Abandonner',
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.sm,
                  onPressed: () => _confirmDiscard(context, notifier),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDiscard(BuildContext context, ApiWorkoutNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandonner ces modifications ?'),
        content: const Text('Elles seront retirées de l\'appareil et la version du serveur sera gardée.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          AppButton(
            label: 'Abandonner',
            variant: AppButtonVariant.destructive,
            size: AppButtonSize.sm,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) await notifier.discardRejected();
  }
}

/// "Création de la séance « Jambes »", "Modification de l'exercice « Squat »"…
String describeOperation(PendingOperation operation, ApiWorkoutState state) {
  final workout = state.byId(operation.workoutId);
  final workoutName = operation.fields['name'] as String? ?? workout?.name;
  final exerciseName = operation.fields['exerciseName'] as String? ??
      workout?.exercises.where((e) => e.id == operation.exerciseId).firstOrNull?.exerciseName;
  String quoted(String? name) => name == null ? '' : ' « $name »';
  return switch (operation.type) {
    OperationType.createWorkout => 'Création de la séance${quoted(workoutName)}',
    OperationType.updateWorkout => 'Modification de la séance${quoted(workoutName)}',
    OperationType.deleteWorkout => 'Suppression de la séance${quoted(workoutName)}',
    OperationType.createExercise => 'Ajout de l\'exercice${quoted(exerciseName)}',
    OperationType.updateExercise => 'Modification de l\'exercice${quoted(exerciseName)}',
    OperationType.deleteExercise => 'Suppression de l\'exercice${quoted(exerciseName)}',
  };
}
