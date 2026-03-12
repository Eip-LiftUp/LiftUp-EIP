import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';
import 'package:app/core/providers/workout_provider.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/core/utils/date_utils.dart';

/// Program Page - Hevy style workout tracking
class ProgramPage extends ConsumerStatefulWidget {
  const ProgramPage({super.key});

  @override
  ConsumerState<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends ConsumerState<ProgramPage> {
  @override
  void initState() {
    super.initState();
    // Load workouts on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.userId != null) {
        ref.read(apiWorkoutProvider(authState.userId!).notifier).loadWorkouts();
      }
    });
  }

  String get _userId {
    final authState = ref.watch(authProvider);
    return authState.userId ?? '';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userId.isEmpty) {
      return MainScaffold(
        currentIndex: 2, // Programme = index 2
        child: const Center(
          child: Text('Non connecté', style: TextStyle(color: AppColors.textPrimary)),
        ),
      );
    }

    final workoutState = ref.watch(apiWorkoutProvider(_userId));

    return MainScaffold(
      currentIndex: 2, // Programme = index 2  (0=Accueil, 1=Analyse, 2=Programme, 3=Profil)
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              border: Border(
                bottom: BorderSide(color: AppColors.navBarBorder),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Programme',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${workoutState.workouts.length} entraînements',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateWorkoutDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Nouveau'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: workoutState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : workoutState.error != null
                    ? _buildErrorView(workoutState.error!)
                    : workoutState.workouts.isEmpty
                        ? _buildEmptyView()
                        : _buildWorkoutList(workoutState.workouts),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            'Erreur',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            error,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingL),
          ElevatedButton(
            onPressed: () {
              ref.read(apiWorkoutProvider(_userId).notifier).loadWorkouts();
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              'Aucun entraînement',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            const Text(
              'Créez votre premier entraînement pour commencer !',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXl),
            ElevatedButton.icon(
              onPressed: () => _showCreateWorkoutDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Créer un entraînement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingXl,
                  vertical: AppConstants.spacingM,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutList(List<WorkoutModel> workouts) {
    // Group workouts by date
    final groupedWorkouts = <String, List<WorkoutModel>>{};
    for (final workout in workouts) {
      final dateKey = AppDateUtils.formatDateKey(workout.workoutDate);
      groupedWorkouts.putIfAbsent(dateKey, () => []).add(workout);
    }

    // Sort dates descending (newest first)
    final sortedDates = groupedWorkouts.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dateWorkouts = groupedWorkouts[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
                vertical: AppConstants.spacingS,
              ),
              child: Text(
                _formatDateHeader(date),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            // Workouts for this date
            ...dateWorkouts.map((workout) => _buildWorkoutCard(workout)),
            const SizedBox(height: AppConstants.spacingM),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    return AppDateUtils.formatDateHeader(date);
  }

  Widget _buildWorkoutCard(WorkoutModel workout) {
    return Card(
      color: AppColors.cardBackground,
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
        side: BorderSide(
          color: workout.isCompleted
              ? AppColors.secondary.withOpacity(0.3)
              : AppColors.navBarBorder,
        ),
      ),
      child: InkWell(
        onTap: () => _showWorkoutDetails(workout),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingS),
                    decoration: BoxDecoration(
                      color: workout.isCompleted
                          ? AppColors.secondary.withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                    ),
                    child: Icon(
                      workout.isCompleted ? Icons.check_circle : Icons.fitness_center,
                      color: workout.isCompleted ? AppColors.secondary : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (workout.durationMinutes != null) ...[
                              const Icon(Icons.timer, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '${workout.durationMinutes} min',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacingM),
                            ],
                            const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              AppDateUtils.formatTime(workout.workoutDate),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                    color: AppColors.cardBackground,
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditWorkoutDialog(workout);
                          break;
                        case 'add_exercise':
                          _showAddExerciseDialog(workout);
                          break;
                        case 'delete':
                          _confirmDeleteWorkout(workout);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Modifier', style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'add_exercise',
                        child: Row(
                          children: [
                            Icon(Icons.add, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Ajouter exercice', style: TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Exercises preview
              if (workout.exercises.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spacingM),
                const Divider(color: AppColors.navBarBorder),
                const SizedBox(height: AppConstants.spacingM),
                ...workout.exercises.take(3).map((exercise) => Padding(
                      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
                      child: Row(
                        children: [
                          Icon(
                            exercise.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                            size: 16,
                            color: exercise.isCompleted
                                ? AppColors.secondary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppConstants.spacingS),
                          Expanded(
                            child: Text(
                              exercise.exerciseName,
                              style: TextStyle(
                                color: exercise.isCompleted
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                fontSize: 14,
                                decoration: exercise.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          Text(
                            '${exercise.sets}×${exercise.reps}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          if (exercise.weight != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${exercise.weight}${exercise.weightUnit == WeightUnit.kg ? 'kg' : 'lbs'}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )),
                if (workout.exercises.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: AppConstants.spacingS),
                    child: Text(
                      '+${workout.exercises.length - 3} autre(s) exercice(s)',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],

              // Notes
              if (workout.notes != null && workout.notes!.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spacingM),
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: AppConstants.spacingS),
                      Expanded(
                        child: Text(
                          workout.notes!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Status badge
              if (workout.isCompleted) ...[
                const SizedBox(height: AppConstants.spacingM),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM,
                    vertical: AppConstants.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: AppColors.secondary),
                      SizedBox(width: 4),
                      Text(
                        'Complété',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkoutDetails(WorkoutModel workout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusL)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _WorkoutDetailsSheet(
          workout: workout,
          scrollController: scrollController,
          onAddExercise: () {
            Navigator.of(context).pop();
            _showAddExerciseDialog(workout);
          },
          onExerciseTap: (exercise) {
            _showExerciseDetails(workout, exercise);
          },
        ),
      ),
    );
  }

  void _showCreateWorkoutDialog() {
    final nameController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    int? durationMinutes;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Nouvel entraînement',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nom de l\'entraînement',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.fitness_center, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.primary,
                            surface: AppColors.cardBackground,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.primary),
                        const SizedBox(width: AppConstants.spacingM),
                        Text(
                          AppDateUtils.formatDate(selectedDate),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                TextField(
                  style: const TextStyle(color: AppColors.textPrimary),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Durée (minutes) - optionnel',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.timer, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    durationMinutes = int.tryParse(value);
                  },
                ),
                const SizedBox(height: AppConstants.spacingM),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes - optionnel',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.note, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  _showErrorSnackBar('Le nom est requis');
                  return;
                }

                final request = CreateWorkoutRequest(
                  name: nameController.text.trim(),
                  workoutDate: selectedDate,
                  durationMinutes: durationMinutes,
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                );

                Navigator.of(context).pop();

                try {
                  final notifier = ref.read(apiWorkoutProvider(_userId).notifier);
                  await notifier.createWorkout(
                    name: request.name,
                    workoutDate: request.workoutDate,
                    durationMinutes: request.durationMinutes,
                    notes: request.notes,
                  );
                  _showSuccessSnackBar('Entraînement créé !');
                } catch (e) {
                  _showErrorSnackBar('Erreur: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditWorkoutDialog(WorkoutModel workout) {
    final nameController = TextEditingController(text: workout.name);
    final notesController = TextEditingController(text: workout.notes ?? '');
    DateTime selectedDate = workout.workoutDate;
    int? durationMinutes = workout.durationMinutes;
    bool isCompleted = workout.isCompleted;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Modifier l\'entraînement',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.fitness_center, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.primary,
                            surface: AppColors.cardBackground,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.primary),
                        const SizedBox(width: AppConstants.spacingM),
                        Text(
                          AppDateUtils.formatDate(selectedDate),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                TextField(
                  style: const TextStyle(color: AppColors.textPrimary),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: durationMinutes?.toString() ?? ''),
                  decoration: InputDecoration(
                    labelText: 'Durée (minutes)',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.timer, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    durationMinutes = int.tryParse(value);
                  },
                ),
                const SizedBox(height: AppConstants.spacingM),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.note, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                CheckboxListTile(
                  value: isCompleted,
                  onChanged: (value) {
                    setDialogState(() => isCompleted = value ?? false);
                  },
                  title: const Text('Entraînement complété', style: TextStyle(color: AppColors.textPrimary)),
                  activeColor: AppColors.secondary,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  _showErrorSnackBar('Le nom est requis');
                  return;
                }

                final request = UpdateWorkoutRequest(
                  name: nameController.text.trim(),
                  workoutDate: selectedDate,
                  durationMinutes: durationMinutes,
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  isCompleted: isCompleted,
                );

                Navigator.of(context).pop();

                try {
                  final notifier = ref.read(apiWorkoutProvider(_userId).notifier);
                  await notifier.updateWorkout(
                    workoutId: workout.id,
                    name: request.name,
                    workoutDate: request.workoutDate,
                    durationMinutes: request.durationMinutes,
                    notes: request.notes,
                    isCompleted: request.isCompleted,
                  );
                  _showSuccessSnackBar('Entraînement modifié !');
                } catch (e) {
                  _showErrorSnackBar('Erreur: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExerciseDialog(WorkoutModel workout) {
    final nameController = TextEditingController();
    final notesController = TextEditingController();
    int sets = 3;
    int reps = 12;
    double? weight;
    WeightUnit weightUnit = WeightUnit.kg;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Ajouter un exercice',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nom de l\'exercice',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.fitness_center, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingL),
                // Sets
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Séries', style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: AppConstants.spacingS),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () => setDialogState(() => sets = (sets - 1).clamp(1, 10)),
                                icon: const Icon(Icons.remove_circle, color: AppColors.primary),
                              ),
                              Text(
                                '$sets',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => setDialogState(() => sets = (sets + 1).clamp(1, 10)),
                                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Reps
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Reps', style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: AppConstants.spacingS),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () => setDialogState(() => reps = (reps - 1).clamp(1, 50)),
                                icon: const Icon(Icons.remove_circle, color: AppColors.primary),
                              ),
                              Text(
                                '$reps',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => setDialogState(() => reps = (reps + 1).clamp(1, 50)),
                                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingL),
                // Weight
                TextField(
                  style: const TextStyle(color: AppColors.textPrimary),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Poids (optionnel)',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.monitor_weight, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    weight = double.tryParse(value);
                  },
                ),
                const SizedBox(height: AppConstants.spacingM),
                // Weight Unit Toggle
                Row(
                  children: [
                    const Text('Unité: ', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(width: AppConstants.spacingM),
                    SegmentedButton<WeightUnit>(
                      segments: const [
                        ButtonSegment(value: WeightUnit.kg, label: Text('KG')),
                        ButtonSegment(value: WeightUnit.lbs, label: Text('LBS')),
                      ],
                      selected: {weightUnit},
                      onSelectionChanged: (Set<WeightUnit> newSelection) {
                        setDialogState(() => weightUnit = newSelection.first);
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.primary;
                            }
                            return AppColors.background;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return AppColors.textSecondary;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingM),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes - optionnel',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.note, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  _showErrorSnackBar('Le nom est requis');
                  return;
                }

                final request = CreateExerciseRequest(
                  exerciseName: nameController.text.trim(),
                  sets: sets,
                  reps: reps,
                  weight: weight,
                  weightUnit: weightUnit,
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                );

                Navigator.of(context).pop();

                try {
                  final notifier = ref.read(apiWorkoutProvider(_userId).notifier);
                  await notifier.addExercise(
                    workoutId: workout.id,
                    exerciseName: request.exerciseName,
                    sets: request.sets,
                    reps: request.reps,
                    weight: request.weight,
                    weightUnit: request.weightUnit,
                    notes: request.notes,
                  );
                  _showSuccessSnackBar('Exercice ajouté !');
                } catch (e) {
                  _showErrorSnackBar('Erreur: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseDetails(WorkoutModel workout, ExerciseModel exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          exercise.exerciseName,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Séries', '${exercise.sets}'),
            _buildDetailRow('Répétitions', '${exercise.reps}'),
            if (exercise.weight != null)
              _buildDetailRow(
                'Poids',
                '${exercise.weight} ${exercise.weightUnit == WeightUnit.kg ? 'kg' : 'lbs'}',
              ),
            if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacingM),
              const Text('Notes:', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                exercise.notes!,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditExerciseDialog(workout, exercise);
            },
            child: const Text('Modifier'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(apiWorkoutProvider(_userId).notifier).deleteExercise(exercise.id);
                _showSuccessSnackBar('Exercice supprimé');
              } catch (e) {
                _showErrorSnackBar('Erreur: $e');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showEditExerciseDialog(WorkoutModel workout, ExerciseModel exercise) {
    final nameController = TextEditingController(text: exercise.exerciseName);
    final notesController = TextEditingController(text: exercise.notes ?? '');
    int sets = exercise.sets;
    int reps = exercise.reps;
    double? weight = exercise.weight;
    WeightUnit weightUnit = exercise.weightUnit;
    bool isCompleted = exercise.isCompleted;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Modifier l\'exercice',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.fitness_center, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingL),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Séries', style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: AppConstants.spacingS),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () => setDialogState(() => sets = (sets - 1).clamp(1, 10)),
                                icon: const Icon(Icons.remove_circle, color: AppColors.primary),
                              ),
                              Text(
                                '$sets',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => setDialogState(() => sets = (sets + 1).clamp(1, 10)),
                                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Reps', style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: AppConstants.spacingS),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () => setDialogState(() => reps = (reps - 1).clamp(1, 50)),
                                icon: const Icon(Icons.remove_circle, color: AppColors.primary),
                              ),
                              Text(
                                '$reps',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => setDialogState(() => reps = (reps + 1).clamp(1, 50)),
                                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingL),
                TextField(
                  style: const TextStyle(color: AppColors.textPrimary),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  controller: TextEditingController(text: weight?.toString() ?? ''),
                  decoration: InputDecoration(
                    labelText: 'Poids',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.monitor_weight, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    weight = double.tryParse(value);
                  },
                ),
                const SizedBox(height: AppConstants.spacingM),
                Row(
                  children: [
                    const Text('Unité: ', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(width: AppConstants.spacingM),
                    SegmentedButton<WeightUnit>(
                      segments: const [
                        ButtonSegment(value: WeightUnit.kg, label: Text('KG')),
                        ButtonSegment(value: WeightUnit.lbs, label: Text('LBS')),
                      ],
                      selected: {weightUnit},
                      onSelectionChanged: (Set<WeightUnit> newSelection) {
                        setDialogState(() => weightUnit = newSelection.first);
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return AppColors.primary;
                            }
                            return AppColors.background;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return AppColors.textSecondary;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingM),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.note, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                CheckboxListTile(
                  value: isCompleted,
                  onChanged: (value) {
                    setDialogState(() => isCompleted = value ?? false);
                  },
                  title: const Text('Exercice complété', style: TextStyle(color: AppColors.textPrimary)),
                  activeColor: AppColors.secondary,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  _showErrorSnackBar('Le nom est requis');
                  return;
                }

                final request = UpdateExerciseRequest(
                  exerciseName: nameController.text.trim(),
                  sets: sets,
                  reps: reps,
                  weight: weight,
                  weightUnit: weightUnit,
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  isCompleted: isCompleted,
                );

                Navigator.of(context).pop();

                try {
                  final notifier = ref.read(apiWorkoutProvider(_userId).notifier);
                  await notifier.updateExercise(
                    exerciseId: exercise.id,
                    exerciseName: request.exerciseName,
                    sets: request.sets,
                    reps: request.reps,
                    weight: request.weight,
                    weightUnit: request.weightUnit,
                    notes: request.notes,
                    isCompleted: request.isCompleted,
                  );
                  _showSuccessSnackBar('Exercice modifié !');
                } catch (e) {
                  _showErrorSnackBar('Erreur: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteWorkout(WorkoutModel workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Supprimer l\'entraînement ?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Cette action est irréversible.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(apiWorkoutProvider(_userId).notifier).deleteWorkout(workout.id);
                _showSuccessSnackBar('Entraînement supprimé');
              } catch (e) {
                _showErrorSnackBar('Erreur: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

/// Workout details bottom sheet
class _WorkoutDetailsSheet extends StatelessWidget {
  final WorkoutModel workout;
  final ScrollController scrollController;
  final VoidCallback onAddExercise;
  final Function(ExerciseModel) onExerciseTap;

  const _WorkoutDetailsSheet({
    required this.workout,
    required this.scrollController,
    required this.onAddExercise,
    required this.onExerciseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                decoration: BoxDecoration(
                  color: workout.isCompleted
                      ? AppColors.secondary.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                ),
                child: Icon(
                  workout.isCompleted ? Icons.check_circle : Icons.fitness_center,
                  color: workout.isCompleted ? AppColors.secondary : AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppDateUtils.formatDateTime(workout.workoutDate),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Stats
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (workout.durationMinutes != null)
                  _buildStatItem(Icons.timer, '${workout.durationMinutes}', 'Minutes'),
                _buildStatItem(Icons.fitness_center, '${workout.exercises.length}', 'Exercices'),
                _buildStatItem(
                  Icons.repeat,
                  '${workout.exercises.fold<int>(0, (sum, e) => sum + e.sets)}',
                  'Séries',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Notes
          if (workout.notes != null && workout.notes!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: AppConstants.spacingM),
                  Expanded(
                    child: Text(
                      workout.notes!,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
          ],

          // Exercises header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Exercices',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: onAddExercise,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),

          // Exercises list
          Expanded(
            child: workout.exercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 48,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        const Text(
                          'Aucun exercice',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    itemCount: workout.exercises.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppConstants.spacingM),
                    itemBuilder: (context, index) {
                      final exercise = workout.exercises[index];
                      return InkWell(
                        onTap: () => onExerciseTap(exercise),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                        child: Container(
                          padding: const EdgeInsets.all(AppConstants.spacingM),
                          decoration: BoxDecoration(
                            color: exercise.isCompleted
                                ? AppColors.secondary.withOpacity(0.1)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                            border: Border.all(
                              color: exercise.isCompleted
                                  ? AppColors.secondary
                                  : AppColors.navBarBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                exercise.isCompleted
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: exercise.isCompleted
                                    ? AppColors.secondary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppConstants.spacingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise.exerciseName,
                                      style: TextStyle(
                                        color: exercise.isCompleted
                                            ? AppColors.textSecondary
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        decoration: exercise.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${exercise.sets} séries × ${exercise.reps} reps${exercise.weight != null ? ' • ${exercise.weight} ${exercise.weightUnit == WeightUnit.kg ? 'kg' : 'lbs'}' : ''}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
