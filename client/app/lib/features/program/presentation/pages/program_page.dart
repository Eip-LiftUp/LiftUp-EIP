import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';
import 'package:app/core/providers/workout_provider.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/exercise_provider.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/core/utils/workout_timer.dart';
import 'package:intl/intl.dart';

/// Program Page - Hevy style workout tracking with automatic timer
class ProgramPage extends ConsumerStatefulWidget {
  const ProgramPage({super.key});

  @override
  ConsumerState<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends ConsumerState<ProgramPage> {
  final WorkoutTimer _workoutTimer = WorkoutTimer();
  WorkoutModel? _activeWorkout;

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

  @override
  void dispose() {
    _workoutTimer.dispose();
    super.dispose();
  }

  String get _userId {
    final authState = ref.watch(authProvider);
    return authState.userId ?? '';
  }

  // Date formatting utilities
  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "AUJOURD'HUI";
    } else if (date.year == now.year && 
               date.month == now.month && 
               date.day == now.day - 1) {
      return "HIER";
    }
    return DateFormat('EEEE dd MMM', 'fr_FR').format(date).toUpperCase();
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.secondary,
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
        currentIndex: 2,
        child: const Center(
          child: Text('Non connecté', style: TextStyle(color: AppColors.textPrimary)),
        ),
      );
    }

    final workoutState = ref.watch(apiWorkoutProvider(_userId));

    return MainScaffold(
      currentIndex: 2,
      child: Column(
        children: [
          // Active workout banner
          if (_activeWorkout != null) _buildActiveWorkoutBanner(),

          // Header
          _buildHeader(workoutState.workouts.length),

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

  Widget _buildActiveWorkoutBanner() {
    return AnimatedBuilder(
      animation: _workoutTimer,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.8),
                const Color(0xFF7C3AED).withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingS),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _activeWorkout!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'En cours • ${_workoutTimer.getFormattedTime()}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showActiveWorkoutSheet(_activeWorkout!),
                  icon: const Icon(Icons.open_in_full, color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int workoutCount) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.navBarBorder),
        ),
      ),
      child: SafeArea(
        bottom: false,
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
                      '$workoutCount entraînements',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _showCreateWorkoutDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Nouveau'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _showCreateWorkoutDialog,
                icon: const Icon(Icons.add),
                label: const Text('Créer un entraînement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingXl,
                    vertical: AppConstants.spacingM,
                  ),
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
      final dateKey = workout.workoutDate.toIso8601String().split('T')[0];
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
                              _formatTime(workout.workoutDate),
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
                        case 'start':
                          _startWorkout(workout);
                          break;
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
                      if (!workout.isCompleted)
                        const PopupMenuItem(
                          value: 'start',
                          child: Row(
                            children: [
                              Icon(Icons.play_arrow, color: AppColors.secondary),
                              SizedBox(width: 8),
                              Text('Démarrer', style: TextStyle(color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
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
                            '${exercise.setsCount}×${exercise.reps}',
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

  void _startWorkout(WorkoutModel workout) {
    setState(() {
      _activeWorkout = workout;
      _workoutTimer.start(workout.id);
    });
    _showSnackBar('Entraînement démarré ! Timer actif.');
    _showActiveWorkoutSheet(workout);
  }

  Future<void> _completeWorkout(WorkoutModel workout) async {
    final durationMinutes = _workoutTimer.getDurationMinutes();
    _workoutTimer.stop();

    try {
      final notifier = ref.read(apiWorkoutProvider(_userId).notifier);
      await notifier.updateWorkout(
        workoutId: workout.id,
        durationMinutes: durationMinutes,
        isCompleted: true,
      );

      setState(() {
        _activeWorkout = null;
      });

      _showSnackBar('Entraînement complété ! Durée: $durationMinutes min');
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    }
  }

  void _showActiveWorkoutSheet(WorkoutModel workout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => _ActiveWorkoutSheet(
        workout: workout,
        workoutTimer: _workoutTimer,
        onComplete: () {
          Navigator.of(context).pop();
          _completeWorkout(workout);
        },
        onAddExercise: () {
          Navigator.of(context).pop();
          _showAddExerciseDialog(workout);
        },
        onExerciseTap: (exercise) {
          _showExerciseDetailsInSheet(workout, exercise);
        },
        onToggleComplete: (exercise) async {
          await _toggleExerciseComplete(exercise);
        },
      ),
    );
  }

  Future<void> _toggleExerciseComplete(ExerciseModel exercise) async {
    try {
      final notifier = ref.read(apiWorkoutProvider(_userId).notifier);
      await notifier.updateExercise(
        exerciseId: exercise.id,
        isCompleted: !exercise.isCompleted,
      );
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    }
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
          onStartWorkout: () {
            Navigator.of(context).pop();
            _startWorkout(workout);
          },
        ),
      ),
    );
  }

  void _showCreateWorkoutDialog() {
    final nameController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

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
                          _formatDate(selectedDate),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
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
                  _showSnackBar('Le nom est requis', isError: true);
                  return;
                }

                Navigator.of(context).pop();

                try {
                  final notifier = ref.read(apiWorkoutProvider(_userId).notifier);
                  await notifier.createWorkout(
                    name: nameController.text.trim(),
                    workoutDate: selectedDate,
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  );
                  _showSnackBar('Entraînement créé !');
                } catch (e) {
                  _showSnackBar('Erreur: $e', isError: true);
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
                          _formatDate(selectedDate),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
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
                  _showSnackBar('Le nom est requis', isError: true);
                  return;
                }

                Navigator.of(context).pop();

                try {
                  final notifier = ref.read(apiWorkoutProvider(_userId).notifier);
                  await notifier.updateWorkout(
                    workoutId: workout.id,
                    name: nameController.text.trim(),
                    workoutDate: selectedDate,
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    isCompleted: isCompleted,
                  );
                  _showSnackBar('Entraînement modifié !');
                } catch (e) {
                  _showSnackBar('Erreur: $e', isError: true);
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
    final searchController = TextEditingController();
    String? selectedExerciseName;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final exerciseState = ref.watch(exerciseListProvider);

          return AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text(
              'Ajouter un exercice',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: searchController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un exercice...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      ref.read(exerciseListProvider.notifier).searchExercises(value);
                    },
                  ),
                  const SizedBox(height: AppConstants.spacingM),

                  // Exercise list
                  Expanded(
                    child: exerciseState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : exerciseState.exercises.isEmpty
                            ? const Center(
                                child: Text(
                                  'Aucun exercice trouvé',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              )
                            : ListView.builder(
                                itemCount: exerciseState.exercises.length,
                                itemBuilder: (context, index) {
                                  final exercise = exerciseState.exercises[index];
                                  final isSelected = selectedExerciseName == exercise.name;

                                  return Card(
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.2)
                                        : AppColors.background,
                                    child: ListTile(
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.fitness_center,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        exercise.name,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        exercise.category,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(Icons.check_circle, color: AppColors.secondary)
                                          : null,
                                      onTap: () {
                                        setDialogState(() {
                                          selectedExerciseName = exercise.name;
                                        });
                                      },
                                    ),
                                  );
                                },
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
                onPressed: selectedExerciseName == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        _showExerciseDetailsDialog(workout, selectedExerciseName!);
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Suivant'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExerciseDetailsDialog(WorkoutModel workout, String exerciseName) {
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
          title: Text(
            exerciseName,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sets and Reps
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

                // Notes
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
                Navigator.of(context).pop();

                try {
                  final notifier = ref.read(apiWorkoutProvider(_userId).notifier);
                  await notifier.addExercise(
                    workoutId: workout.id,
                    exerciseName: exerciseName,
                    sets: sets,
                    reps: reps,
                    weight: weight,
                    weightUnit: weightUnit,
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  );
                  _showSnackBar('Exercice ajouté !');
                } catch (e) {
                  _showSnackBar('Erreur: $e', isError: true);
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
            _buildDetailRow('Séries', '${exercise.setsCount}'),
            _buildDetailRow('Répétitions', '${exercise.reps}'),
            if (exercise.weight != null)
              _buildDetailRow(
                'Poids',
                '${exercise.weight} ${exercise.weightUnit.displayName}',
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
                _showSnackBar('Exercice supprimé');
              } catch (e) {
                _showSnackBar('Erreur: $e', isError: true);
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

  void _showExerciseDetailsInSheet(WorkoutModel workout, ExerciseModel exercise) {
    // Make a mutable copy of sets for editing
    List<SetModel> editableSets = List.from(exercise.sets);
    if (editableSets.isEmpty) {
      editableSets = List.generate(3, (i) => SetModel(setNumber: i + 1, reps: 10));
    }

    final notesController = TextEditingController(text: exercise.notes ?? '');
    int restTimerSeconds = 120; // 2 minutes default
    // ignore: unused_local_variable
    bool isWarmupMode = false; // Toggle for warmup sets (future feature)
    
    // Create controllers for each set (persisted between rebuilds)
    final Map<int, TextEditingController> weightControllers = {};
    final Map<int, TextEditingController> repsControllers = {};
    for (int i = 0; i < editableSets.length; i++) {
      weightControllers[i] = TextEditingController(
        text: editableSets[i].weight != null ? editableSets[i].weight.toString() : '',
      );
      repsControllers[i] = TextEditingController(
        text: editableSets[i].reps.toString(),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header with icon + exercise name + menu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    // Exercise icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.exerciseName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${editableSets.length} séries',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
                      color: AppColors.cardBackground,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.swap_horiz, size: 20, color: AppColors.primary),
                              SizedBox(width: 12),
                              Text('Remplacer l\'exercice', style: TextStyle(color: AppColors.textPrimary)),
                            ],
                          ),
                          onTap: () {},
                        ),
                        PopupMenuItem(
                          child: const Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Supprimer', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                          onTap: () async {
                            Navigator.of(context).pop();
                            try {
                              await ref.read(apiWorkoutProvider(_userId).notifier).deleteExercise(exercise.id);
                              _showSnackBar('Exercice supprimé');
                            } catch (e) {
                              _showSnackBar('Erreur: $e', isError: true);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Notes section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  controller: notesController,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ajouter une note...',
                    hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                    border: InputBorder.none,
                    icon: Icon(Icons.notes, size: 18, color: AppColors.textSecondary.withOpacity(0.5)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: 1,
                ),
              ),

              // Rest timer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: InkWell(
                  onTap: () {
                    // TODO: Implement rest timer dialog
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.navBarBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Repos : ${restTimerSeconds ~/ 60}m ${restTimerSeconds % 60}s',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(color: AppColors.navBarBorder, height: 1),
              const SizedBox(height: 16),

              // Table header (Hevy style with PREVIOUS column)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 45,
                      child: Text(
                        'SET',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'PREVIOUS',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        exercise.weightUnit.displayName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'REPS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 45),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Sets list (scrollable)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: editableSets.length,
                  itemBuilder: (context, index) {
                    final set = editableSets[index];
                    // ignore: dead_code
                    final isWarmup = index == 0 && isWarmupMode; // First set can be warmup

                    // Ensure controllers exist for this index
                    if (!weightControllers.containsKey(index)) {
                      weightControllers[index] = TextEditingController(
                        text: set.weight != null ? set.weight.toString() : '',
                      );
                    }
                    if (!repsControllers.containsKey(index)) {
                      repsControllers[index] = TextEditingController(
                        text: set.reps.toString(),
                      );
                    }

                    // Mock previous data (replace with actual data from previous workout)
                    final previousWeight = set.weight != null ? (set.weight! * 0.95).toStringAsFixed(1) : null;
                    final previousReps = set.reps > 0 ? (set.reps - 1).toString() : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: set.isCompleted
                            ? AppColors.secondary.withOpacity(0.12)
                            : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: set.isCompleted
                              ? AppColors.secondary
                              : AppColors.navBarBorder,
                          width: set.isCompleted ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Set number or Warmup badge
                          SizedBox(
                            width: 45,
                            child: isWarmup
                                // ignore: dead_code
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFA500).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFFA500).withOpacity(0.3)),
                                    ),
                                    child: const Text(
                                      'W',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFFFFA500),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : Text(
                                    '${set.setNumber}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: set.isCompleted 
                                          ? AppColors.secondary
                                          : AppColors.textPrimary,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),

                          // Previous performance column
                          Expanded(
                            flex: 2,
                            child: Text(
                              previousWeight != null && previousReps != null
                                  ? '$previousWeight ${exercise.weightUnit.displayName} × $previousReps'
                                  : '-',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary.withOpacity(0.6),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          // Weight input
                          Expanded(
                            child: TextField(
                              controller: weightControllers[index],
                              textAlign: TextAlign.center,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(
                                color: set.isCompleted 
                                    ? AppColors.secondary
                                    : AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '-',
                                hintStyle: TextStyle(color: AppColors.textSecondary),
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              onChanged: (value) {
                                final weight = double.tryParse(value);
                                setSheetState(() {
                                  editableSets[index] = set.copyWith(weight: weight);
                                });
                              },
                            ),
                          ),

                          // Reps input
                          Expanded(
                            child: TextField(
                              controller: repsControllers[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: set.isCompleted 
                                    ? AppColors.secondary
                                    : AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                                hintStyle: TextStyle(color: AppColors.textSecondary),
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              onChanged: (value) {
                                final reps = int.tryParse(value) ?? 0;
                                setSheetState(() {
                                  editableSets[index] = set.copyWith(reps: reps);
                                });
                              },
                            ),
                          ),

                          // Checkmark button
                          SizedBox(
                            width: 45,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                setSheetState(() {
                                  editableSets[index] = set.copyWith(isCompleted: !set.isCompleted);
                                });
                              },
                              icon: Icon(
                                set.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                                color: set.isCompleted ? AppColors.secondary : AppColors.textSecondary,
                                size: 26,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Add set button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: OutlinedButton.icon(
                  onPressed: () {
                    setSheetState(() {
                      final newSet = SetModel(
                        setNumber: editableSets.length + 1,
                        reps: editableSets.isNotEmpty ? editableSets.last.reps : 10,
                        weight: editableSets.isNotEmpty ? editableSets.last.weight : null,
                      );
                      editableSets.add(newSet);
                      
                      // Create controllers for the new set
                      final newIndex = editableSets.length - 1;
                      weightControllers[newIndex] = TextEditingController(
                        text: newSet.weight != null ? newSet.weight.toString() : '',
                      );
                      repsControllers[newIndex] = TextEditingController(
                        text: newSet.reps.toString(),
                      );
                    });
                  },
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: const Text(
                    'Ajouter une série',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              // Save button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border(top: BorderSide(color: AppColors.navBarBorder)),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        // Save individual sets to backend
                        try {
                          final notifier = ref.read(apiWorkoutProvider(_userId).notifier);
                          await notifier.updateExercise(
                            exerciseId: exercise.id,
                            sets: editableSets.length,
                            reps: editableSets.isNotEmpty ? editableSets.first.reps : 10,
                            weight: editableSets.isNotEmpty ? editableSets.first.weight : null,
                            setsData: editableSets,
                          );
                          _showSnackBar('Exercice mis à jour !');
                        } catch (e) {
                          _showSnackBar('Erreur: $e', isError: true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Terminer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      // Dispose all controllers when sheet closes
      weightControllers.values.forEach((c) => c.dispose());
      repsControllers.values.forEach((c) => c.dispose());
      notesController.dispose();
    });
  }

  void _showEditExerciseDialog(WorkoutModel workout, ExerciseModel exercise) {
    final nameController = TextEditingController(text: exercise.exerciseName);
    final notesController = TextEditingController(text: exercise.notes ?? '');
    int sets = exercise.setsCount;
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
                  _showSnackBar('Le nom est requis', isError: true);
                  return;
                }

                Navigator.of(context).pop();

                try {
                  final notifier = ref.read(apiWorkoutProvider(_userId).notifier);
                  await notifier.updateExercise(
                    exerciseId: exercise.id,
                    exerciseName: nameController.text.trim(),
                    sets: sets,
                    reps: reps,
                    weight: weight,
                    weightUnit: weightUnit,
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    isCompleted: isCompleted,
                  );
                  _showSnackBar('Exercice modifié !');
                } catch (e) {
                  _showSnackBar('Erreur: $e', isError: true);
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
                _showSnackBar('Entraînement supprimé');
              } catch (e) {
                _showSnackBar('Erreur: $e', isError: true);
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

/// Active Workout Sheet - Full screen workout session
class _ActiveWorkoutSheet extends ConsumerWidget {
  final WorkoutModel workout;
  final WorkoutTimer workoutTimer;
  final VoidCallback onComplete;
  final VoidCallback onAddExercise;
  final Function(ExerciseModel) onExerciseTap;
  final Function(ExerciseModel) onToggleComplete;

  const _ActiveWorkoutSheet({
    required this.workout,
    required this.workoutTimer,
    required this.onComplete,
    required this.onAddExercise,
    required this.onExerciseTap,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedBuilder(
      animation: workoutTimer,
      builder: (context, child) {
        return Container(
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusL)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Timer display
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
                ),
                margin: const EdgeInsets.all(AppConstants.spacingL),
                child: Column(
                  children: [
                    const Text(
                      'TEMPS ÉCOULÉ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      workoutTimer.getFormattedTime(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      workout.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Exercises header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exercices (${workout.exercises.length})',
                      style: const TextStyle(
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
              ),

              // Exercises list
              Expanded(
                child: workout.exercises.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 64,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: AppConstants.spacingL),
                            const Text(
                              'Aucun exercice',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingS),
                            TextButton.icon(
                              onPressed: onAddExercise,
                              icon: const Icon(Icons.add),
                              label: const Text('Ajouter un exercice'),
                              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppConstants.spacingL),
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
                                    : AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                                border: Border.all(
                                  color: exercise.isCompleted
                                      ? AppColors.secondary
                                      : AppColors.navBarBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => onToggleComplete(exercise),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: exercise.isCompleted
                                              ? AppColors.secondary
                                              : AppColors.textSecondary,
                                          width: 2,
                                        ),
                                      ),
                                      child: exercise.isCompleted
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: AppColors.secondary,
                                            )
                                          : const SizedBox(width: 16, height: 16),
                                    ),
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
                                            fontSize: 16,
                                            decoration: exercise.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${exercise.setsCount} séries × ${exercise.reps} reps${exercise.weight != null ? ' • ${exercise.weight} ${exercise.weightUnit.displayName}' : ''}',    
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14,
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

              // Complete workout button
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingL),
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border(
                    top: BorderSide(color: AppColors.navBarBorder),
                  ),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.secondary, Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: onComplete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingL),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                          ),
                        ),
                        child: const Text(
                          'TERMINER L\'ENTRAÎNEMENT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Workout details bottom sheet
class _WorkoutDetailsSheet extends StatelessWidget {
  final WorkoutModel workout;
  final ScrollController scrollController;
  final VoidCallback onAddExercise;
  final Function(ExerciseModel) onExerciseTap;
  final VoidCallback onStartWorkout;

  const _WorkoutDetailsSheet({
    required this.workout,
    required this.scrollController,
    required this.onAddExercise,
    required this.onExerciseTap,
    required this.onStartWorkout,
  });

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy à HH:mm').format(dateTime);
  }

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
                      _formatDateTime(workout.workoutDate),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Start workout button
          if (!workout.isCompleted) ...[
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: onStartWorkout,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('DÉMARRER L\'ENTRAÎNEMENT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
          ],

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
                  '${workout.exercises.fold<int>(0, (sum, e) => sum + e.setsCount)}',
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
                                      '${exercise.setsCount} séries × ${exercise.reps} reps${exercise.weight != null ? ' • ${exercise.weight} ${exercise.weightUnit.displayName}' : ''}',
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
