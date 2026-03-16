/// Weight unit enum
enum WeightUnit {
  kg,
  lbs;

  String get displayName => this == WeightUnit.kg ? 'kg' : 'lbs';
}

/// Individual set model (for Hevy-style tracking)
class SetModel {
  final int setNumber;
  final int reps;
  final double? weight;
  final bool isCompleted;

  SetModel({
    required this.setNumber,
    required this.reps,
    this.weight,
    this.isCompleted = false,
  });

  factory SetModel.fromJson(Map<String, dynamic> json) {
    return SetModel(
      setNumber: json['setNumber'] as int,
      reps: json['reps'] as int,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
      'isCompleted': isCompleted,
    };
  }

  SetModel copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    bool? isCompleted,
  }) {
    return SetModel(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Exercise model (Hevy-style with individual sets)
class ExerciseModel {
  final String id;
  final String workoutId;
  final String exerciseName;
  final List<SetModel> sets; // Changed from int to List<SetModel>
  final WeightUnit weightUnit;
  final int orderIndex;
  final String? notes;
  final DateTime createdAt;

  // Computed properties for backward compatibility
  int get setsCount => sets.length;
  bool get isCompleted => sets.isNotEmpty && sets.every((s) => s.isCompleted);
  
  // Helper getters for display (uses first set or average)
  int get reps => sets.isNotEmpty ? sets.first.reps : 0;
  double? get weight => sets.isNotEmpty ? sets.first.weight : null;
  
  // Get summary string (e.g., "3 sets x 10 reps • 100 kg")
  String getSummary() {
    if (sets.isEmpty) return '0 séries';
    
    final allSame = sets.every((s) => 
      s.reps == sets.first.reps && s.weight == sets.first.weight
    );
    
    if (allSame) {
      final firstSet = sets.first;
      final weightStr = firstSet.weight != null 
        ? ' • ${firstSet.weight} ${weightUnit.displayName}' 
        : '';
      return '${sets.length} sets × ${firstSet.reps} reps$weightStr';
    } else {
      // Show range if sets differ
      return '${sets.length} sets (variable)';
    }
  }

  ExerciseModel({
    required this.id,
    required this.workoutId,
    required this.exerciseName,
    required this.sets,
    this.weightUnit = WeightUnit.kg,
    required this.orderIndex,
    this.notes,
    required this.createdAt,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    // Handle different formats for sets data
    List<SetModel> parsedSets;
    
    // Priority 1: Check for setsData (new format from backend)
    if (json['setsData'] != null && json['setsData'] is List) {
      parsedSets = (json['setsData'] as List)
          .map((s) => SetModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    // Priority 2: Check for sets as List (old format)
    else if (json['sets'] is List) {
      parsedSets = (json['sets'] as List)
          .map((s) => SetModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    // Priority 3: Backward compatibility with integer sets
    else {
      final int setsCount = json['sets'] as int? ?? 3;
      final int reps = json['reps'] as int? ?? 10;
      final double? weight = json['weight'] != null ? (json['weight'] as num).toDouble() : null;
      parsedSets = List.generate(
        setsCount,
        (index) => SetModel(
          setNumber: index + 1,
          reps: reps,
          weight: weight,
          isCompleted: false,
        ),
      );
    }

    return ExerciseModel(
      id: json['id'] as String,
      workoutId: json['workoutId'] as String,
      exerciseName: json['exerciseName'] as String,
      sets: parsedSets,
      weightUnit: json['weightUnit'] == 'lbs' ? WeightUnit.lbs : WeightUnit.kg,
      orderIndex: json['orderIndex'] as int,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutId': workoutId,
      'exerciseName': exerciseName,
      'sets': sets.map((s) => s.toJson()).toList(),
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
    List<SetModel>? sets,
    WeightUnit? weightUnit,
    int? orderIndex,
    String? notes,
    DateTime? createdAt,
  }) {
    return ExerciseModel(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      weightUnit: weightUnit ?? this.weightUnit,
      orderIndex: orderIndex ?? this.orderIndex,
      notes: notes ?? this.notes,
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
  final List<SetModel>? setsData;

  UpdateExerciseRequest({
    this.exerciseName,
    this.sets,
    this.reps,
    this.weight,
    this.weightUnit,
    this.orderIndex,
    this.notes,
    this.isCompleted,
    this.setsData,
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
      if (setsData != null) 'setsData': setsData!.map((s) => s.toJson()).toList(),
    };
  }
}
