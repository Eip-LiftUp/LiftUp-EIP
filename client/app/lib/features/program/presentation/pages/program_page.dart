import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';
import 'package:app/core/providers/workout_provider.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/config/providers.dart';
import 'package:intl/intl.dart';

/// Program Page - Hevy style workout tracking
/// 
/// Displays workout history and allows creating new workouts with exercises.
/// Features: create workouts, add exercises, track weight in kg/lbs
class ProgramPage extends ConsumerStatefulWidget {
  const ProgramPage({super.key});

  @override
  ConsumerState<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends ConsumerState<ProgramPage> {
  int _selectedDayIndex = DateTime.now().weekday - 1;

  DateTime get _currentWeekStart {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekOffset = ref.read(workoutStateProvider).selectedWeekOffset;
    return weekStart.add(Duration(days: 7 * weekOffset));
  }

  String get _weekRangeText {
    final start = _currentWeekStart;
    final end = start.add(const Duration(days: 6));
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]}';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadiusM)),
      ),
    );
  }

  /// Start a workout
  void _startWorkout(int workoutIndex) {
    ref.read(workoutStateProvider.notifier).startWorkout(_selectedDayIndex, workoutIndex);
    _showSuccessSnackBar('Entraînement commencé !');
    _showActiveWorkoutSheet(workoutIndex);
  }

  /// Show active workout sheet (workout in progress)
  void _showActiveWorkoutSheet(int workoutIndex) {
    final workoutState = ref.read(workoutStateProvider);
    final workout = workoutState.weeklySchedule[_selectedDayIndex].workouts[workoutIndex];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusL)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _ActiveWorkoutSheet(
          workout: workout,
          dayIndex: _selectedDayIndex,
          workoutIndex: workoutIndex,
          scrollController: scrollController,
          onComplete: () {
            Navigator.of(context).pop();
            ref.read(workoutStateProvider.notifier).completeWorkout(_selectedDayIndex, workoutIndex);
            ref.read(appStateProvider.notifier).incrementWorkoutStats();
            _showSuccessSnackBar('Entraînement terminé ! 💪');
          },
        ),
      ),
    );
  }

  /// Show workout details
  void _showWorkoutDetails(int workoutIndex) {
    final workoutState = ref.read(workoutStateProvider);
    final workout = workoutState.weeklySchedule[_selectedDayIndex].workouts[workoutIndex];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusL)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _WorkoutDetailsSheet(
          workout: workout,
          scrollController: scrollController,
        ),
      ),
    );
  }

  /// Show add workout dialog
  void _showAddWorkoutDialog() {
    final titleController = TextEditingController();
    final timeController = TextEditingController(text: '08:00');
    final durationController = TextEditingController(text: '60');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Ajouter un entraînement', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Titre', Icons.fitness_center),
              ),
              const SizedBox(height: AppConstants.spacingM),
              TextField(
                controller: timeController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Heure (HH:MM)', Icons.access_time),
              ),
              const SizedBox(height: AppConstants.spacingM),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Durée (minutes)', Icons.timer),
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
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                final newWorkout = Workout(
                  id: 'w_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleController.text,
                  time: timeController.text,
                  duration: int.tryParse(durationController.text) ?? 60,
                  exercises: [],
                );
                ref.read(workoutStateProvider.notifier).addWorkout(_selectedDayIndex, newWorkout);
                Navigator.of(context).pop();
                _showSuccessSnackBar('Entraînement ajouté');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  /// Show add exercise dialog
  void _showAddExerciseDialog(int workoutIndex) {
    final availableExercises = ref.read(availableExercisesProvider);
    String? selectedExercise;
    int sets = 3;
    int reps = 12;
    double weight = 20;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Ajouter un exercice', style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exercice', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: AppConstants.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                    border: Border.all(color: AppColors.navBarBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedExercise,
                      hint: const Text('Choisir un exercice', style: TextStyle(color: AppColors.textSecondary)),
                      dropdownColor: AppColors.cardBackground,
                      style: const TextStyle(color: AppColors.textPrimary),
                      items: availableExercises.map((e) => DropdownMenuItem(
                        value: e['name'] as String,
                        child: Text(e['name'] as String),
                      )).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedExercise = value;
                          final exercise = availableExercises.firstWhere((e) => e['name'] == value);
                          sets = exercise['defaultSets'] as int;
                          reps = exercise['defaultReps'] as int;
                        });
                      },
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
                          const Text('Séries', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          const SizedBox(height: AppConstants.spacingS),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => setDialogState(() => sets = (sets - 1).clamp(1, 10)),
                                icon: const Icon(Icons.remove_circle, color: AppColors.primary),
                              ),
                              Text('$sets', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
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
                          const Text('Répétitions', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          const SizedBox(height: AppConstants.spacingS),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => setDialogState(() => reps = (reps - 1).clamp(1, 50)),
                                icon: const Icon(Icons.remove_circle, color: AppColors.primary),
                              ),
                              Text('$reps', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
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
                const SizedBox(height: AppConstants.spacingM),
                const Text('Poids (kg)', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                Slider(
                  value: weight,
                  min: 0,
                  max: 200,
                  divisions: 40,
                  activeColor: AppColors.primary,
                  label: '${weight.toInt()} kg',
                  onChanged: (value) => setDialogState(() => weight = value),
                ),
                Center(
                  child: Text('${weight.toInt()} kg', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
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
              onPressed: selectedExercise != null ? () {
                final newExercise = Exercise(
                  id: 'e_${DateTime.now().millisecondsSinceEpoch}',
                  name: selectedExercise!,
                  sets: sets,
                  reps: reps,
                  weight: weight > 0 ? weight : null,
                );
                ref.read(workoutStateProvider.notifier).addExercise(_selectedDayIndex, workoutIndex, newExercise);
                Navigator.of(context).pop();
                _showSuccessSnackBar('Exercice ajouté: $selectedExercise');
              } : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show calendar dialog
  void _showCalendarDialog() {
    final weekOffset = ref.read(workoutStateProvider).selectedWeekOffset;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Calendrier', style: TextStyle(color: AppColors.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.arrow_back, color: AppColors.primary),
                title: const Text('Semaine dernière', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  ref.read(workoutStateProvider.notifier).setWeekOffset(weekOffset - 1);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.today, color: AppColors.secondary),
                title: const Text('Cette semaine', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  ref.read(workoutStateProvider.notifier).setWeekOffset(0);
                  setState(() => _selectedDayIndex = DateTime.now().weekday - 1);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_forward, color: AppColors.primary),
                title: const Text('Semaine prochaine', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  ref.read(workoutStateProvider.notifier).setWeekOffset(weekOffset + 1);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        borderSide: const BorderSide(color: AppColors.navBarBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutStateProvider);

    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Week selector
          _buildWeekSelector(workoutState),

          // Day selector
          _buildDaySelector(workoutState),

          // Content
          Expanded(
            child: _buildDayContent(workoutState),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Programme',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            onPressed: _showCalendarDialog,
            icon: const Icon(
              Icons.calendar_today,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector(WorkoutState workoutState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              ref.read(workoutStateProvider.notifier).setWeekOffset(workoutState.selectedWeekOffset - 1);
            },
            icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          ),
          Column(
            children: [
              Text(
                workoutState.selectedWeekOffset == 0
                    ? 'Cette semaine'
                    : workoutState.selectedWeekOffset == 1
                        ? 'Semaine prochaine'
                        : workoutState.selectedWeekOffset == -1
                            ? 'Semaine dernière'
                            : 'Semaine',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                _weekRangeText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              ref.read(workoutStateProvider.notifier).setWeekOffset(workoutState.selectedWeekOffset + 1);
            },
            icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(WorkoutState workoutState) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final day = workoutState.weeklySchedule[index];
          final isSelected = index == _selectedDayIndex;
          final hasWorkout = day.workouts.isNotEmpty;
          final dayDate = _currentWeekStart.add(Duration(days: index));
          final isToday = workoutState.selectedWeekOffset == 0 && index == DateTime.now().weekday - 1;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingS,
                vertical: AppConstants.spacingM,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    day.shortName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dayDate.day}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: hasWorkout
                          ? (isSelected ? Colors.white : AppColors.secondary)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayContent(WorkoutState workoutState) {
    final selectedDay = workoutState.weeklySchedule[_selectedDayIndex];

    if (selectedDay.workouts.isEmpty) {
      return _buildRestDay();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      itemCount: selectedDay.workouts.length,
      itemBuilder: (context, index) {
        return _buildWorkoutCard(selectedDay.workouts[index], index);
      },
    );
  }

  Widget _buildRestDay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.self_improvement,
                size: 64,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              'Jour de repos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Profitez de cette journée pour récupérer.\nLe repos est essentiel pour progresser !',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXl),
            OutlinedButton.icon(
              onPressed: _showAddWorkoutDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un entraînement'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                  vertical: AppConstants.spacingM,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
        border: Border.all(
          color: workout.isCompleted
              ? AppColors.secondary.withOpacity(0.5)
              : workout.isInProgress
                  ? AppColors.accent.withOpacity(0.5)
                  : AppColors.navBarBorder,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: workout.isCompleted
                  ? AppColors.secondary.withOpacity(0.1)
                  : workout.isInProgress
                      ? AppColors.accent.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.borderRadiusL),
                topRight: Radius.circular(AppConstants.borderRadiusL),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacingS),
                  decoration: BoxDecoration(
                    color: workout.isCompleted
                        ? AppColors.secondary.withOpacity(0.2)
                        : workout.isInProgress
                            ? AppColors.accent.withOpacity(0.2)
                            : AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                  ),
                  child: Icon(
                    workout.isCompleted
                        ? Icons.check_circle
                        : workout.isInProgress
                            ? Icons.play_circle
                            : Icons.fitness_center,
                    color: workout.isCompleted
                        ? AppColors.secondary
                        : workout.isInProgress
                            ? AppColors.accent
                            : AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${workout.time} • ${workout.duration} min',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (workout.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingS,
                      vertical: AppConstants.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                    ),
                    child: const Text(
                      'Terminé',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (workout.isInProgress)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingS,
                      vertical: AppConstants.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                    ),
                    child: const Text(
                      'En cours',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // Menu button
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  color: AppColors.cardBackground,
                  onSelected: (value) {
                    switch (value) {
                      case 'add_exercise':
                        _showAddExerciseDialog(index);
                        break;
                      case 'delete':
                        _confirmDeleteWorkout(index);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
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
          ),

          // Exercises list
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exercices (${workout.exercises.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddExerciseDialog(index),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Ajouter'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingS),
                if (workout.exercises.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                    ),
                    child: const Center(
                      child: Text(
                        'Aucun exercice. Appuyez sur + pour en ajouter.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: AppConstants.spacingS,
                    runSpacing: AppConstants.spacingS,
                    children: workout.exercises.map((exercise) {
                      return GestureDetector(
                        onTap: () => _showExerciseDetails(exercise, index, workout.exercises.indexOf(exercise)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacingM,
                            vertical: AppConstants.spacingS,
                          ),
                          decoration: BoxDecoration(
                            color: exercise.isCompleted
                                ? AppColors.secondary.withOpacity(0.2)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                            border: exercise.isCompleted
                                ? Border.all(color: AppColors.secondary)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (exercise.isCompleted)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(Icons.check_circle, color: AppColors.secondary, size: 14),
                                ),
                              Text(
                                exercise.name,
                                style: TextStyle(
                                  color: exercise.isCompleted ? AppColors.secondary : AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          // Action button
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacingM,
              0,
              AppConstants.spacingM,
              AppConstants.spacingM,
            ),
            child: SizedBox(
              width: double.infinity,
              child: workout.isCompleted
                  ? OutlinedButton.icon(
                      onPressed: () => _showWorkoutDetails(index),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Voir les détails'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.navBarBorder),
                      ),
                    )
                  : workout.isInProgress
                      ? ElevatedButton.icon(
                          onPressed: () => _showActiveWorkoutSheet(index),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Continuer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _startWorkout(index),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Commencer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseDetails(Exercise exercise, int workoutIndex, int exerciseIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(exercise.name, style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildExerciseDetailRow('Séries', '${exercise.sets}'),
            _buildExerciseDetailRow('Répétitions', '${exercise.reps}'),
            if (exercise.weight != null) _buildExerciseDetailRow('Poids', '${exercise.weight!.toInt()} kg'),
            const SizedBox(height: AppConstants.spacingM),
            if (exercise.isCompleted)
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.secondary),
                    SizedBox(width: 8),
                    Text('Complété', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(workoutStateProvider.notifier).removeExercise(_selectedDayIndex, workoutIndex, exerciseIndex);
              _showSuccessSnackBar('Exercice supprimé');
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

  Widget _buildExerciseDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _confirmDeleteWorkout(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Supprimer l\'entraînement ?', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Cette action est irréversible.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(workoutStateProvider.notifier).removeWorkout(_selectedDayIndex, index);
              _showSuccessSnackBar('Entraînement supprimé');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

/// Active workout sheet for in-progress workouts
class _ActiveWorkoutSheet extends ConsumerStatefulWidget {
  final Workout workout;
  final int dayIndex;
  final int workoutIndex;
  final ScrollController scrollController;
  final VoidCallback onComplete;

  const _ActiveWorkoutSheet({
    required this.workout,
    required this.dayIndex,
    required this.workoutIndex,
    required this.scrollController,
    required this.onComplete,
  });

  @override
  ConsumerState<_ActiveWorkoutSheet> createState() => _ActiveWorkoutSheetState();
}

class _ActiveWorkoutSheetState extends ConsumerState<_ActiveWorkoutSheet> {
  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutStateProvider);
    final workout = workoutState.weeklySchedule[widget.dayIndex].workouts[widget.workoutIndex];

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                ),
                child: const Icon(Icons.play_circle, color: AppColors.accent),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.title,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'En cours • ${workout.exercises.where((e) => e.isCompleted).length}/${workout.exercises.length} exercices',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Progress bar
          LinearProgressIndicator(
            value: workout.exercises.isEmpty ? 0 : workout.exercises.where((e) => e.isCompleted).length / workout.exercises.length,
            backgroundColor: AppColors.navBarBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Exercise list
          Expanded(
            child: ListView.separated(
              controller: widget.scrollController,
              itemCount: workout.exercises.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppConstants.spacingM),
              itemBuilder: (context, index) {
                final exercise = workout.exercises[index];
                return _buildExerciseItem(exercise, index);
              },
            ),
          ),

          // Complete button
          const SizedBox(height: AppConstants.spacingL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onComplete,
              icon: const Icon(Icons.check_circle),
              label: const Text('Terminer l\'entraînement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(Exercise exercise, int index) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: exercise.isCompleted ? AppColors.secondary.withOpacity(0.1) : AppColors.background,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        border: Border.all(
          color: exercise.isCompleted ? AppColors.secondary : AppColors.navBarBorder,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: exercise.isCompleted,
            activeColor: AppColors.secondary,
            onChanged: (value) {
              ref.read(workoutStateProvider.notifier).toggleExerciseComplete(
                widget.dayIndex,
                widget.workoutIndex,
                index,
              );
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: TextStyle(
                    color: exercise.isCompleted ? AppColors.secondary : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    decoration: exercise.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  '${exercise.sets} séries × ${exercise.reps} reps${exercise.weight != null ? ' • ${exercise.weight!.toInt()} kg' : ''}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Workout details sheet
class _WorkoutDetailsSheet extends StatelessWidget {
  final Workout workout;
  final ScrollController scrollController;

  const _WorkoutDetailsSheet({
    required this.workout,
    required this.scrollController,
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

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingS),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                ),
                child: const Icon(Icons.check_circle, color: AppColors.secondary),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.title,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Terminé ✓',
                      style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w500),
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
                _buildStatItem(Icons.timer, '${workout.duration} min', 'Durée'),
                _buildStatItem(Icons.fitness_center, '${workout.exercises.length}', 'Exercices'),
                _buildStatItem(Icons.repeat, '${workout.exercises.fold<int>(0, (sum, e) => sum + e.sets)}', 'Séries'),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),

          // Exercises
          const Text(
            'Exercices',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              itemCount: workout.exercises.length,
              separatorBuilder: (_, __) => const Divider(color: AppColors.navBarBorder),
              itemBuilder: (context, index) {
                final exercise = workout.exercises[index];
                return ListTile(
                  leading: const Icon(Icons.check_circle, color: AppColors.secondary),
                  title: Text(exercise.name, style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    '${exercise.sets} × ${exercise.reps}${exercise.weight != null ? ' • ${exercise.weight!.toInt()} kg' : ''}',
                    style: const TextStyle(color: AppColors.textSecondary),
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
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
