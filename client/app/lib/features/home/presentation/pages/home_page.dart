import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/core/providers/active_program_provider.dart';
import 'package:app/core/providers/active_workout_provider.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/workout_provider.dart';
import 'package:app/core/utils/date_utils.dart';
import 'package:app/core/utils/workout_stats.dart';
import 'package:app/core/widgets/ui/ui.dart';

/// Home tab: AI suggestion, today's session, current phase, quick stats and
/// recent workouts. Every figure comes from the user's real workouts; the AI
/// suggestion and the current phase stay empty until they have a data source.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).userId;
    final workoutState = userId == null ? null : ref.watch(apiWorkoutProvider(userId));
    final loading = workoutState != null && workoutState.isLoading && workoutState.workouts.isEmpty;
    final stats = WorkoutStats(workoutState?.workouts ?? const []);
    final now = DateTime.now();

    final page = PageListView(
      children: [
        Text(AppDateUtils.weekdayDayMonth(now), style: AppText.caption),
        const SizedBox(height: 4),
        Semantics(header: true, child: const Text('Entraînement du jour', style: AppText.h1)),
        const SizedBox(height: 24),
        const _AiSuggestionCard(),
        const SizedBox(height: 24),
        if (loading)
          const _WorkoutCardSkeleton()
        else
          _TodayCard(
            workouts: stats.on(now),
            activeWorkoutId: ref.watch(activeWorkoutProvider).workoutId,
          ),
        const SizedBox(height: 24),
        _CurrentPhaseCard(
          program: userId == null ? null : ref.watch(activeProgramProvider(userId)),
          now: now,
          onTap: () => context.push('/planning'),
        ),
        const SizedBox(height: 24),
        const SectionTitle('Statistiques rapides'),
        _QuickStats(stats: stats, now: now),
        const SizedBox(height: 24),
        SectionTitle(
          'Séances récentes',
          trailing: LinkText('Planning', onTap: () => context.push('/planning')),
        ),
        _RecentWorkouts(workouts: stats.recentCompleted()),
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

class _AiSuggestionCard extends StatelessWidget {
  const _AiSuggestionCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      accentColor: AppColors.accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: LucideIcons.sparkles, color: AppColors.accent),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Suggestion IA', style: AppText.bodyMedium),
                    Pill(text: 'Bientôt', color: AppColors.accent, dense: true),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Ton coach analysera tes séances et tes vidéos pour te proposer des ajustements.',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma `WorkoutCard`, fed with today's first unfinished workout.
class _TodayCard extends StatelessWidget {
  final List<WorkoutModel> workouts;
  final String? activeWorkoutId;

  const _TodayCard({required this.workouts, required this.activeWorkoutId});

  @override
  Widget build(BuildContext context) {
    final next = workouts.where((w) => !w.isCompleted).firstOrNull;

    if (next != null) {
      final count = next.exercises.length;
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(next.name, style: AppText.h2),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                if (next.durationMinutes != null)
                  _Meta(icon: LucideIcons.clock, text: '${next.durationMinutes} min'),
                _Meta(
                  icon: LucideIcons.dumbbell,
                  text: count == 0 ? 'Aucun exercice' : '$count exercice${count > 1 ? 's' : ''}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: next.id == activeWorkoutId ? 'Reprendre la séance' : 'Commencer la séance',
              icon: LucideIcons.play,
              fullWidth: true,
              onPressed: () => context.go('/training?start=${next.id}'),
            ),
          ],
        ),
      );
    }

    if (workouts.isNotEmpty) {
      return AppCard(
        onTap: () => context.push('/planning'),
        child: Row(
          children: [
            const IconTile(icon: LucideIcons.circleCheck, color: AppColors.success),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Séance du jour terminée', style: AppText.bodyMedium),
                  Text(
                    workouts.map((w) => w.name).join(', '),
                    style: AppText.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Aucune séance prévue aujourd\'hui', style: AppText.h3),
          const SizedBox(height: 4),
          const Text(
            'Planifie une séance ou génère un programme depuis l\'onglet Entraînement.',
            style: AppText.caption,
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Aller à l\'entraînement',
            variant: AppButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => context.go('/training'),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Meta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(text, style: AppText.caption),
      ],
    );
  }
}

class _WorkoutCardSkeleton extends StatelessWidget {
  const _WorkoutCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FractionallySizedBox(widthFactor: 0.75, child: Skeleton(height: 28)),
          SizedBox(height: 8),
          FractionallySizedBox(widthFactor: 0.5, child: Skeleton(height: 16)),
          SizedBox(height: 16),
          Skeleton(height: 48, radius: 12),
        ],
      ),
    );
  }
}

