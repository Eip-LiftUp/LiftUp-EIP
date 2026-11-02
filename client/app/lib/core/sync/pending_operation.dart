/// A change made on the device that the server has not acknowledged yet.
enum OperationType {
  createWorkout,
  updateWorkout,
  deleteWorkout,
  createExercise,
  updateExercise,
  deleteExercise;

  bool get isCreate => this == createWorkout || this == createExercise;
  bool get isDelete => this == deleteWorkout || this == deleteExercise;
  bool get onExercise => this == createExercise || this == updateExercise || this == deleteExercise;
}

/// Ids given to workouts and exercises created on the device, until the
/// server returns their real id.
const localIdPrefix = 'local-';

bool isLocalId(String id) => id.startsWith(localIdPrefix);

class PendingOperation {
  /// Unique id of the operation itself.
  final String id;
  final OperationType type;

  /// The workout, or the parent workout of an exercise operation.
  final String workoutId;
  final String? exerciseId;

  /// Request body: the whole entity for a create, only the changed fields
  /// for an update (the backend keeps the fields it does not receive).
  final Map<String, dynamic> fields;

  final DateTime createdAt;

  /// `updatedAt` of the server version the edit was made on, to detect that
  /// another device changed the workout in the meantime.
  final DateTime? baseUpdatedAt;

  /// Times the request was sent without a usable answer.
  final int attempts;

  /// Why the server refused it; such an operation is no longer sent until the
  /// user retries it.
  final String? rejection;

  const PendingOperation({
    required this.id,
    required this.type,
    required this.workoutId,
    this.exerciseId,
    this.fields = const {},
    required this.createdAt,
    this.baseUpdatedAt,
    this.attempts = 0,
    this.rejection,
  });

  bool get isRejected => rejection != null;

  /// Id of the workout or exercise the operation is about.
  String get targetId => type.onExercise ? exerciseId! : workoutId;

  PendingOperation copyWith({
    String? workoutId,
    String? exerciseId,
    Map<String, dynamic>? fields,
    DateTime? baseUpdatedAt,
    int? attempts,
    String? rejection,
    bool clearRejection = false,
  }) {
    return PendingOperation(
      id: id,
      type: type,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      fields: fields ?? this.fields,
      createdAt: createdAt,
      baseUpdatedAt: baseUpdatedAt ?? this.baseUpdatedAt,
      attempts: attempts ?? this.attempts,
      rejection: clearRejection ? null : rejection ?? this.rejection,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'workoutId': workoutId,
        if (exerciseId != null) 'exerciseId': exerciseId,
        if (fields.isNotEmpty) 'fields': fields,
        'createdAt': createdAt.toIso8601String(),
        if (baseUpdatedAt != null) 'baseUpdatedAt': baseUpdatedAt!.toIso8601String(),
        if (attempts > 0) 'attempts': attempts,
        if (rejection != null) 'rejection': rejection,
      };

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'] as String,
      type: OperationType.values.byName(json['type'] as String),
      workoutId: json['workoutId'] as String,
      exerciseId: json['exerciseId'] as String?,
      fields: (json['fields'] as Map<String, dynamic>?) ?? const {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      baseUpdatedAt: json['baseUpdatedAt'] == null ? null : DateTime.parse(json['baseUpdatedAt'] as String),
      attempts: json['attempts'] as int? ?? 0,
      rejection: json['rejection'] as String?,
    );
  }
}
