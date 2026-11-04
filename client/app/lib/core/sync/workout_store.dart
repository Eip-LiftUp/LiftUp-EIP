import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/core/sync/pending_operation.dart';

class StoredWorkouts {
  /// Last workouts received from the server; null before the first sync.
  final List<WorkoutModel>? workouts;
  final List<PendingOperation> operations;
  final DateTime? syncedAt;

  const StoredWorkouts({this.workouts, this.operations = const [], this.syncedAt});
}

/// Keeps a user's workouts and pending changes on the device, so the app
/// opens and works without network.
class WorkoutStore {
  final String userId;

  const WorkoutStore(this.userId);

  String get _workoutsKey => 'workouts.$userId';
  String get _operationsKey => 'sync.$userId';
  String get _syncedAtKey => 'sync.$userId.at';

  Future<StoredWorkouts> load() async {
    final prefs = await SharedPreferences.getInstance();
    return StoredWorkouts(
      workouts: _decode(prefs.getString(_workoutsKey), WorkoutModel.fromJson),
      operations: _decode(prefs.getString(_operationsKey), PendingOperation.fromJson) ?? const [],
      syncedAt: DateTime.tryParse(prefs.getString(_syncedAtKey) ?? ''),
    );
  }

  Future<void> saveWorkouts(List<WorkoutModel> workouts, {DateTime? syncedAt}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_workoutsKey, jsonEncode([for (final w in workouts) w.toJson()]));
    if (syncedAt != null) await prefs.setString(_syncedAtKey, syncedAt.toIso8601String());
  }

  Future<void> saveOperations(List<PendingOperation> operations) async {
    final prefs = await SharedPreferences.getInstance();
    if (operations.isEmpty) {
      await prefs.remove(_operationsKey);
    } else {
      await prefs.setString(_operationsKey, jsonEncode([for (final o in operations) o.toJson()]));
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [_workoutsKey, _operationsKey, _syncedAtKey]) {
      await prefs.remove(key);
    }
  }

  /// A corrupted entry is dropped rather than blocking the app.
  static List<T>? _decode<T>(String? raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw == null) return null;
    try {
      return [for (final item in jsonDecode(raw) as List<dynamic>) fromJson(item as Map<String, dynamic>)];
    } catch (_) {
      return null;
    }
  }
}
