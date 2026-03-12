import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/workout_api_service.dart';
import 'package:app/core/models/workout.dart' as api_models;
import 'package:app/core/config/api_config.dart';

// ==================== API SERVICES ====================

/// Workout API service provider
final workoutApiServiceProvider = Provider<WorkoutApiService>((ref) {
  return WorkoutApiService(baseUrl: ApiConfig.baseUrl);
});

// ==================== USER PROFILE ====================

/// User profile data model
class UserProfile {
  final String name;
  final String email;
  final String? phone;
  final String level;
  final DateTime memberSince;
  final int totalWorkouts;
  final int totalHours;
  final int currentStreak;
  final int longestStreak;
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool workoutReminders;

  const UserProfile({
    required this.name,
    required this.email,
    this.phone,
    this.level = 'Débutant',
    required this.memberSince,
    this.totalWorkouts = 0,
    this.totalHours = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.notificationsEnabled = true,
    this.emailNotifications = true,
    this.workoutReminders = true,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? level,
    DateTime? memberSince,
    int? totalWorkouts,
    int? totalHours,
    int? currentStreak,
    int? longestStreak,
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? workoutReminders,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      level: level ?? this.level,
      memberSince: memberSince ?? this.memberSince,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalHours: totalHours ?? this.totalHours,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      workoutReminders: workoutReminders ?? this.workoutReminders,
    );
  }
}

// ==================== WORKOUT/EXERCISE ====================

/// Exercise model
class Exercise {
  final String id;
  final String name;
  final int sets;
  final int reps;
  final double? weight;
  final bool isCompleted;

  const Exercise({
    required this.id,
    required this.name,
    this.sets = 3,
    this.reps = 12,
    this.weight,
    this.isCompleted = false,
  });

