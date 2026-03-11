/// Weight unit enum
enum WeightUnit {
  kg,
  lbs;

  String get displayName => this == WeightUnit.kg ? 'kg' : 'lbs';
}

/// Exercise model
class ExerciseModel {
  final String id;
  final String workoutId;
  final String exerciseName;
  final int sets;
  final int reps;
  final double? weight;
  final WeightUnit weightUnit;
  final int orderIndex;
  final String? notes;
  final bool isCompleted;
  final DateTime createdAt;

  ExerciseModel({
    required this.id,
    required this.workoutId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    this.weight,
    this.weightUnit = WeightUnit.kg,
    required this.orderIndex,
    this.notes,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String,
      workoutId: json['workoutId'] as String,
      exerciseName: json['exerciseName'] as String,
      sets: json['sets'] as int,
      reps: json['reps'] as int,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      weightUnit: json['weightUnit'] == 'lbs' ? WeightUnit.lbs : WeightUnit.kg,
      orderIndex: json['orderIndex'] as int,
      notes: json['notes'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutId': workoutId,
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'weightUnit': weightUnit.name,
      'orderIndex': orderIndex,
      'notes': notes,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ExerciseModel copyWith({
    String? id,
    String? workoutId,
    String? exerciseName,
    int? sets,
    int? reps,
    double? weight,
    WeightUnit? weightUnit,
    int? orderIndex,
    String? notes,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      orderIndex: orderIndex ?? this.orderIndex,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Workout model
class WorkoutModel {
  final String id;
  final String userId;
  final String name;
  final DateTime workoutDate;
  final int? durationMinutes;
  final String? notes;
  final bool isCompleted;
  final List<ExerciseModel> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.workoutDate,
    this.durationMinutes,
    this.notes,
    this.isCompleted = false,
    this.exercises = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    return WorkoutModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      workoutDate: DateTime.parse(json['workoutDate'] as String),
      durationMinutes: json['durationMinutes'] as int?,
      notes: json['notes'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'workoutDate': workoutDate.toIso8601String().split('T')[0],
      'durationMinutes': durationMinutes,
      'notes': notes,
      'isCompleted': isCompleted,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  WorkoutModel copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? workoutDate,
    int? durationMinutes,
    String? notes,
    bool? isCompleted,
    List<ExerciseModel>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      workoutDate: workoutDate ?? this.workoutDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Create workout request DTO
class CreateWorkoutRequest {
  final String name;
  final DateTime? workoutDate;
  final int? durationMinutes;
  final String? notes;

  CreateWorkoutRequest({
    required this.name,
    this.workoutDate,
    this.durationMinutes,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (workoutDate != null) 'workoutDate': workoutDate!.toIso8601String().split('T')[0],
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (notes != null) 'notes': notes,
    };
  }
}

/// Update workout request DTO
class UpdateWorkoutRequest {
  final String? name;
  final DateTime? workoutDate;
  final int? durationMinutes;
  final String? notes;
  final bool? isCompleted;

  UpdateWorkoutRequest({
    this.name,
    this.workoutDate,
    this.durationMinutes,
    this.notes,
    this.isCompleted,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (workoutDate != null) 'workoutDate': workoutDate!.toIso8601String().split('T')[0],
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      if (notes != null) 'notes': notes,
      if (isCompleted != null) 'isCompleted': isCompleted,
    };
  }
}

/// Create exercise request DTO
class CreateExerciseRequest {
  final String exerciseName;
  final int sets;
  final int reps;
  final double? weight;
  final WeightUnit? weightUnit;
  final int? orderIndex;
  final String? notes;

  CreateExerciseRequest({
    required this.exerciseName,
    required this.sets,
    required this.reps,
    this.weight,
    this.weightUnit,
    this.orderIndex,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      if (weight != null) 'weight': weight,
      if (weightUnit != null) 'weightUnit': weightUnit!.name,
      if (orderIndex != null) 'orderIndex': orderIndex,
      if (notes != null) 'notes': notes,
    };
  }
}

/// Update exercise request DTO
class UpdateExerciseRequest {
  final String? exerciseName;
  final int? sets;
  final int? reps;
  final double? weight;
  final WeightUnit? weightUnit;
  final int? orderIndex;
  final String? notes;
  final bool? isCompleted;

  UpdateExerciseRequest({
    this.exerciseName,
    this.sets,
    this.reps,
    this.weight,
    this.weightUnit,
    this.orderIndex,
    this.notes,
    this.isCompleted,
  });

  Map<String, dynamic> toJson() {
    return {
      if (exerciseName != null) 'exerciseName': exerciseName,
      if (sets != null) 'sets': sets,
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
      if (weightUnit != null) 'weightUnit': weightUnit!.name,
      if (orderIndex != null) 'orderIndex': orderIndex,
      if (notes != null) 'notes': notes,
      if (isCompleted != null) 'isCompleted': isCompleted,
    };
  }
}
