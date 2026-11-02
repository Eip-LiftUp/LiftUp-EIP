import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/core/providers/active_workout_provider.dart';
import 'package:app/core/providers/workout_provider.dart';
import 'package:app/core/utils/date_utils.dart';
import 'package:app/core/widgets/ui/ui.dart';
import 'package:app/features/program/presentation/widgets/workout_actions.dart';

/// [onStart] runs once the sheet is closed, with a context that outlives it.
void showWorkoutDetailsSheet(
  BuildContext context,
  String userId,
  String workoutId, {
  required VoidCallback onStart,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => WorkoutDetailsSheet(userId: userId, workoutId: workoutId, onStart: onStart),
  );
}

class WorkoutDetailsSheet extends ConsumerWidget {
  final String userId;
  final String workoutId;
  final VoidCallback onStart;

  const WorkoutDetailsSheet({
    super.key,
    required this.userId,
    required this.workoutId,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // byId: the workout may have been created offline and renamed since.
    final workout = ref.watch(apiWorkoutProvider(userId)).byId(workoutId);
    if (workout == null) return const SizedBox(height: 120);

    final isActive = ref.watch(activeWorkoutProvider).workoutId == workout.id;
    final totalSets = workout.exercises.fold<int>(0, (sum, e) => sum + e.setsCount);

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Row(
            children: [
              IconTile(
                icon: workout.isCompleted ? LucideIcons.circleCheck : LucideIcons.dumbbell,
                color: workout.isCompleted ? AppColors.success : AppColors.primary,
                size: 56,
                iconSize: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.name, style: AppText.h2),
                    const SizedBox(height: 2),
                    Text(AppDateUtils.weekdayDayMonth(workout.workoutDate), style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
          if (!workout.isCompleted) ...[
            const SizedBox(height: 20),
            AppButton(
              label: isActive ? 'Reprendre la séance' : 'Démarrer la séance',
              icon: LucideIcons.play,
              fullWidth: true,
              onPressed: () {
                Navigator.of(context).pop();
                onStart();
              },
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: LucideIcons.clock,
                  value: workout.durationMinutes?.toString() ?? '—',
                  label: 'Minutes',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Stat(
                  icon: LucideIcons.dumbbell,
                  value: '${workout.exercises.length}',
                  label: 'Exercices',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _Stat(icon: LucideIcons.repeat, value: '$totalSets', label: 'Séries')),
            ],
          ),
          if (workout.notes != null && workout.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            AppCard(
              elevated: true,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.stickyNote, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(workout.notes!, style: AppText.body)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Text('Exercices', style: AppText.h3)),
              TextButton.icon(
                onPressed: () => showAddExerciseFlow(context, userId, workout),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (workout.exercises.isEmpty)
            const AppCard(
              elevated: true,
              child: Text('Aucun exercice pour l\'instant.', style: AppText.caption),
            )
          else
            for (final exercise in workout.exercises) ...[
              _ExerciseTile(
                exercise: exercise,
                onTap: () => showExerciseDetailsDialog(context, ref, userId, exercise),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(value, style: AppText.h3.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback onTap;

  const _ExerciseTile({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = exercise.isCompleted;
    return AppCard(
      onTap: onTap,
      elevated: true,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            done ? LucideIcons.circleCheck : LucideIcons.circle,
            color: done ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: AppText.bodyMedium.copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  exercisePrescription(exercise),
                  semanticsLabel: exercisePrescriptionLabel(exercise),
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
