import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/core/providers/active_workout_provider.dart';
import 'package:app/core/providers/exercise_provider.dart';
import 'package:app/core/providers/workout_provider.dart';
import 'package:app/core/utils/date_utils.dart';
import 'package:app/core/widgets/ui/ui.dart';
import 'package:app/features/program/presentation/widgets/active_workout_sheet.dart';

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? LucideIcons.circleAlert : LucideIcons.circleCheck,
              size: 20,
              color: error ? AppColors.error : AppColors.success,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: AppText.body)),
          ],
        ),
      ),
    );
}

/// "4 × 8 • 60 kg"
String exercisePrescription(ExerciseModel exercise) {
  final parts = ['${exercise.setsCount} × ${exercise.reps}'];
  final weight = exercise.weight;
  if (weight != null && weight > 0) {
    parts.add('${_formatNumber(weight)} ${exercise.weightUnit.displayName}');
  }
  return parts.join(' • ');
}

String _formatNumber(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : value.toString();

// ==================== Session lifecycle ====================

void startWorkout(BuildContext context, WidgetRef ref, String userId, WorkoutModel workout) {
  ref.read(activeWorkoutProvider).start(workout.id);
  showActiveWorkoutSheet(context, userId);
}

void showActiveWorkoutSheet(BuildContext context, String userId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => ActiveWorkoutSheet(userId: userId),
  );
}

Future<void> completeActiveWorkout(BuildContext context, WidgetRef ref, String userId) async {
  final controller = ref.read(activeWorkoutProvider);
  final workoutId = controller.workoutId;
  if (workoutId == null) return;
  final minutes = controller.finish();
  final ok = await ref.read(apiWorkoutProvider(userId).notifier).updateWorkout(
        workoutId: workoutId,
        durationMinutes: minutes,
        isCompleted: true,
      );
  if (context.mounted) {
    showAppSnack(
      context,
      ok ? 'Séance terminée ! Durée : $minutes min' : 'Impossible d\'enregistrer la séance',
      error: !ok,
    );
  }
}

/// Marks every set of the exercise done (or not), since completion is
/// derived from the sets.
Future<void> toggleExerciseDone(
  BuildContext context,
  WidgetRef ref,
  String userId,
  ExerciseModel exercise,
) async {
  final done = !exercise.isCompleted;
  final sets = exercise.sets.isEmpty
      ? List.generate(exercise.setsCount, (i) => SetModel(setNumber: i + 1, reps: exercise.reps))
      : exercise.sets;
  final ok = await ref.read(apiWorkoutProvider(userId).notifier).updateExercise(
        exerciseId: exercise.id,
        isCompleted: done,
        setsData: [for (final s in sets) s.copyWith(isCompleted: done)],
      );
  if (!ok && context.mounted) showAppSnack(context, 'Impossible de mettre à jour l\'exercice', error: true);
}

// ==================== Workouts ====================

Future<void> showWorkoutFormDialog(BuildContext context, String userId, {WorkoutModel? workout}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _WorkoutFormDialog(userId: userId, workout: workout),
  );
}

class _WorkoutFormDialog extends ConsumerStatefulWidget {
  final String userId;
  final WorkoutModel? workout;

  const _WorkoutFormDialog({required this.userId, this.workout});

  @override
  ConsumerState<_WorkoutFormDialog> createState() => _WorkoutFormDialogState();
}

class _WorkoutFormDialogState extends ConsumerState<_WorkoutFormDialog> {
  late final _name = TextEditingController(text: widget.workout?.name ?? '');
  late final _notes = TextEditingController(text: widget.workout?.notes ?? '');
  late final _dateText = TextEditingController();
  late DateTime _date = widget.workout?.workoutDate ?? DateTime.now();
  late bool _completed = widget.workout?.isCompleted ?? false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.workout != null;

