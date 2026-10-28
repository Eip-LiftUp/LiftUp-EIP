import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';
import 'package:app/core/providers/auth_provider.dart';

const List<String> _kWeekdayShortLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// Home dashboard.
///
/// Everything below the greeting is a placeholder: honest empty states for
/// the weekly planning, the stats and today's exercises, not fabricated
/// data. These sections get wired to real providers/endpoints later.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final displayName = authState.displayName ?? authState.username;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGreeting(context, displayName),
            const SizedBox(height: AppConstants.spacingXl),

            _buildSectionTitle(context, 'Planning de la semaine', Icons.calendar_today_outlined),
            const SizedBox(height: AppConstants.spacingM),
            _buildPlanningPlaceholder(),
            const SizedBox(height: AppConstants.spacingXl),

            _buildSectionTitle(context, 'Statistiques', Icons.insights_outlined),
            const SizedBox(height: AppConstants.spacingM),
            _buildStatsPlaceholder(),
            const SizedBox(height: AppConstants.spacingXl),

            _buildSectionTitle(context, "Exercices du jour", Icons.fitness_center_outlined),
            const SizedBox(height: AppConstants.spacingM),
            _buildTodayExercisesPlaceholder(),
            const SizedBox(height: AppConstants.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, String? displayName) {
    return Row(
      children: [
        Image.asset('lib/assets/image.png', width: 48, height: 48),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName != null ? 'Salut, $displayName 👋' : 'Bienvenue sur LiftUp',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                "Voici un aperçu de ton entraînement",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: AppConstants.spacingS),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
        border: Border.all(color: AppColors.navBarBorder),
      ),
      child: child,
    );
  }

  // ==================== PLANNING (placeholder) ====================

  Widget _buildPlanningPlaceholder() {
    return _buildPlaceholderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isToday = index == DateTime.now().weekday - 1;
              return Column(
                children: [
                  Text(
                    _kWeekdayShortLabels[index],
                    style: TextStyle(
                      color: isToday ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday
                          ? AppColors.primary
                          : AppColors.navBarBorder,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: AppConstants.spacingL),
          Row(
            children: [
              const Icon(Icons.event_note_outlined, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: Text(
                  'Ton planning de la semaine s\'affichera ici.',
                  style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== STATS (placeholder) ====================

  Widget _buildStatsPlaceholder() {
    final stats = [
      ('Séances', Icons.local_fire_department_outlined, AppColors.primary),
      ('Série en cours', Icons.bolt_outlined, AppColors.accent),
      ('Temps total', Icons.timer_outlined, AppColors.secondary),
      ('Progression', Icons.trending_up_outlined, Colors.purple),
    ];

    return Row(
      children: List.generate(stats.length, (index) {
        final (label, icon, color) = stats[index];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < stats.length - 1 ? AppConstants.spacingS : 0,
            ),
            child: _buildPlaceholderCard(
              child: Column(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: AppConstants.spacingS),
                  const Text(
                    '—',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ==================== TODAY'S EXERCISES (placeholder) ====================

  Widget _buildTodayExercisesPlaceholder() {
    return _buildPlaceholderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSkeletonExerciseRow(),
          const SizedBox(height: AppConstants.spacingM),
          _buildSkeletonExerciseRow(),
          const SizedBox(height: AppConstants.spacingM),
          _buildSkeletonExerciseRow(),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 18),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: Text(
                  'Aucun exercice prévu pour aujourd\'hui pour le moment.',
                  style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonExerciseRow() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          ),
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              Container(
                width: 100,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
