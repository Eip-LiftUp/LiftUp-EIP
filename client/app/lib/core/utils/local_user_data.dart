import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/providers/user_profile_provider.dart';
import 'package:app/core/sync/workout_store.dart';

/// Removes everything the app keeps on the device for [userId]: workouts and
/// pending changes, cached profile, video verdicts, started program.
Future<void> clearLocalUserData(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  for (final key in ['reviews.$userId', 'program.$userId', profileCacheKey(userId)]) {
    await prefs.remove(key);
  }
  await WorkoutStore(userId).clear();
}