  @override
  void initState() {
    super.initState();
    _dateText.text = AppDateUtils.weekdayDayMonth(_date);
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _dateText.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateText.text = AppDateUtils.weekdayDayMonth(picked);
      });
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Le nom est requis');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final notifier = ref.read(apiWorkoutProvider(widget.userId).notifier);
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final bool ok;
    if (_isEdit) {
      ok = await notifier.updateWorkout(
        workoutId: widget.workout!.id,
        name: name,
        workoutDate: _date,
        notes: notes,
        isCompleted: _completed,
      );
    } else {
      ok = await notifier.createWorkout(name: name, workoutDate: _date, notes: notes) != null;
    }

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      showAppSnack(context, _isEdit ? 'Séance modifiée' : 'Séance créée');
    } else {
      setState(() {
        _saving = false;
        _error = 'L\'enregistrement a échoué, réessaie.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Modifier la séance' : 'Nouvelle séance'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Nom',
              hint: 'ex : Haut du corps',
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Date',
              controller: _dateText,
              readOnly: true,
              onTap: _pickDate,
              trailing: const Icon(LucideIcons.calendar, size: 20),
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'Notes (facultatif)', controller: _notes, maxLines: 3),
            if (_isEdit) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _completed,
                onChanged: (value) => setState(() => _completed = value ?? false),
                title: const Text('Séance terminée', style: AppText.body),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
            if (_error != null) ...[const SizedBox(height: 12), InlineError(_error!)],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        AppButton(
          label: _isEdit ? 'Enregistrer' : 'Créer',
          size: AppButtonSize.sm,
          loading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}

Future<void> confirmDeleteWorkout(BuildContext context, WidgetRef ref, String userId, WorkoutModel workout) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer la séance ?'),
      content: Text('« ${workout.name} » sera supprimée définitivement.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
        AppButton(
          label: 'Supprimer',
          variant: AppButtonVariant.destructive,
          size: AppButtonSize.sm,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  final ok = await ref.read(apiWorkoutProvider(userId).notifier).deleteWorkout(workout.id);
  if (context.mounted) {
    showAppSnack(context, ok ? 'Séance supprimée' : 'La suppression a échoué', error: !ok);
  }
}

// ==================== Exercises ====================

/// Picks an exercise from the catalogue (or a custom name), then asks for
/// sets, reps and weight before adding it to [workout].
Future<void> showAddExerciseFlow(BuildContext context, String userId, WorkoutModel workout) async {
  final name = await showDialog<String>(
    context: context,
    builder: (_) => const _ExercisePickerDialog(),
  );
  if (name == null || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => _ExerciseFormDialog(userId: userId, workoutId: workout.id, initialName: name),
  );
}

Future<void> showEditExerciseDialog(BuildContext context, String userId, ExerciseModel exercise) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ExerciseFormDialog(
      userId: userId,
      workoutId: exercise.workoutId,
      initialName: exercise.exerciseName,
      exercise: exercise,
    ),
  );
}

Future<void> showExerciseDetailsDialog(
  BuildContext context,
  WidgetRef ref,
  String userId,
  ExerciseModel exercise,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(exercise.exerciseName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailRow('Séries', '${exercise.setsCount}'),
          _DetailRow('Répétitions', '${exercise.reps}'),
          if (exercise.weight != null && exercise.weight! > 0)
            _DetailRow('Poids', '${_formatNumber(exercise.weight!)} ${exercise.weightUnit.displayName}'),
          if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Notes', style: AppText.caption),
            const SizedBox(height: 4),
            Text(exercise.notes!, style: AppText.body),
          ],
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            final ok = await ref.read(apiWorkoutProvider(userId).notifier).deleteExercise(exercise.id);
            if (context.mounted) {
              showAppSnack(context, ok ? 'Exercice supprimé' : 'La suppression a échoué', error: !ok);
            }
          },
          child: const Text('Supprimer'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            showEditExerciseDialog(context, userId, exercise);
          },
          child: const Text('Modifier'),
        ),
        AppButton(
          label: 'Fermer',
          size: AppButtonSize.sm,
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body.copyWith(color: AppColors.textSecondary))),
          Text(value, style: AppText.bodyMedium),
        ],
      ),
    );
  }
}

class _ExercisePickerDialog extends ConsumerStatefulWidget {
  const _ExercisePickerDialog();

  @override
  ConsumerState<_ExercisePickerDialog> createState() => _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends ConsumerState<_ExercisePickerDialog> {
  final _search = TextEditingController();
  String? _selected;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseListProvider);
    final query = _search.text.trim();
    final hasExactMatch =
        state.exercises.any((e) => e.name.toLowerCase() == query.toLowerCase());

