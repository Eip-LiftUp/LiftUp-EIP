import 'package:flutter/material.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';

/// Program/Schedule Page
/// 
/// Displays the user's weekly training schedule with
/// workout sessions and progress tracking.
class ProgramPage extends StatefulWidget {
  const ProgramPage({super.key});

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  int _selectedDayIndex = DateTime.now().weekday - 1;
  int _selectedWeekOffset = 0;

  /// Mock workout data
  final List<_WorkoutDay> _weeklySchedule = [
    _WorkoutDay(
      dayName: 'Lundi',
      shortName: 'Lun',
      workouts: [
        _Workout(
          title: 'Push - Pectoraux & Épaules',
          time: '08:00',
          duration: 60,
          exercises: ['Développé couché', 'Développé incliné', 'Élévations latérales', 'Dips'],
          isCompleted: true,
        ),
      ],
    ),
    _WorkoutDay(
      dayName: 'Mardi',
      shortName: 'Mar',
      workouts: [
        _Workout(
          title: 'Pull - Dos & Biceps',
          time: '08:00',
          duration: 55,
          exercises: ['Tractions', 'Rowing barre', 'Curl biceps', 'Face pulls'],
          isCompleted: true,
        ),
      ],
    ),
    _WorkoutDay(
      dayName: 'Mercredi',
      shortName: 'Mer',
      workouts: [], // Rest day
    ),
    _WorkoutDay(
      dayName: 'Jeudi',
      shortName: 'Jeu',
      workouts: [
        _Workout(
          title: 'Legs - Jambes',
          time: '08:00',
          duration: 70,
          exercises: ['Squat', 'Presse à cuisses', 'Leg curl', 'Mollets debout'],
          isCompleted: false,
        ),
      ],
    ),
    _WorkoutDay(
      dayName: 'Vendredi',
      shortName: 'Ven',
      workouts: [
        _Workout(
          title: 'Upper Body - Haut du corps',
          time: '08:00',
          duration: 50,
          exercises: ['Développé militaire', 'Rowing haltères', 'Curl marteau', 'Extensions triceps'],
          isCompleted: false,
        ),
      ],
    ),
    _WorkoutDay(
      dayName: 'Samedi',
      shortName: 'Sam',
      workouts: [
        _Workout(
          title: 'Full Body - Corps complet',
          time: '10:00',
          duration: 75,
          exercises: ['Deadlift', 'Bench press', 'Pull-ups', 'Squats', 'Planche'],
          isCompleted: false,
        ),
      ],
    ),
    _WorkoutDay(
      dayName: 'Dimanche',
      shortName: 'Dim',
      workouts: [], // Rest day
    ),
  ];

  DateTime get _currentWeekStart {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return weekStart.add(Duration(days: 7 * _selectedWeekOffset));
  }

  String get _weekRangeText {
    final start = _currentWeekStart;
    final end = start.add(const Duration(days: 6));
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Week selector
          _buildWeekSelector(),

          // Day selector
          _buildDaySelector(),

          // Content
          Expanded(
            child: _buildDayContent(),
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
            onPressed: () {
              // TODO: Open calendar view
            },
            icon: const Icon(
              Icons.calendar_today,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedWeekOffset--;
              });
            },
            icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
          ),
          Column(
            children: [
              Text(
                _selectedWeekOffset == 0
                    ? 'Cette semaine'
                    : _selectedWeekOffset == 1
                        ? 'Semaine prochaine'
                        : _selectedWeekOffset == -1
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
              setState(() {
                _selectedWeekOffset++;
              });
            },
            icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final day = _weeklySchedule[index];
          final isSelected = index == _selectedDayIndex;
          final hasWorkout = day.workouts.isNotEmpty;
          final dayDate = _currentWeekStart.add(Duration(days: index));
          final isToday = _selectedWeekOffset == 0 && index == DateTime.now().weekday - 1;

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

  Widget _buildDayContent() {
    final selectedDay = _weeklySchedule[_selectedDayIndex];

    if (selectedDay.workouts.isEmpty) {
      return _buildRestDay();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      itemCount: selectedDay.workouts.length,
      itemBuilder: (context, index) {
        return _buildWorkoutCard(selectedDay.workouts[index]);
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
              onPressed: () {
                // TODO: Add workout
              },
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

  Widget _buildWorkoutCard(_Workout workout) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
        border: Border.all(
          color: workout.isCompleted
              ? AppColors.secondary.withOpacity(0.5)
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
                        : AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                  ),
                  child: Icon(
                    workout.isCompleted ? Icons.check_circle : Icons.fitness_center,
                    color: workout.isCompleted ? AppColors.secondary : AppColors.primary,
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
                Text(
                  'Exercices',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                Wrap(
                  spacing: AppConstants.spacingS,
                  runSpacing: AppConstants.spacingS,
                  children: workout.exercises.map((exercise) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingM,
                        vertical: AppConstants.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                      ),
                      child: Text(
                        exercise,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
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
                      onPressed: () {
                        // TODO: View workout details
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Voir les détails'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.navBarBorder),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Start workout
                      },
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
}

/// Data class for a workout day
class _WorkoutDay {
  final String dayName;
  final String shortName;
  final List<_Workout> workouts;

  _WorkoutDay({
    required this.dayName,
    required this.shortName,
    required this.workouts,
  });
}

/// Data class for a workout session
class _Workout {
  final String title;
  final String time;
  final int duration;
  final List<String> exercises;
  final bool isCompleted;

  _Workout({
    required this.title,
    required this.time,
    required this.duration,
    required this.exercises,
    this.isCompleted = false,
  });
}
