import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/models/workout.dart';
import 'package:app/core/providers/active_workout_provider.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/workout_provider.dart';
import 'package:app/core/utils/workout_stats.dart';
import 'package:app/core/widgets/ui/ui.dart';
import 'package:app/features/program/presentation/widgets/workout_actions.dart';
import 'package:app/features/program/presentation/widgets/workout_card.dart';
import 'package:app/features/program/presentation/widgets/workout_details_sheet.dart';
import 'package:app/features/video/video.dart';

/// "Entraînement" tab: video analysis and manual session creation on top,
/// then upcoming sessions and history.
class ProgramPage extends ConsumerStatefulWidget {
  const ProgramPage({super.key});

  @override
  ConsumerState<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends ConsumerState<ProgramPage> {
  /// Workout to start as soon as it is loaded (`/training?start=<id>`, sent by
  /// the home "Commencer la séance" button).
  String? _pendingStartId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pendingStartId ??= GoRouterState.of(context).uri.queryParameters['start'];
  }

  void _startPendingWorkout(String userId, List<WorkoutModel> workouts) {
    final id = _pendingStartId;
    if (id == null || id.isEmpty) return;
    final workout = workouts.where((w) => w.id == id).firstOrNull;
    if (workout == null) return;
    _pendingStartId = '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) startWorkout(context, ref, userId, workout);
    });
  }

  void _onMenu(String userId, WorkoutModel workout, WorkoutMenuAction action) {
    switch (action) {
      case WorkoutMenuAction.start:
        startWorkout(context, ref, userId, workout);
      case WorkoutMenuAction.edit:
        showWorkoutFormDialog(context, userId, workout: workout);
      case WorkoutMenuAction.addExercise:
        showAddExerciseFlow(context, userId, workout);
      case WorkoutMenuAction.delete:
        confirmDeleteWorkout(context, ref, userId, workout);
    }
  }

  void _openDetails(String userId, WorkoutModel workout) {
    showWorkoutDetailsSheet(
      context,
      userId,
      workout.id,
      onStart: () {
        final active = ref.read(activeWorkoutProvider);
        if (active.workoutId == workout.id) {
          showActiveWorkoutSheet(context, userId);
        } else {
          startWorkout(context, ref, userId, workout);
        }
      },
    );
  }

  void _openVideoAnalysis() {
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute<void>(builder: (_) => const VideoSelectionPage()));
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider).userId;
    if (userId == null) {
      return const Center(child: Text('Non connecté', style: AppText.caption));
    }

    final state = ref.watch(apiWorkoutProvider(userId));
    final active = ref.watch(activeWorkoutProvider);
    if (!state.isLoading) _startPendingWorkout(userId, state.workouts);

    final today = dateOnly(DateTime.now());
    final sorted = WorkoutStats(state.workouts).workouts;
    final upcoming = sorted
        .where((w) => !w.isCompleted && !dateOnly(w.workoutDate).isBefore(today))
        .toList();
    final history = sorted.reversed
        .where((w) => w.isCompleted || dateOnly(w.workoutDate).isBefore(today))
        .toList();
    final activeWorkout = sorted.where((w) => w.id == active.workoutId).firstOrNull;

    Widget card(WorkoutModel workout) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: WorkoutCard(
            workout: workout,
            isActive: workout.id == active.workoutId,
            onTap: () => _openDetails(userId, workout),
            onMenu: (action) => _onMenu(userId, workout, action),
          ),
        );

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.read(apiWorkoutProvider(userId).notifier).loadWorkouts(),
        child: PageListView(
          children: [
            const Text('Entraînement', style: AppText.h1),
            const SizedBox(height: 4),
            Text(
              upcoming.isEmpty
                  ? 'Aucune séance à venir'
                  : '${upcoming.length} séance${upcoming.length > 1 ? 's' : ''} à venir',
              style: AppText.caption,
            ),
            const SizedBox(height: 24),
            if (activeWorkout != null) ...[
              _ActiveSessionBanner(
                workout: activeWorkout,
                controller: active,
                onOpen: () => showActiveWorkoutSheet(context, userId),
              ),
              const SizedBox(height: 16),
            ],
            _ActionTile(
              icon: LucideIcons.sparkles,
              color: AppColors.primary,
              title: 'Générer un programme',
              subtitle: 'Un plan sur mesure basé sur ton profil',
              onTap: () => context.push('/training/generate'),
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: LucideIcons.video,
              color: AppColors.accent,
              title: 'Analyser une vidéo',
              subtitle: 'Ton coach IA vérifie ta technique',
              onTap: _openVideoAnalysis,
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: LucideIcons.plus,
              color: AppColors.success,
              title: 'Créer une séance',
              subtitle: 'Compose ta séance exercice par exercice',
              onTap: () => showWorkoutFormDialog(context, userId),
            ),
            const SizedBox(height: 32),
            if (state.isLoading && state.workouts.isEmpty) ...[
              const _CardSkeleton(),
              const SizedBox(height: 12),
              const _CardSkeleton(),
            ] else if (state.error != null && state.workouts.isEmpty)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InlineError('Impossible de charger tes séances.'),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Réessayer',
                      icon: LucideIcons.rotateCcw,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.sm,
                      onPressed: () => ref.read(apiWorkoutProvider(userId).notifier).loadWorkouts(),
                    ),
                  ],
                ),
              )
            else if (sorted.isEmpty)
              const AppCard(
                child: Row(
                  children: [
                    IconTile(icon: LucideIcons.dumbbell),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aucune séance pour l\'instant. Crée ta première séance ci-dessus.',
                        style: AppText.caption,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              const SectionTitle('À venir'),
              if (upcoming.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Rien de prévu pour le moment.', style: AppText.caption),
                )
              else
                for (final workout in upcoming) card(workout),
              const SizedBox(height: 12),
              const SectionTitle('Historique'),
              if (history.isEmpty)
                const Text('Tes séances passées apparaîtront ici.', style: AppText.caption)
              else
                for (final workout in history) card(workout),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconTile(icon: icon, color: color, size: 44),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodyMedium),
                Text(subtitle, style: AppText.caption),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _ActiveSessionBanner extends StatelessWidget {
  final WorkoutModel workout;
  final ActiveWorkoutController controller;
  final VoidCallback onOpen;

  const _ActiveSessionBanner({
    required this.workout,
    required this.controller,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(LucideIcons.timer, color: AppColors.onPrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.name,
                        style: AppText.bodyMedium.copyWith(color: AppColors.onPrimary),
                      ),
                      AnimatedBuilder(
                        animation: controller.timer,
                        builder: (context, _) => Text(
                          'Séance en cours • ${controller.timer.getFormattedTime()}',
                          style: AppText.caption.copyWith(
                            color: AppColors.onPrimary.withValues(alpha: 0.8),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text('Ouvrir', style: AppText.bodyMedium.copyWith(color: AppColors.onPrimary)),
                const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 80, height: 12),
          SizedBox(height: 8),
          FractionallySizedBox(widthFactor: 0.6, child: Skeleton(height: 20)),
          SizedBox(height: 16),
          Skeleton(height: 14),
          SizedBox(height: 8),
          FractionallySizedBox(widthFactor: 0.8, child: Skeleton(height: 14)),
        ],
      ),
    );
  }
}
