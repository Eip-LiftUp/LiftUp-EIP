import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

/// "Progrès" tab: timeline of the last days (opens the planning), period
/// figures, volume curve, recent workouts and reviews with record badges.
class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({super.key});

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  static const _periods = [7, 30, 90];
  int _periodDays = 30;

  void _openPlanning([DateTime? day]) {
    context.push(day == null ? '/planning' : '/planning?date=${AppDateUtils.formatDateKey(day)}');
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider).userId;
    final workouts = userId == null ? const <WorkoutModel>[] : ref.watch(apiWorkoutProvider(userId)).workouts;
    final reviews = userId == null ? const <ReviewRecord>[] : ref.watch(reviewHistoryProvider(userId));
    final stats = WorkoutStats(workouts);
    final today = dateOnly(DateTime.now());
    final end = DateTime(today.year, today.month, today.day + 1);
    final start = DateTime(today.year, today.month, today.day - (_periodDays - 1));
    final previousStart = DateTime(start.year, start.month, start.day - _periodDays);

    final page = PageListView(
      children: [
        const Text('Progrès', style: AppText.h1),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            for (final days in _periods)
              AppChip(
                label: '$days jours',
                selected: _periodDays == days,
                onTap: () => setState(() => _periodDays = days),
              ),
          ],
        ),
        const SizedBox(height: 24),
        SectionTitle('Timeline', trailing: LinkText('Calendrier', onTap: _openPlanning)),
        _Timeline(today: today, stats: stats, reviews: reviews, onDayTap: _openPlanning),
        const SizedBox(height: 24),
        _Summary(
          stats: stats,
          start: start,
          end: end,
          previousStart: previousStart,
          today: today,
        ),
        const SizedBox(height: 24),
        _VolumeChart(workouts: stats.completedIn(start, end), start: start, periodDays: _periodDays),
        const SizedBox(height: 24),
        const SectionTitle('Séances et analyses récentes'),
        _RecentActivity(stats: stats, reviews: reviews, onTap: _openPlanning),
      ],
    );

    return SafeArea(
      child: userId == null
          ? page
          : RefreshIndicator(
              onRefresh: () => ref.read(apiWorkoutProvider(userId).notifier).loadWorkouts(),
              child: page,
            ),
    );
  }
}

// ==================== Timeline ====================

class _Timeline extends StatelessWidget {
  static const _days = 14;

  final DateTime today;
  final WorkoutStats stats;
  final List<ReviewRecord> reviews;
  final ValueChanged<DateTime> onDayTap;

