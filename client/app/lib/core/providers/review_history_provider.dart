import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/core/models/review_record.dart';

/// Video review verdicts of a user, kept on the device (one short string per
/// review) until the backend has a table for them.
class ReviewHistoryNotifier extends StateNotifier<List<ReviewRecord>> {
  final String userId;
  late final Future<void> _loaded;

  ReviewHistoryNotifier(this.userId) : super(const []) {
    _loaded = _load();
  }

  String get _key => 'reviews.$userId';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    state = [for (final entry in raw) ?ReviewRecord.decode(entry)];
  }

  /// All stored reviews, once loaded from the device.
  Future<List<ReviewRecord>> loaded() async {
    await _loaded;
    return state;
  }

  Future<void> add(ReviewRecord record) async {
    await _loaded;
    state = [...state, record];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, [for (final r in state) r.encode()]);
  }
}

final reviewHistoryProvider =
    StateNotifierProvider.family<ReviewHistoryNotifier, List<ReviewRecord>, String>(
  (ref, userId) => ReviewHistoryNotifier(userId),
);
