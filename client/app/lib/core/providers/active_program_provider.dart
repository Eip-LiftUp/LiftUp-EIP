import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The generated program the user started, for the "Phase en cours" card.
class ActiveProgram {
  final String name;
  final DateTime startDate;
  final int weeks;
  final int sessionsPerWeek;

  ActiveProgram({
    required this.name,
    required DateTime startDate,
    required this.weeks,
    required this.sessionsPerWeek,
  }) : startDate = DateTime(startDate.year, startDate.month, startDate.day);

  /// 1-based, capped to [weeks].
  int currentWeek(DateTime now) {
    final days = DateTime(now.year, now.month, now.day).difference(startDate).inDays;
    return (days ~/ 7 + 1).clamp(1, weeks);
  }

  bool isFinished(DateTime now) =>
      DateTime(now.year, now.month, now.day).difference(startDate).inDays >= weeks * 7;

  /// `LiftUp Force & Volume|20261028|6|4`
  String encode() {
    final d = startDate;
    final date = '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
    return '${name.replaceAll('|', ' ')}|$date|$weeks|$sessionsPerWeek';
  }

  static ActiveProgram? decode(String raw) {
    final parts = raw.split('|');
    if (parts.length != 4 || parts[1].length != 8) return null;
    final year = int.tryParse(parts[1].substring(0, 4));
    final month = int.tryParse(parts[1].substring(4, 6));
    final day = int.tryParse(parts[1].substring(6, 8));
    final weeks = int.tryParse(parts[2]);
    final perWeek = int.tryParse(parts[3]);
    if (year == null || month == null || day == null || weeks == null || perWeek == null) return null;
    return ActiveProgram(
      name: parts[0],
      startDate: DateTime(year, month, day),
      weeks: weeks,
      sessionsPerWeek: perWeek,
    );
  }
}

class ActiveProgramNotifier extends StateNotifier<ActiveProgram?> {
  final String userId;
  late final Future<void> _loaded;

  ActiveProgramNotifier(this.userId) : super(null) {
    _loaded = _load();
  }

  String get _key => 'program.$userId';

  Future<void> _load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    state = raw == null ? null : ActiveProgram.decode(raw);
  }

  /// The stored program, once loaded from the device.
  Future<ActiveProgram?> loaded() async {
    await _loaded;
    return state;
  }

  Future<void> start(ActiveProgram program) async {
    await _loaded;
    state = program;
    await (await SharedPreferences.getInstance()).setString(_key, program.encode());
  }
}

final activeProgramProvider =
    StateNotifierProvider.family<ActiveProgramNotifier, ActiveProgram?, String>(
  (ref, userId) => ActiveProgramNotifier(userId),
);
