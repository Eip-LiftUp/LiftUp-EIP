import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/core/providers/workout_provider.dart';
import 'package:app/core/utils/workout_stats.dart';
import 'package:app/core/widgets/ui/ui.dart';
import 'package:app/features/program/presentation/widgets/workout_actions.dart';

void showSetEditorSheet(BuildContext context, String userId, ExerciseModel exercise) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => SetEditorSheet(userId: userId, exercise: exercise),
  );
}

/// Set-by-set logging (weight, reps, done) with last session's numbers
/// for reference.
class SetEditorSheet extends ConsumerStatefulWidget {
  final String userId;
  final ExerciseModel exercise;

  const SetEditorSheet({super.key, required this.userId, required this.exercise});

  @override
  ConsumerState<SetEditorSheet> createState() => _SetEditorSheetState();
}

class _SetEditorSheetState extends ConsumerState<SetEditorSheet> {
  static const _restSeconds = 120;

  late final List<SetModel> _sets = widget.exercise.sets.isEmpty
      ? List.generate(3, (i) => SetModel(setNumber: i + 1, reps: 10))
      : [...widget.exercise.sets];
  late final _notes = TextEditingController(text: widget.exercise.notes ?? '');
  final List<TextEditingController> _weights = [];
  final List<TextEditingController> _reps = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final set in _sets) {
      _addControllers(set);
    }
  }

  @override
  void dispose() {
    for (final c in [..._weights, ..._reps, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _addControllers(SetModel set) {
    _weights.add(TextEditingController(text: _number(set.weight)));
    _reps.add(TextEditingController(text: '${set.reps}'));
  }

  static String _number(double? value) {
    if (value == null || value == 0) return '';
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  void _updateSet(int index, {double? weight, int? reps, bool? done, bool clearWeight = false}) {
    final s = _sets[index];
    setState(() {
      _sets[index] = SetModel(
        setNumber: s.setNumber,
        reps: reps ?? s.reps,
        weight: clearWeight ? null : (weight ?? s.weight),
        isCompleted: done ?? s.isCompleted,
      );
    });
  }

  void _addSet() {
    final last = _sets.isNotEmpty ? _sets.last : null;
    final set = SetModel(setNumber: _sets.length + 1, reps: last?.reps ?? 10, weight: last?.weight);
    setState(() {
      _sets.add(set);
      _addControllers(set);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await ref.read(apiWorkoutProvider(widget.userId).notifier).updateExercise(
          exerciseId: widget.exercise.id,
          sets: _sets.length,
          reps: _sets.isNotEmpty ? _sets.first.reps : 10,
          weight: _sets.isNotEmpty ? _sets.first.weight : null,
          setsData: _sets,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      showAppSnack(context, 'Exercice mis à jour');
    } else {
      setState(() => _saving = false);
      showAppSnack(context, 'L\'enregistrement a échoué', error: true);
    }
  }

  Future<void> _delete() async {
    final ok = await ref.read(apiWorkoutProvider(widget.userId).notifier).deleteExercise(widget.exercise.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    showAppSnack(context, ok ? 'Exercice supprimé' : 'La suppression a échoué', error: !ok);
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final previous = WorkoutStats(ref.watch(apiWorkoutProvider(widget.userId)).workouts)
        .previousPerformance(exercise.exerciseName, excludingWorkoutId: exercise.workoutId);
    final unit = exercise.weightUnit.displayName;

    String previousLabel(int index) {
      if (previous == null || index >= previous.sets.length) return '—';
      final set = previous.sets[index];
      final weight = _number(set.weight);
      return weight.isEmpty ? '× ${set.reps}' : '$weight ${previous.weightUnit.displayName} × ${set.reps}';
    }

    Widget setRow(int index) {
      final set = _sets[index];
      final done = set.isCompleted;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: done ? AppColors.success.withValues(alpha: 0.1) : AppColors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: done ? AppColors.success : Colors.transparent),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  '${set.setNumber}',
                  style: AppText.bodyMedium.copyWith(
                    color: done ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  previousLabel(index),
                  semanticsLabel: 'Précédent : ${previousLabel(index)}',
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: _CellField(
                  label: 'Série ${set.setNumber}, poids en $unit',
                  controller: _weights[index],
                  hint: '—',
                  decimal: true,
                  onChanged: (value) {
                    final parsed = double.tryParse(value.replaceAll(',', '.'));
                    _updateSet(index, weight: parsed, clearWeight: parsed == null);
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _CellField(
                  label: 'Série ${set.setNumber}, répétitions',
                  controller: _reps[index],
                  hint: '0',
                  onChanged: (value) => _updateSet(index, reps: int.tryParse(value) ?? 0),
                ),
              ),
              SizedBox(
                width: 44,
                child: IconButton(
                  tooltip: done
                      ? 'Série ${set.setNumber} : marquer comme non faite'
                      : 'Série ${set.setNumber} : marquer comme faite',
                  onPressed: () => _updateSet(index, done: !done),
                  icon: Icon(
                    done ? LucideIcons.circleCheck : LucideIcons.circle,
                    color: done ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          // Everything but the save button scrolls, so large text still fits.
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const IconTile(icon: LucideIcons.dumbbell, size: 48, iconSize: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exercise.exerciseName, style: AppText.h2),
                            Text('${_sets.length} séries', style: AppText.caption),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Options de l\'exercice',
                        icon: const Icon(LucideIcons.ellipsis),
                        onSelected: (value) {
                          if (value == 'delete') _delete();
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'replace',
                            child: Row(
                              children: [
                                Icon(LucideIcons.arrowLeftRight, size: 18, color: AppColors.primary),
                                SizedBox(width: 12),
                                Text('Remplacer l\'exercice'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                                SizedBox(width: 12),
                                Text('Supprimer', style: TextStyle(color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: AppTextField(hint: 'Ajouter une note…', controller: _notes),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Pill(
                      text: 'Repos : ${_restSeconds ~/ 60} min',
                      icon: LucideIcons.timer,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Divider(),
                // Column titles; each field below carries its own label.
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 12, 32, 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 40, child: Text('SÉRIE', style: AppText.caption)),
                        const Expanded(
                          flex: 2,
                          child: Text('PRÉCÉDENT', style: AppText.caption, textAlign: TextAlign.center),
                        ),
                        Expanded(
                          child: Text(unit.toUpperCase(), style: AppText.caption, textAlign: TextAlign.center),
                        ),
                        const Expanded(
                          child: Text('REPS', style: AppText.caption, textAlign: TextAlign.center),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                ),
                for (var index = 0; index < _sets.length; index++) setRow(index),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: AppButton(
                    label: 'Ajouter une série',
                    icon: LucideIcons.plus,
                    variant: AppButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: _addSet,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: AppButton(
              label: 'Enregistrer',
              fullWidth: true,
              size: AppButtonSize.lg,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}

class _CellField extends StatelessWidget {
  /// Spoken name of the field, e.g. "Série 2, répétitions".
  final String label;
  final TextEditingController controller;
  final String hint;
  final bool decimal;
  final ValueChanged<String> onChanged;

  const _CellField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.decimal = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    );
    return Semantics(
      container: true,
      label: label,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        style: AppText.bodyMedium.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          fillColor: AppColors.background,
          // 44px high, the minimum touch target.
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
