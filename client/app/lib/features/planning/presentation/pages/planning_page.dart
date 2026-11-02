import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/models/review_record.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/review_history_provider.dart';
import 'package:app/core/providers/workout_provider.dart';
import 'package:app/core/utils/date_utils.dart';
import 'package:app/core/utils/workout_stats.dart';
import 'package:app/core/widgets/ui/ui.dart';

/// Month calendar of workouts and video review verdicts, one row per week.
class PlanningPage extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  const PlanningPage({super.key, this.initialDate});

  @override
  ConsumerState<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends ConsumerState<PlanningPage> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = dateOnly(widget.initialDate ?? DateTime.now());
    _month = DateTime(_selected.year, _selected.month);
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  void _goToToday() {
    final today = dateOnly(DateTime.now());
    setState(() {
      _selected = today;
      _month = DateTime(today.year, today.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider).userId;
    final workouts =
        userId == null ? const <WorkoutModel>[] : ref.watch(apiWorkoutProvider(userId)).workouts;
    final reviews =
        userId == null ? const <ReviewRecord>[] : ref.watch(reviewHistoryProvider(userId));
    final today = dateOnly(DateTime.now());

    return Scaffold(
      appBar: AppTopBar(
        title: 'Planning',
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      body: PageListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          _MonthHeader(
            month: _month,
            isCurrentMonth: _month.year == today.year && _month.month == today.month,
            onPrevious: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
            onToday: _goToToday,
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const _WeekdayLabels(),
                const SizedBox(height: 8),
                _MonthGrid(
                  month: _month,
                  today: today,
                  selected: _selected,
                  workouts: workouts,
                  reviews: reviews,
                  onSelect: (day) => setState(() => _selected = day),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _Legend(),
          const SizedBox(height: 24),
          SectionTitle(AppDateUtils.weekdayDayMonth(_selected)),
          _DayDetail(
            day: _selected,
            today: today,
            workouts: WorkoutStats(workouts).on(_selected),
            reviews: reviews.where((r) => isSameDay(r.day, _selected)).toList(),
          ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final bool isCurrentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  const _MonthHeader({
    required this.month,
    required this.isCurrentMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Mois précédent',
          onPressed: onPrevious,
          icon: const Icon(LucideIcons.chevronLeft),
        ),
        Expanded(
          child: Column(
            children: [
              Text(AppDateUtils.monthYear(month), style: AppText.h2, textAlign: TextAlign.center),
              if (!isCurrentMonth)
                InkWell(
                  onTap: onToday,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Revenir à aujourd\'hui',
                      style: AppText.caption.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Mois suivant',
          onPressed: onNext,
          icon: const Icon(LucideIcons.chevronRight),
        ),
      ],
    );
  }
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in const ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
          Expanded(child: Center(child: Text(label, style: AppText.caption))),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime today;
  final DateTime selected;
  final List<WorkoutModel> workouts;
  final List<ReviewRecord> reviews;
  final ValueChanged<DateTime> onSelect;

  const _MonthGrid({
    required this.month,
    required this.today,
    required this.selected,
    required this.workouts,
    required this.reviews,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final workoutsByDay = <DateTime, List<WorkoutModel>>{};
    for (final w in workouts) {
      (workoutsByDay[dateOnly(w.workoutDate)] ??= []).add(w);
    }
    final verdictsByDay = <DateTime, Set<ReviewVerdict>>{};
    for (final r in reviews) {
      (verdictsByDay[r.day] ??= {}).add(r.verdict);
    }

    final leading = DateTime(month.year, month.month, 1).weekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((leading + daysInMonth) / 7).ceil();

    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: Builder(builder: (context) {
                    final dayOfMonth = row * 7 + col - leading + 1;
                    if (dayOfMonth < 1 || dayOfMonth > daysInMonth) {
                      return const SizedBox(height: 56);
                    }
                    final day = DateTime(month.year, month.month, dayOfMonth);
                    return _DayCell(
                      day: day,
                      isToday: day == today,
                      isSelected: day == selected,
                      isPast: day.isBefore(today),
                      workouts: workoutsByDay[day] ?? const [],
                      verdicts: verdictsByDay[day] ?? const {},
                      onTap: () => onSelect(day),
                    );
                  }),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool isPast;
  final List<WorkoutModel> workouts;
  final Set<ReviewVerdict> verdicts;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.isPast,
    required this.workouts,
    required this.verdicts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final markers = <Widget>[
      for (final w in workouts.take(2))
        w.isCompleted
            ? const DayMarker(color: AppColors.primary)
            : DayMarker(
                color: isPast ? AppColors.textSecondary : AppColors.primary,
                shape: DayMarkerShape.ring,
              ),
      for (final verdict in ReviewVerdict.values)
        if (verdicts.contains(verdict)) DayMarker(color: verdict.color, shape: verdict.markerShape),
    ];

    final done = workouts.where((w) => w.isCompleted).length;
    return Semantics(
      button: true,
      selected: isSelected,
      label: [
        AppDateUtils.weekdayDayMonth(day),
        if (workouts.isNotEmpty) '${workouts.length} séance(s), $done terminée(s)',
        for (final verdict in verdicts) verdict.label,
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isToday ? Border.all(color: AppColors.primary, width: 1.5) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: AppText.bodyMedium.copyWith(
                  fontSize: 14,
                  color: isToday
                      ? AppColors.primary
                      : isPast && workouts.isEmpty && verdicts.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 7,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final (i, marker) in markers.take(4).indexed) ...[
                      if (i > 0) const SizedBox(width: 3),
                      marker,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final items = [
      (const DayMarker(color: AppColors.primary), 'Séance faite'),
      (const DayMarker(color: AppColors.primary, shape: DayMarkerShape.ring), 'Séance prévue'),
      for (final verdict in ReviewVerdict.values)
        (DayMarker(color: verdict.color, shape: verdict.markerShape), verdict.label),
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final (dot, label) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [dot, const SizedBox(width: 6), Text(label, style: AppText.caption)],
          ),
      ],
    );
  }
}

class _DayDetail extends StatelessWidget {
  final DateTime day;
  final DateTime today;
  final List<WorkoutModel> workouts;
  final List<ReviewRecord> reviews;

  const _DayDetail({
    required this.day,
    required this.today,
    required this.workouts,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty && reviews.isEmpty) {
      return AppCard(
        child: Text(
          day.isAfter(today) ? 'Rien de prévu ce jour-là.' : 'Aucune séance ni analyse ce jour-là.',
          style: AppText.caption,
        ),
      );
    }

    final isPast = day.isBefore(today);
    return Column(
      children: [
        for (final workout in workouts) ...[
          AppCard(
            onTap: () => context.go('/training'),
            child: Row(
              children: [
                IconTile(
                  icon: LucideIcons.dumbbell,
                  color: workout.isCompleted ? AppColors.success : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(workout.name, style: AppText.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        [
                          '${workout.exercises.length} exercice${workout.exercises.length > 1 ? 's' : ''}',
                          if (workout.durationMinutes != null) '${workout.durationMinutes} min',
                        ].join(' • '),
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (workout.isCompleted)
                  const Pill(text: 'Terminée', color: AppColors.success, dense: true)
                else if (isPast)
                  const Pill(
                    text: 'Non faite',
                    color: AppColors.textSecondary,
                    background: AppColors.surface2,
                    dense: true,
                  )
                else
                  const Pill(text: 'Prévue', color: AppColors.primary, dense: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (final review in reviews) ...[
          AppCard(
            child: Row(
              children: [
                IconTile(icon: LucideIcons.video, color: review.verdict.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(analysisExerciseLabel(review.exercise), style: AppText.bodyMedium),
                      const SizedBox(height: 4),
                      Text('Analyse vidéo • ${review.score}/100', style: AppText.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                VerdictBadge(review.verdict),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