  const _Timeline({
    required this.today,
    required this.stats,
    required this.reviews,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 84,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _days,
          separatorBuilder: (_, _) => const SizedBox(width: 4),
          itemBuilder: (context, index) {
            final day = DateTime(today.year, today.month, today.day - index);
            final dayWorkouts = stats.on(day);
            final done = dayWorkouts.any((w) => w.isCompleted);
            final verdicts = {for (final r in reviews) if (isSameDay(r.day, day)) r.verdict};
            final isToday = index == 0;

            return Semantics(
              button: true,
              label: [
                AppDateUtils.weekdayDayMonth(day),
                if (done) 'séance faite',
                for (final v in verdicts) v.label,
              ].join(', '),
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onDayTap(day),
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 40,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEEEE').format(day).toUpperCase(),
                        style: AppText.caption.copyWith(
                          color: isToday ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: done ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: isToday ? Border.all(color: AppColors.primary, width: 1.5) : null,
                        ),
                        child: Text(
                          '${day.day}',
                          style: AppText.bodyMedium.copyWith(
                            fontSize: 14,
                            color: done ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 7,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final (i, verdict) in ReviewVerdict.values
                                .where(verdicts.contains)
                                .indexed) ...[
                              if (i > 0) const SizedBox(width: 3),
                              DayMarker(color: verdict.color, shape: verdict.markerShape),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==================== Summary ====================

class _Summary extends StatelessWidget {
  final WorkoutStats stats;
  final DateTime start;
  final DateTime end;
  final DateTime previousStart;
  final DateTime today;

  const _Summary({
    required this.stats,
    required this.start,
    required this.end,
    required this.previousStart,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final current = stats.completedIn(start, end);
    final previous = stats.completedIn(previousStart, start);
    final volume = current.fold<double>(0, (sum, w) => sum + WorkoutStats.volumeKg(w));
    final previousVolume = previous.fold<double>(0, (sum, w) => sum + WorkoutStats.volumeKg(w));
    final volumeChange = previousVolume > 0 ? (volume - previousVolume) / previousVolume * 100 : null;
    final sessionsChange = current.length - previous.length;

    final due = stats
        .scheduledIn(start, end)
        .where((w) => !dateOnly(w.workoutDate).isAfter(today))
        .toList();
    final consistency = due.isEmpty ? null : current.length / due.length * 100;
    final records = stats
        .personalRecords()
        .where((r) => !r.workout.workoutDate.isBefore(start) && r.workout.workoutDate.isBefore(end))
        .length;

    final compact = NumberFormat.compact();

    Widget row(Widget left, Widget right) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [Expanded(child: left), const SizedBox(width: 12), Expanded(child: right)],
          ),
        );

    return Column(
      children: [
        row(
          MetricCard(
            label: 'Volume (kg)',
            value: volume == 0 ? '0' : compact.format(volume),
            trend: volumeChange == null || volumeChange == 0
                ? null
                : (volumeChange > 0 ? MetricTrend.up : MetricTrend.down),
            trendValue: volumeChange == null ? null : '${volumeChange > 0 ? '+' : ''}${volumeChange.round()} %',
          ),
          MetricCard(
            label: 'Séances',
            value: '${current.length}',
            trend: sessionsChange == 0 ? null : (sessionsChange > 0 ? MetricTrend.up : MetricTrend.down),
            trendValue: '${sessionsChange > 0 ? '+' : ''}$sessionsChange',
          ),
        ),
        const SizedBox(height: 12),
        row(
          MetricCard(
            label: 'Régularité',
            value: consistency == null ? '—' : '${consistency.round()} %',
            icon: LucideIcons.calendarCheck,
          ),
          MetricCard(label: 'Records', value: '$records', icon: LucideIcons.award),
        ),
      ],
    );
  }
}

// ==================== Volume chart ====================

class _VolumeChart extends StatelessWidget {
  final List<WorkoutModel> workouts;
  final DateTime start;
  final int periodDays;

  const _VolumeChart({required this.workouts, required this.start, required this.periodDays});

  @override
  Widget build(BuildContext context) {
    final points = [
      for (final w in workouts)
        if (WorkoutStats.volumeKg(w) > 0)
          (day: dateOnly(w.workoutDate), volume: WorkoutStats.volumeKg(w)),
    ];

    if (points.length < 2) {
      return const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Volume soulevé', style: AppText.h3),
            SizedBox(height: 8),
            Text(
              'Termine au moins deux séances avec des charges sur la période pour voir ta courbe.',
              style: AppText.caption,
            ),
          ],
        ),
      );
    }

    final first = points.first.volume;
    final last = points.last.volume;
    final change = (last - first) / first * 100;
    final up = change >= 0;
    final numbers = NumberFormat.decimalPattern();
    final compact = NumberFormat.compact();

    final spots = [
      for (final p in points) FlSpot(p.day.difference(start).inDays.toDouble(), p.volume),
    ];
    final values = points.map((p) => p.volume);
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) == 0 ? maxY * 0.2 : (maxY - minY) * 0.2;
    final minX = spots.first.x;
    final maxX = spots.last.x;
    final middleX = ((minX + maxX) / 2).roundToDouble();
    // First, middle and last day only: a label per day would collide.
    final xLabels = {minX, maxX, if (middleX - minX >= 2 && maxX - middleX >= 2) middleX};

    String dayLabel(double x) => AppDateUtils.shortDayMonth(
          DateTime(start.year, start.month, start.day + x.round()),
        );

    final axisStyle = AppText.caption.copyWith(fontSize: 11);
    const gridLine = FlLine(color: AppColors.border, strokeWidth: 1, dashArray: [3, 3]);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Volume soulevé', style: AppText.h3)),
              Icon(
                up ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                size: 16,
                color: up ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 6),
              Text(
                '${up ? '+' : ''}${change.toStringAsFixed(1).replaceAll('.', ',')} %',
                style: AppText.caption.copyWith(color: up ? AppColors.success : AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Charge totale par séance (kg)', style: AppText.caption),
          const SizedBox(height: 16),
          Semantics(
            label: 'Courbe du volume : ${points.length} séances, de ${numbers.format(first)} kg '
                'le ${AppDateUtils.shortDayMonth(points.first.day)} à ${numbers.format(last)} kg '
                'le ${AppDateUtils.shortDayMonth(points.last.day)}.',
            excludeSemantics: true,
            child: SizedBox(
              height: 192,
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: (minY - padding).clamp(0, double.infinity),
                  maxY: maxY + padding,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    getDrawingHorizontalLine: (_) => gridLine,
                    getDrawingVerticalLine: (_) => gridLine,
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        minIncluded: false,
                        maxIncluded: false,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(compact.format(value), style: axisStyle),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        interval: 1,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            xLabels.contains(value) ? dayLabel(value) : '',
                            style: axisStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    getTouchedSpotIndicator: (bar, indexes) => [
                      for (final _ in indexes)
                        const TouchedSpotIndicatorData(
                          FlLine(color: AppColors.textSecondary, strokeWidth: 1, dashArray: [3, 3]),
                          FlDotData(),
                        ),
                    ],
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => AppColors.surface2,
                      tooltipBorder: const BorderSide(color: AppColors.border),
                      tooltipBorderRadius: BorderRadius.circular(8),
                      fitInsideHorizontally: true,
                      getTooltipItems: (spots) => [
                        for (final spot in spots)
                          LineTooltipItem(
                            '${dayLabel(spot.x)}\n',
                            AppText.caption,
                            children: [
                              const TextSpan(text: '● ', style: TextStyle(color: AppColors.primary)),
                              TextSpan(
                                text: '${numbers.format(spot.y)} kg',
                                style: AppText.bodyMedium.copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: AppColors.surface1,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.18),
                            AppColors.primary.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Recent activity ====================

class _RecentActivity extends StatelessWidget {
  static const _limit = 8;

  final WorkoutStats stats;
  final List<ReviewRecord> reviews;
  final ValueChanged<DateTime> onTap;

  const _RecentActivity({required this.stats, required this.reviews, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final recordsByWorkout = <String, List<PersonalRecord>>{};
    for (final record in stats.personalRecords()) {
      (recordsByWorkout[record.workout.id] ??= []).add(record);
    }

    final items = <({DateTime day, Widget card})>[
      for (final workout in stats.recentCompleted(limit: _limit))
        (
          day: dateOnly(workout.workoutDate),
          card: _WorkoutItem(
            workout: workout,
            records: recordsByWorkout[workout.id] ?? const [],
            onTap: () => onTap(workout.workoutDate),
          ),
        ),
      for (final review in reviews)
        (day: review.day, card: _ReviewItem(review: review, onTap: () => onTap(review.day))),
    ]..sort((a, b) => b.day.compareTo(a.day));

    if (items.isEmpty) {
      return const AppCard(
        child: Row(
          children: [
            IconTile(icon: LucideIcons.history, color: AppColors.textSecondary, background: AppColors.surface2),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tes séances terminées et tes analyses vidéo apparaîtront ici.',
                style: AppText.caption,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final item in items.take(_limit)) ...[item.card, const SizedBox(height: 12)],
      ],
    );
  }
}

class _WorkoutItem extends StatelessWidget {
  final WorkoutModel workout;
  final List<PersonalRecord> records;
  final VoidCallback onTap;

  const _WorkoutItem({required this.workout, required this.records, required this.onTap});

  static String _weight(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString().replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconTile(icon: LucideIcons.dumbbell, color: AppColors.success),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.name, style: AppText.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      [
                        AppDateUtils.shortDayMonth(workout.workoutDate),
                        if (workout.durationMinutes != null) '${workout.durationMinutes} min',
                        '${workout.exercises.length} exercice${workout.exercises.length > 1 ? 's' : ''}',
                      ].join(' • '),
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.check, size: 18, color: AppColors.success),
            ],
          ),
          if (records.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final record in records)
                  Pill(
                    icon: LucideIcons.award,
                    color: AppColors.accent,
                    text: 'Record · ${record.exerciseName} ${_weight(record.weight)} '
                        '${record.unit.displayName} (+${_weight(record.gain)})',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final ReviewRecord review;
  final VoidCallback onTap;

  const _ReviewItem({required this.review, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          IconTile(icon: LucideIcons.video, color: review.verdict.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(analysisExerciseLabel(review.exercise), style: AppText.bodyMedium),
                Text(
                  '${AppDateUtils.shortDayMonth(review.day)} • Analyse vidéo • ${review.score}/100',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          VerdictBadge(review.verdict),
        ],
      ),
    );
  }
}