/// Figma "Current Phase" card, fed by the program started from the
/// generation screen.
class _CurrentPhaseCard extends StatelessWidget {
  final ActiveProgram? program;
  final DateTime now;
  final VoidCallback onTap;

  const _CurrentPhaseCard({required this.program, required this.now, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final program = this.program;
    final running = program != null && !program.isFinished(now);
    final week = program?.currentWeek(now) ?? 0;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Phase en cours', style: AppText.h3)),
              if (running)
                Pill(text: 'Semaine $week sur ${program.weeks}', color: AppColors.primary)
              else
                const Pill(
                  text: 'Aucun programme',
                  color: AppColors.textSecondary,
                  background: AppColors.surface2,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (running) ...[
            Text(program.name, style: AppText.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '${program.sessionsPerWeek} séances par semaine sur ${program.weeks} semaines',
              style: AppText.caption,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    const Positioned.fill(child: ColoredBox(color: AppColors.surface2)),
                    FractionallySizedBox(
                      widthFactor: week / program.weeks,
                      heightFactor: 1,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(gradient: AppColors.primaryGradient),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Text(
              program != null
                  ? '« ${program.name} » est terminé. Génère un nouveau programme depuis l\'onglet Entraînement.'
                  : 'Aucun programme actif pour l\'instant. Tu pourras en générer un depuis l\'onglet Entraînement.',
              style: AppText.caption,
            ),
          ],
          const SizedBox(height: 12),
          const Row(
            children: [
              Text(
                'Voir le planning',
                style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              SizedBox(width: 2),
              Icon(LucideIcons.chevronRight, size: 16, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final WorkoutStats stats;
  final DateTime now;

  const _QuickStats({required this.stats, required this.now});

  @override
  Widget build(BuildContext context) {
    final week = stats.week(now);
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            label: 'Série',
            value: '${stats.streak(now)} j',
            valueLabel: '${stats.streak(now)} jour${stats.streak(now) > 1 ? 's' : ''}',
            icon: LucideIcons.flame,
            compact: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricCard(
            label: 'Semaine',
            value: week.planned == 0 ? '0' : '${week.done}/${week.planned}',
            valueLabel: week.planned == 0 ? null : '${week.done} sur ${week.planned}',
            icon: LucideIcons.calendar,
            compact: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricCard(
            label: 'Records',
            value: '${stats.personalRecords().length}',
            icon: LucideIcons.award,
            compact: true,
          ),
        ),
      ],
    );
  }
}

class _RecentWorkouts extends StatelessWidget {
  final List<WorkoutModel> workouts;

  const _RecentWorkouts({required this.workouts});

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return const AppCard(
        child: Row(
          children: [
            IconTile(
              icon: LucideIcons.history,
              color: AppColors.textSecondary,
              background: AppColors.surface2,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text('Tes séances terminées apparaîtront ici.', style: AppText.caption),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final workout in workouts) ...[
          AppCard(
            onTap: () => context.push(
              '/planning?date=${AppDateUtils.formatDateKey(workout.workoutDate)}',
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.name,
                        style: AppText.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          AppDateUtils.shortDayMonth(workout.workoutDate),
                          if (workout.durationMinutes != null) '${workout.durationMinutes} min',
                        ].join(' • '),
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.check, size: 16, color: AppColors.success),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
