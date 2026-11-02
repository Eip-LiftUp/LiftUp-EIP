import 'package:intl/intl.dart';

/// Date formatting utilities
class AppDateUtils {
  AppDateUtils._();

  /// "Lundi 27 octobre"
  static String weekdayDayMonth(DateTime date) =>
      _capitalize(DateFormat('EEEE d MMMM').format(date));

  /// "Octobre 2026"
  static String monthYear(DateTime date) => _capitalize(DateFormat('MMMM y').format(date));

  /// "21 oct."
  static String shortDayMonth(DateTime date) => DateFormat('d MMM').format(date);

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static String formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Aujourd\'hui';
    } else if (dateOnly == yesterday) {
      return 'Hier';
    } else {
      final weekdays = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
      final months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
      return '${weekdays[date.weekday % 7]} ${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} à ${formatTime(date)}';
  }
}