    return AlertDialog(
      title: const Text('Ajouter un exercice'),
      content: SizedBox(
        width: 400,
        height: 420,
        child: Column(
          children: [
            AppTextField(
              hint: 'Rechercher un exercice…',
              controller: _search,
              trailing: const Icon(LucideIcons.search, size: 20),
              onChanged: (value) {
                setState(() {});
                ref.read(exerciseListProvider.notifier).searchExercises(value);
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: [
                        if (query.isNotEmpty && !hasExactMatch)
                          _PickerTile(
                            title: 'Ajouter « $query »',
                            subtitle: 'Exercice personnalisé',
                            icon: LucideIcons.plus,
                            selected: _selected == query,
                            onTap: () => setState(() => _selected = query),
                          ),
                        for (final exercise in state.exercises)
                          _PickerTile(
                            title: exercise.name,
                            subtitle: exercise.category,
                            icon: LucideIcons.dumbbell,
                            selected: _selected == exercise.name,
                            onTap: () => setState(() => _selected = exercise.name),
                          ),
                        if (state.exercises.isEmpty && query.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Aucun exercice trouvé', style: AppText.caption),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        AppButton(
          label: 'Suivant',
          size: AppButtonSize.sm,
          onPressed: _selected == null ? null : () => Navigator.of(context).pop(_selected),
        ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PickerTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.surface2 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: AppColors.surface2,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                IconTile(icon: icon, size: 36, iconSize: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.bodyMedium),
                      Text(subtitle, style: AppText.caption),
                    ],
                  ),
                ),
                if (selected) const Icon(LucideIcons.circleCheck, size: 20, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseFormDialog extends ConsumerStatefulWidget {
  final String userId;
  final String workoutId;
  final String initialName;

  /// Edited exercise; null when adding a new one.
  final ExerciseModel? exercise;

  const _ExerciseFormDialog({
    required this.userId,
    required this.workoutId,
    required this.initialName,
    this.exercise,
  });

  @override
  ConsumerState<_ExerciseFormDialog> createState() => _ExerciseFormDialogState();
}

class _ExerciseFormDialogState extends ConsumerState<_ExerciseFormDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _weight = TextEditingController(
    text: widget.exercise?.weight != null && widget.exercise!.weight! > 0
        ? _formatNumber(widget.exercise!.weight!)
        : '',
  );
  late final _notes = TextEditingController(text: widget.exercise?.notes ?? '');
  late int _sets = widget.exercise?.setsCount ?? 3;
  late int _reps = widget.exercise?.reps ?? 10;
  late WeightUnit _unit = widget.exercise?.weightUnit ?? WeightUnit.kg;
  late bool _completed = widget.exercise?.isCompleted ?? false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.exercise != null;

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Le nom est requis');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final notifier = ref.read(apiWorkoutProvider(widget.userId).notifier);
    final weight = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final bool ok;
    if (_isEdit) {
      ok = await notifier.updateExercise(
        exerciseId: widget.exercise!.id,
        exerciseName: name,
        sets: _sets,
        reps: _reps,
        weight: weight,
        weightUnit: _unit,
        notes: notes,
        isCompleted: _completed,
      );
    } else {
      ok = await notifier.addExercise(
        workoutId: widget.workoutId,
        exerciseName: name,
        sets: _sets,
        reps: _reps,
        weight: weight,
        weightUnit: _unit,
        notes: notes,
      );
    }

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      showAppSnack(context, _isEdit ? 'Exercice modifié' : 'Exercice ajouté');
    } else {
      setState(() {
        _saving = false;
        _error = 'L\'enregistrement a échoué, réessaie.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Modifier l\'exercice' : widget.initialName),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isEdit) ...[
              AppTextField(label: 'Nom', controller: _name),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: _Counter(
                    label: 'Séries',
                    value: _sets,
                    min: 1,
                    max: 10,
                    onChanged: (v) => setState(() => _sets = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Counter(
                    label: 'Répétitions',
                    value: _reps,
                    min: 1,
                    max: 50,
                    onChanged: (v) => setState(() => _reps = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Poids (facultatif)',
                    hint: '0',
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<WeightUnit>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                    ButtonSegment(value: WeightUnit.lbs, label: Text('lbs')),
                  ],
                  selected: {_unit},
                  onSelectionChanged: (selection) => setState(() => _unit = selection.first),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'Notes (facultatif)', controller: _notes, maxLines: 2),
            if (_isEdit) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _completed,
                onChanged: (value) => setState(() => _completed = value ?? false),
                title: const Text('Exercice terminé', style: AppText.body),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
            if (_error != null) ...[const SizedBox(height: 12), InlineError(_error!)],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        AppButton(
          label: _isEdit ? 'Enregistrer' : 'Ajouter',
          size: AppButtonSize.sm,
          loading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Counter({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.bodyMedium),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Moins',
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: const Icon(LucideIcons.minus, size: 18),
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: AppText.h3.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
              IconButton(
                tooltip: 'Plus',
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: const Icon(LucideIcons.plus, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