  Exercise copyWith({
    String? id,
    String? name,
    int? sets,
    int? reps,
    double? weight,
    bool? isCompleted,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Workout model
class Workout {
  final String id;
  final String title;
  final String time;
  final int duration;
  final List<Exercise> exercises;
  final bool isCompleted;
  final bool isInProgress;

  const Workout({
    required this.id,
    required this.title,
    this.time = '08:00',
    this.duration = 60,
    this.exercises = const [],
    this.isCompleted = false,
    this.isInProgress = false,
  });

  Workout copyWith({
    String? id,
    String? title,
    String? time,
    int? duration,
    List<Exercise>? exercises,
    bool? isCompleted,
    bool? isInProgress,
  }) {
    return Workout(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      duration: duration ?? this.duration,
      exercises: exercises ?? this.exercises,
      isCompleted: isCompleted ?? this.isCompleted,
      isInProgress: isInProgress ?? this.isInProgress,
    );
  }
}

/// Workout day model
class WorkoutDay {
  final String dayName;
  final String shortName;
  final List<Workout> workouts;

  const WorkoutDay({
    required this.dayName,
    required this.shortName,
    this.workouts = const [],
  });

  WorkoutDay copyWith({
    String? dayName,
    String? shortName,
    List<Workout>? workouts,
  }) {
    return WorkoutDay(
      dayName: dayName ?? this.dayName,
      shortName: shortName ?? this.shortName,
      workouts: workouts ?? this.workouts,
    );
  }
}

// ==================== APP STATE ====================

class AppState {
  final bool isDarkMode;
  final String? userToken;
  final bool isAuthenticated;
  final UserProfile? userProfile;

  AppState({
    this.isDarkMode = false,
    this.userToken,
    this.isAuthenticated = false,
    this.userProfile,
  });

  // Convenience getters for backward compatibility
  String? get userName => userProfile?.name;
  String? get userEmail => userProfile?.email;

  AppState copyWith({
    bool? isDarkMode,
    String? userToken,
    bool? isAuthenticated,
    UserProfile? userProfile,
  }) {
    return AppState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      userToken: userToken ?? this.userToken,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userProfile: userProfile ?? this.userProfile,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState());

  void toggleDarkMode() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
  }

  void setUserToken(String token) {
    state = state.copyWith(userToken: token);
  }

  void setIsAuthenticated(bool value) {
    state = state.copyWith(isAuthenticated: value);
  }

  void setUserInfo({String? name, String? email}) {
    final currentProfile = state.userProfile;
    state = state.copyWith(
      userProfile: currentProfile?.copyWith(name: name, email: email) ??
          UserProfile(
            name: name ?? 'Utilisateur',
            email: email ?? 'user@example.com',
            memberSince: DateTime.now(),
          ),
    );
  }

  void setUserProfile(UserProfile profile) {
    state = state.copyWith(userProfile: profile);
  }

  void updateUserProfile({
    String? name,
    String? email,
    String? phone,
    String? level,
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? workoutReminders,
  }) {
    if (state.userProfile != null) {
      state = state.copyWith(
        userProfile: state.userProfile!.copyWith(
          name: name,
          email: email,
          phone: phone,
          level: level,
          notificationsEnabled: notificationsEnabled,
          emailNotifications: emailNotifications,
          workoutReminders: workoutReminders,
        ),
      );
    }
  }

  void incrementWorkoutStats() {
    if (state.userProfile != null) {
      final newStreak = state.userProfile!.currentStreak + 1;
      state = state.copyWith(
        userProfile: state.userProfile!.copyWith(
          totalWorkouts: state.userProfile!.totalWorkouts + 1,
          totalHours: state.userProfile!.totalHours + 1,
          currentStreak: newStreak,
          longestStreak: newStreak > state.userProfile!.longestStreak
              ? newStreak
              : state.userProfile!.longestStreak,
        ),
      );
    }
  }

  void logout() {
    state = AppState(isDarkMode: state.isDarkMode);
  }

  /// Login with mock data
  void loginWithMockData({String? name, String? email}) {
    state = state.copyWith(
      isAuthenticated: true,
      userToken: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      userProfile: UserProfile(
        name: name ?? 'Jean Dupont',
        email: email ?? 'jean.dupont@email.com',
        phone: '+33 6 12 34 56 78',
        level: 'Intermédiaire',
        memberSince: DateTime(2025, 6, 15),
        totalWorkouts: 47,
        totalHours: 62,
        currentStreak: 5,
        longestStreak: 12,
        notificationsEnabled: true,
        emailNotifications: true,
        workoutReminders: true,
      ),
    );
  }
}

// Example AppState Provider
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>(
  (ref) => AppStateNotifier(),
);

// ==================== WORKOUT STATE ====================

class WorkoutState {
  final List<WorkoutDay> weeklySchedule;
  final int selectedWeekOffset;

  const WorkoutState({
    this.weeklySchedule = const [],
    this.selectedWeekOffset = 0,
  });

  WorkoutState copyWith({
    List<WorkoutDay>? weeklySchedule,
    int? selectedWeekOffset,
  }) {
    return WorkoutState(
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      selectedWeekOffset: selectedWeekOffset ?? this.selectedWeekOffset,
    );
  }
}

class WorkoutStateNotifier extends StateNotifier<WorkoutState> {
  WorkoutStateNotifier() : super(WorkoutState(weeklySchedule: _defaultSchedule()));

  static List<WorkoutDay> _defaultSchedule() {
    return [
      WorkoutDay(
        dayName: 'Lundi',
        shortName: 'Lun',
        workouts: [
          Workout(
            id: 'w1',
            title: 'Push - Pectoraux & Épaules',
            time: '08:00',
            duration: 60,
            exercises: [
              Exercise(id: 'e1', name: 'Développé couché', sets: 4, reps: 10, weight: 60),
              Exercise(id: 'e2', name: 'Développé incliné', sets: 3, reps: 12, weight: 50),
              Exercise(id: 'e3', name: 'Élévations latérales', sets: 3, reps: 15, weight: 10),
              Exercise(id: 'e4', name: 'Dips', sets: 3, reps: 12),
            ],
            isCompleted: true,
          ),
        ],
      ),
      WorkoutDay(
        dayName: 'Mardi',
        shortName: 'Mar',
        workouts: [
          Workout(
            id: 'w2',
            title: 'Pull - Dos & Biceps',
            time: '08:00',
            duration: 55,
            exercises: [
              Exercise(id: 'e5', name: 'Tractions', sets: 4, reps: 8),
              Exercise(id: 'e6', name: 'Rowing barre', sets: 4, reps: 10, weight: 70),
              Exercise(id: 'e7', name: 'Curl biceps', sets: 3, reps: 12, weight: 15),
              Exercise(id: 'e8', name: 'Face pulls', sets: 3, reps: 15, weight: 20),
            ],
            isCompleted: true,
          ),
        ],
      ),
      const WorkoutDay(
        dayName: 'Mercredi',
        shortName: 'Mer',
        workouts: [], // Rest day
      ),
      WorkoutDay(
        dayName: 'Jeudi',
        shortName: 'Jeu',
        workouts: [
          Workout(
            id: 'w3',
            title: 'Legs - Jambes',
            time: '08:00',
            duration: 70,
            exercises: [
              Exercise(id: 'e9', name: 'Squat', sets: 4, reps: 10, weight: 80),
              Exercise(id: 'e10', name: 'Presse à cuisses', sets: 3, reps: 12, weight: 120),
              Exercise(id: 'e11', name: 'Leg curl', sets: 3, reps: 12, weight: 40),
              Exercise(id: 'e12', name: 'Mollets debout', sets: 4, reps: 15, weight: 60),
            ],
            isCompleted: false,
          ),
        ],
      ),
      WorkoutDay(
        dayName: 'Vendredi',
        shortName: 'Ven',
        workouts: [
          Workout(
            id: 'w4',
            title: 'Upper Body - Haut du corps',
            time: '08:00',
            duration: 50,
            exercises: [
              Exercise(id: 'e13', name: 'Développé militaire', sets: 4, reps: 10, weight: 40),
              Exercise(id: 'e14', name: 'Rowing haltères', sets: 3, reps: 12, weight: 25),
              Exercise(id: 'e15', name: 'Curl marteau', sets: 3, reps: 12, weight: 12),
              Exercise(id: 'e16', name: 'Extensions triceps', sets: 3, reps: 12, weight: 20),
            ],
            isCompleted: false,
          ),
        ],
      ),
      WorkoutDay(
        dayName: 'Samedi',
        shortName: 'Sam',
        workouts: [
          Workout(
            id: 'w5',
            title: 'Full Body - Corps complet',
            time: '10:00',
            duration: 75,
            exercises: [
              Exercise(id: 'e17', name: 'Deadlift', sets: 4, reps: 8, weight: 100),
              Exercise(id: 'e18', name: 'Bench press', sets: 3, reps: 10, weight: 60),
              Exercise(id: 'e19', name: 'Pull-ups', sets: 3, reps: 10),
              Exercise(id: 'e20', name: 'Squats', sets: 3, reps: 12, weight: 70),
              Exercise(id: 'e21', name: 'Planche', sets: 3, reps: 60),
            ],
            isCompleted: false,
          ),
        ],
      ),
      const WorkoutDay(
        dayName: 'Dimanche',
        shortName: 'Dim',
        workouts: [], // Rest day
      ),
    ];
  }

  void setWeekOffset(int offset) {
    state = state.copyWith(selectedWeekOffset: offset);
  }

  void startWorkout(int dayIndex, int workoutIndex) {
    final updatedSchedule = List<WorkoutDay>.from(state.weeklySchedule);
    final day = updatedSchedule[dayIndex];
    final updatedWorkouts = List<Workout>.from(day.workouts);
    updatedWorkouts[workoutIndex] = updatedWorkouts[workoutIndex].copyWith(
      isInProgress: true,
    );
    updatedSchedule[dayIndex] = day.copyWith(workouts: updatedWorkouts);
    state = state.copyWith(weeklySchedule: updatedSchedule);
  }

  void completeWorkout(int dayIndex, int workoutIndex) {
    final updatedSchedule = List<WorkoutDay>.from(state.weeklySchedule);
    final day = updatedSchedule[dayIndex];
    final updatedWorkouts = List<Workout>.from(day.workouts);
    updatedWorkouts[workoutIndex] = updatedWorkouts[workoutIndex].copyWith(
      isCompleted: true,
      isInProgress: false,
    );
    updatedSchedule[dayIndex] = day.copyWith(workouts: updatedWorkouts);
    state = state.copyWith(weeklySchedule: updatedSchedule);
  }

  void addWorkout(int dayIndex, Workout workout) {
    final updatedSchedule = List<WorkoutDay>.from(state.weeklySchedule);
    final day = updatedSchedule[dayIndex];
    final updatedWorkouts = List<Workout>.from(day.workouts)..add(workout);
    updatedSchedule[dayIndex] = day.copyWith(workouts: updatedWorkouts);
    state = state.copyWith(weeklySchedule: updatedSchedule);
  }

  void removeWorkout(int dayIndex, int workoutIndex) {
    final updatedSchedule = List<WorkoutDay>.from(state.weeklySchedule);
    final day = updatedSchedule[dayIndex];
    final updatedWorkouts = List<Workout>.from(day.workouts)..removeAt(workoutIndex);
    updatedSchedule[dayIndex] = day.copyWith(workouts: updatedWorkouts);
    state = state.copyWith(weeklySchedule: updatedSchedule);
  }

  void addExercise(int dayIndex, int workoutIndex, Exercise exercise) {
    final updatedSchedule = List<WorkoutDay>.from(state.weeklySchedule);
    final day = updatedSchedule[dayIndex];
    final updatedWorkouts = List<Workout>.from(day.workouts);
    final workout = updatedWorkouts[workoutIndex];
    final updatedExercises = List<Exercise>.from(workout.exercises)..add(exercise);
    updatedWorkouts[workoutIndex] = workout.copyWith(exercises: updatedExercises);
    updatedSchedule[dayIndex] = day.copyWith(workouts: updatedWorkouts);
    state = state.copyWith(weeklySchedule: updatedSchedule);
  }

  void removeExercise(int dayIndex, int workoutIndex, int exerciseIndex) {
    final updatedSchedule = List<WorkoutDay>.from(state.weeklySchedule);
    final day = updatedSchedule[dayIndex];
    final updatedWorkouts = List<Workout>.from(day.workouts);
    final workout = updatedWorkouts[workoutIndex];
    final updatedExercises = List<Exercise>.from(workout.exercises)..removeAt(exerciseIndex);
    updatedWorkouts[workoutIndex] = workout.copyWith(exercises: updatedExercises);
    updatedSchedule[dayIndex] = day.copyWith(workouts: updatedWorkouts);
    state = state.copyWith(weeklySchedule: updatedSchedule);
  }

  void toggleExerciseComplete(int dayIndex, int workoutIndex, int exerciseIndex) {
    final updatedSchedule = List<WorkoutDay>.from(state.weeklySchedule);
    final day = updatedSchedule[dayIndex];
    final updatedWorkouts = List<Workout>.from(day.workouts);
    final workout = updatedWorkouts[workoutIndex];
    final updatedExercises = List<Exercise>.from(workout.exercises);
    updatedExercises[exerciseIndex] = updatedExercises[exerciseIndex].copyWith(
      isCompleted: !updatedExercises[exerciseIndex].isCompleted,
    );
    updatedWorkouts[workoutIndex] = workout.copyWith(exercises: updatedExercises);
    updatedSchedule[dayIndex] = day.copyWith(workouts: updatedWorkouts);
    state = state.copyWith(weeklySchedule: updatedSchedule);
  }

  void updateExercise(int dayIndex, int workoutIndex, int exerciseIndex, Exercise exercise) {
    final updatedSchedule = List<WorkoutDay>.from(state.weeklySchedule);
    final day = updatedSchedule[dayIndex];
    final updatedWorkouts = List<Workout>.from(day.workouts);
    final workout = updatedWorkouts[workoutIndex];
    final updatedExercises = List<Exercise>.from(workout.exercises);
    updatedExercises[exerciseIndex] = exercise;
    updatedWorkouts[workoutIndex] = workout.copyWith(exercises: updatedExercises);
    updatedSchedule[dayIndex] = day.copyWith(workouts: updatedWorkouts);
    state = state.copyWith(weeklySchedule: updatedSchedule);
  }
}

final workoutStateProvider = StateNotifierProvider<WorkoutStateNotifier, WorkoutState>(
  (ref) => WorkoutStateNotifier(),
);

// ==================== AVAILABLE EXERCISES ====================

/// List of available exercises for adding to workouts
final availableExercisesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {'name': 'Développé couché', 'category': 'Pectoraux', 'defaultSets': 4, 'defaultReps': 10},
    {'name': 'Développé incliné', 'category': 'Pectoraux', 'defaultSets': 3, 'defaultReps': 12},
    {'name': 'Développé décliné', 'category': 'Pectoraux', 'defaultSets': 3, 'defaultReps': 12},
    {'name': 'Écarté haltères', 'category': 'Pectoraux', 'defaultSets': 3, 'defaultReps': 15},
    {'name': 'Dips', 'category': 'Pectoraux', 'defaultSets': 3, 'defaultReps': 12},
    {'name': 'Tractions', 'category': 'Dos', 'defaultSets': 4, 'defaultReps': 8},
    {'name': 'Rowing barre', 'category': 'Dos', 'defaultSets': 4, 'defaultReps': 10},
    {'name': 'Rowing haltères', 'category': 'Dos', 'defaultSets': 3, 'defaultReps': 12},
    {'name': 'Tirage vertical', 'category': 'Dos', 'defaultSets': 3, 'defaultReps': 12},
    {'name': 'Face pulls', 'category': 'Dos', 'defaultSets': 3, 'defaultReps': 15},
    {'name': 'Squat', 'category': 'Jambes', 'defaultSets': 4, 'defaultReps': 10},
    {'name': 'Presse à cuisses', 'category': 'Jambes', 'defaultSets': 3, 'defaultReps': 12},
    {'name': 'Leg curl', 'category': 'Jambes', 'defaultSets': 3, 'defaultReps': 12},
    {'name': 'Leg extension', 'category': 'Jambes', 'defaultSets': 3, 'defaultReps': 12},
    {'name': 'Mollets debout', 'category': 'Jambes', 'defaultSets': 4, 'defaultReps': 15},
    {'name': 'Deadlift', 'category': 'Jambes', 'defaultSets': 4, 'defaultReps': 8},
    {'name': 'Développé militaire', 'category': 'Épaules', 'defaultSets': 4, 'defaultReps': 10},
    {'name': 'Élévations latérales', 'category': 'Épaules', 'defaultSets': 3, 'defaultReps': 15},
    {'name': 'Élévations frontales', 'category': 'Épaules', 'defaultSets': 3, 'defaultReps': 12},
    {'name': 'Oiseau', 'category': 'Épaules', 'defaultSets': 3, 'defaultReps': 15},
    {'name': 'Curl biceps', 'category': 'Bras', 'defaultSets': 3, 'defaultReps': 12},
    {'name': 'Curl marteau', 'category': 'Bras', 'defaultSets': 3, 'defaultReps': 12},
    {'name': 'Extensions triceps', 'category': 'Bras', 'defaultSets': 3, 'defaultReps': 12},
    {'name': 'Triceps poulie', 'category': 'Bras', 'defaultSets': 3, 'defaultReps': 15},
    {'name': 'Crunch', 'category': 'Abdos', 'defaultSets': 3, 'defaultReps': 20},
    {'name': 'Planche', 'category': 'Abdos', 'defaultSets': 3, 'defaultReps': 60},
    {'name': 'Relevé de jambes', 'category': 'Abdos', 'defaultSets': 3, 'defaultReps': 15},
  ];
});
