import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/core/utils/date_utils.dart';
import 'package:app/core/utils/workout_stats.dart';
import 'package:app/core/widgets/ui/ui.dart';
import 'package:app/features/program/presentation/widgets/workout_actions.dart';

enum WorkoutMenuAction { start, edit, addExercise, delete }

/// Workout card in the style of the Figma "My program" day cards: day label,
/// title, then the numbered exercise list.
class WorkoutCard extends StatelessWidget {
  final WorkoutModel workout;
  final bool isActive;
  final VoidCallback onTap;
  final ValueChanged<WorkoutMenuAction> onMenu;

  const WorkoutCard({
    super.key,
    required this.workout,
    required this.isActive,
    required this.onTap,
    required this.onMenu,
  });

  static const _previewCount = 3;

  String _dayLabel(DateTime now) {
    final day = dateOnly(workout.workoutDate);
    final today = dateOnly(now);
    final difference = day.difference(today).inDays;
    return switch (difference) {
      0 => 'Aujourd\'hui',
      1 => 'Demain',
      -1 => 'Hier',
      _ => AppDateUtils.weekdayDayMonth(day),
    };
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = dateOnly(workout.workoutDate).isBefore(dateOnly(now));
    final exercises = workout.exercises;

    return AppCard(
      onTap: onTap,
      accentColor: isActive ? AppColors.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dayLabel(now).toUpperCase(),
                      style: AppText.caption.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(workout.name, style: AppText.h3),
                  ],
                ),
              ),
              _Menu(workout: workout, onSelected: onMenu),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (workout.durationMinutes != null)
                _Meta(icon: LucideIcons.clock3, text: '${workout.durationMinutes} min'),
              _Meta(
                icon: LucideIcons.dumbbell,
                text: '${exercises.length} exercice${exercises.length > 1 ? 's' : ''}',
              ),
              if (isActive)
                const Pill(text: 'En cours', icon: LucideIcons.timer, color: AppColors.primary, dense: true)
              else if (workout.isCompleted)
                const Pill(text: 'Terminée', icon: LucideIcons.check, color: AppColors.success, dense: true)
              else if (isPast)
                const Pill(
                  text: 'Non faite',
                  color: AppColors.textSecondary,
                  background: AppColors.surface2,
                  dense: true,
                ),
            ],
          ),
          if (exercises.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            for (final (index, exercise) in exercises.take(_previewCount).indexed) ...[
              if (index > 0) const SizedBox(height: 12),
              _NumberedExercise(number: index + 1, exercise: exercise),
            ],
            if (exercises.length > _previewCount) ...[
              const SizedBox(height: 12),
              Text(
                '+${exercises.length - _previewCount} autre${exercises.length - _previewCount > 1 ? 's' : ''} exercice${exercises.length - _previewCount > 1 ? 's' : ''}',
                style: AppText.caption,
              ),
            ],
          ],
          if (workout.notes != null && workout.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.stickyNote, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    workout.notes!,
                    style: AppText.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  final WorkoutModel workout;
  final ValueChanged<WorkoutMenuAction> onSelected;

  const _Menu({required this.workout, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    PopupMenuItem<WorkoutMenuAction> item(
      WorkoutMenuAction value,
      IconData icon,
      String label, {
      Color color = AppColors.textPrimary,
    }) {
      return PopupMenuItem(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: 18, color: color == AppColors.textPrimary ? AppColors.primary : color),
            const SizedBox(width: 12),
            Text(label, style: AppText.body.copyWith(color: color)),
          ],
        ),
      );
    }

    return SizedBox(
      width: 36,
      height: 36,
      child: PopupMenuButton<WorkoutMenuAction>(
        padding: EdgeInsets.zero,
        tooltip: 'Actions',
        icon: const Icon(LucideIcons.ellipsisVertical, size: 20, color: AppColors.textSecondary),
        onSelected: onSelected,
        itemBuilder: (context) => [
          if (!workout.isCompleted) item(WorkoutMenuAction.start, LucideIcons.play, 'Démarrer'),
          item(WorkoutMenuAction.edit, LucideIcons.pencil, 'Modifier'),
          item(WorkoutMenuAction.addExercise, LucideIcons.plus, 'Ajouter un exercice'),
          item(WorkoutMenuAction.delete, LucideIcons.trash2, 'Supprimer', color: AppColors.error),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(text, style: AppText.caption),
      ],
    );
  }
}

class _NumberedExercise extends StatelessWidget {
  final int number;
  final ExerciseModel exercise;

  const _NumberedExercise({required this.number, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final done = exercise.isCompleted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? AppColors.success.withValues(alpha: 0.1) : AppColors.surface2,
            borderRadius: BorderRadius.circular(8),
          ),
          child: done
              ? const Icon(LucideIcons.check, size: 14, color: AppColors.success)
              : Text('$number', style: AppText.caption.copyWith(color: AppColors.primary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(exercise.exerciseName, style: AppText.bodyMedium),
              const SizedBox(height: 2),
              Text(exercisePrescription(exercise), style: AppText.caption),
            ],
          ),
        ),
      ],
    );
  }
}
