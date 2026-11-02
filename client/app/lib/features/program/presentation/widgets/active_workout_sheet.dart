import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/core/providers/active_workout_provider.dart';
import 'package:app/core/providers/workout_provider.dart';
import 'package:app/core/widgets/ui/ui.dart';
import 'package:app/features/program/presentation/widgets/set_editor_sheet.dart';
import 'package:app/features/program/presentation/widgets/workout_actions.dart';

/// The session in progress: timer, exercises to tick off, finish button.
class ActiveWorkoutSheet extends ConsumerWidget {
  final String userId;

  const ActiveWorkoutSheet({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(activeWorkoutProvider);
    final workout = ref
        .watch(apiWorkoutProvider(userId))
        .workouts
        .where((w) => w.id == controller.workoutId)
        .firstOrNull;

    if (workout == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Aucune séance en cours', style: AppText.caption)),
      );
    }

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    'TEMPS ÉCOULÉ',
                    style: AppText.caption.copyWith(color: AppColors.onPrimary.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: controller.timer,
                    builder: (context, _) => Text(
                      controller.timer.getFormattedTime(),
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(workout.name, style: AppText.h3.copyWith(color: AppColors.onPrimary)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text('Exercices (${workout.exercises.length})', style: AppText.h3),
                ),
                TextButton.icon(
                  onPressed: () => showAddExerciseFlow(context, userId, workout),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
          ),
          Expanded(
            child: workout.exercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const IconTile(icon: LucideIcons.dumbbell, size: 56, iconSize: 28),
                        const SizedBox(height: 12),
                        const Text('Aucun exercice pour l\'instant', style: AppText.caption),
                        const SizedBox(height: 8),
                        AppButton(
                          label: 'Ajouter un exercice',
                          icon: LucideIcons.plus,
                          variant: AppButtonVariant.secondary,
                          size: AppButtonSize.sm,
                          onPressed: () => showAddExerciseFlow(context, userId, workout),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: workout.exercises.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _ExerciseRow(
                      exercise: workout.exercises[index],
                      onToggle: () => toggleExerciseDone(context, ref, userId, workout.exercises[index]),
                      onTap: () => showSetEditorSheet(context, userId, workout.exercises[index]),
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: AppButton(
              label: 'Terminer la séance',
              icon: LucideIcons.flag,
              size: AppButtonSize.lg,
              fullWidth: true,
              onPressed: () {
                Navigator.of(context).pop();
                completeActiveWorkout(context, ref, userId);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _ExerciseRow({required this.exercise, required this.onToggle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = exercise.isCompleted;
    return Material(
      color: done ? AppColors.success.withValues(alpha: 0.08) : AppColors.surface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: done ? AppColors.success : Colors.transparent),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.surface2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              IconButton(
                tooltip: done ? 'Marquer comme non fait' : 'Marquer comme fait',
                onPressed: onToggle,
                icon: Icon(
                  done ? LucideIcons.circleCheck : LucideIcons.circle,
                  color: done ? AppColors.success : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.exerciseName,
                      style: AppText.bodyMedium.copyWith(
                        color: done ? AppColors.textSecondary : AppColors.textPrimary,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(exercisePrescription(exercise), style: AppText.caption),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
