import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/models/user.dart';
import 'package:app/core/providers/active_program_provider.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/connectivity_provider.dart';
import 'package:app/core/providers/user_profile_provider.dart';
import 'package:app/core/providers/workout_provider.dart';
import 'package:app/core/services/auth_api_service.dart';
import 'package:app/core/utils/date_utils.dart';
import 'package:app/core/widgets/ui/ui.dart';
import 'package:app/features/program/presentation/widgets/workout_actions.dart';
import 'package:app/features/program_generation/data/generated_program.dart';
import 'package:app/features/program_generation/data/program_api_service.dart';
import 'package:app/features/profile_setup/presentation/pages/profile_setup_page.dart';

enum _View { summary, loading, result, error }

/// "Générer un programme" (#90), following the four states of the Figma
/// ProgramGenerateScreen: profile summary, loading, result, error.
class GenerateProgramPage extends ConsumerStatefulWidget {
  const GenerateProgramPage({super.key});

  @override
  ConsumerState<GenerateProgramPage> createState() => _GenerateProgramPageState();
}

class _GenerateProgramPageState extends ConsumerState<GenerateProgramPage> {
  static const _statusMessages = [
    'Analyse de ton profil',
    'Sélection des exercices',
    'Équilibrage du volume',
  ];

  _View _view = _View.summary;
  GeneratedProgram? _program;
  ProgramGenerationException? _error;
  int _statusIndex = 0;
  Timer? _statusTimer;
  int _request = 0;
  bool _saving = false;

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _generate(String userId) async {
    if (!ref.read(isOnlineProvider)) {
      setState(() {
        _error = const ProgramGenerationException(offlineMessage);
        _view = _View.error;
      });
      return;
    }
    final request = ++_request;
    setState(() {
      _view = _View.loading;
      _statusIndex = 0;
    });
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(milliseconds: 850), (_) {
      setState(() => _statusIndex = (_statusIndex + 1) % _statusMessages.length);
    });

    try {
      final program = await ref.read(programApiServiceProvider).generateProgram(userId);
      if (!mounted || request != _request) return;
      setState(() {
        _program = program;
        _view = _View.result;
      });
    } on ProgramGenerationException catch (e) {
      if (!mounted || request != _request) return;
      if (e.profileIncomplete) {
        setState(() => _view = _View.summary);
        showAppSnack(context, 'Complète ton profil pour générer un programme', error: true);
        await _completeProfile(userId);
        return;
      }
      setState(() {
        _error = e;
        _view = _View.error;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = const ProgramGenerationException('Le service de génération est indisponible.');
        _view = _View.error;
      });
    } finally {
      if (request == _request) _statusTimer?.cancel();
    }
  }

  void _cancel() {
    _request++;
    _statusTimer?.cancel();
    setState(() => _view = _View.summary);
  }

  /// Opens the questionnaire above this page, then reloads the profile it
  /// filled in.
  Future<void> _completeProfile(String userId) async {
    await context.push('/profile-setup');
    if (mounted) ref.invalidate(userProfileProvider(userId));
  }

  Future<void> _start(String userId, GeneratedProgram program) async {
    setState(() => _saving = true);
    // Read before any await: the user may leave the page meanwhile.
    final notifier = ref.read(apiWorkoutProvider(userId).notifier);
    final activeProgram = ref.read(activeProgramProvider(userId).notifier);
    // Saved on the device at once; sent to the server in the background.
    for (final session in program.sessions) {
      final workout = await notifier.createWorkout(
        name: session.name,
        workoutDate: session.workoutDate,
        durationMinutes: session.durationMinutes,
        notes: session.focus.isEmpty ? null : 'Focus : ${session.focus.join(', ')}',
      );
      if (workout == null) continue;
      for (final (index, exercise) in session.exercises.indexed) {
        await notifier.addExercise(
          workoutId: workout.id,
          exerciseName: exercise.exerciseName,
          sets: exercise.sets,
          reps: exercise.reps,
          weight: exercise.weight,
          weightUnit: exercise.weightUnit,
          orderIndex: index,
          notes: exercise.notes,
        );
      }
    }
    await activeProgram.start(
      ActiveProgram(
        name: program.name,
        startDate: program.sessions.isEmpty ? DateTime.now() : program.sessions.first.workoutDate,
        weeks: program.weeks,
        sessionsPerWeek: program.sessionsPerWeek,
      ),
    );

    if (!mounted) return;
    context.go('/training');
    showAppSnack(context, 'Programme ajouté à ton planning');
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider).userId;

    return Scaffold(
      appBar: AppTopBar(
        title: _view == _View.result ? 'Ton nouveau programme' : 'Générer un programme',
        showBack: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/training'),
      ),
      body: userId == null
          ? const Center(child: Text('Non connecté', style: AppText.caption))
          : switch (_view) {
              _View.summary => _SummaryView(
                  userId: userId,
                  onGenerate: () => _generate(userId),
                  onCompleteProfile: () => _completeProfile(userId),
                ),
              _View.loading => _LoadingView(status: _statusMessages[_statusIndex], onCancel: _cancel),
              _View.result => _ResultView(
                  program: _program!,
                  saving: _saving,
                  onStart: () => _start(userId, _program!),
                  onRegenerate: () => _generate(userId),
                ),
              _View.error => _ErrorView(error: _error!, onRetry: () => _generate(userId)),
            },
    );
  }
}

/// Centered column capped at the Figma `max-w-md` width.
class _Body extends StatelessWidget {
  final List<Widget> children;
  final Widget? bottom;

  const _Body({required this.children, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: children,
              ),
            ),
            if (bottom != null)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}

// ==================== Summary ====================

class _SummaryView extends ConsumerWidget {
  final String userId;
  final VoidCallback onGenerate;
  final VoidCallback onCompleteProfile;

  const _SummaryView({required this.userId, required this.onGenerate, required this.onCompleteProfile});

  static String _level(FitnessLevel? level) => switch (level) {
        FitnessLevel.beginner => 'Débutant',
        FitnessLevel.intermediate => 'Intermédiaire',
        FitnessLevel.advanced => 'Avancé',
        null => 'Non renseigné',
      };

  static String _frequency(ActivityFrequency? frequency) {
    for (final (value, label, description) in kActivityFrequencyOptions) {
      if (value == frequency) return '$label · $description';
    }
    return 'Non renseignée';
  }

  static bool _isComplete(UserProfileResponse p) =>
      p.heightCm != null && p.weightKg != null && p.birthDate != null && p.activityFrequency != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider(userId));

    return profile.when(
      loading: () => const _Body(
        children: [
          Align(alignment: Alignment.centerLeft, child: Skeleton(width: 64, height: 64, radius: 16)),
          SizedBox(height: 20),
          Skeleton(height: 28),
          SizedBox(height: 24),
          Skeleton(height: 220, radius: 16),
        ],
      ),
      error: (_, _) => _Body(
        children: [
          InlineError(ref.watch(isOnlineProvider) ? 'Impossible de charger ton profil.' : offlineProfileMessage),
          const SizedBox(height: 16),
          AppButton(
            label: 'Réessayer',
            variant: AppButtonVariant.secondary,
            onPressed: () => ref.invalidate(userProfileProvider(userId)),
          ),
        ],
      ),
      data: (p) {
        final complete = _isComplete(p);
        final rows = [
          (LucideIcons.target, 'Objectif', p.fitnessGoals ?? 'Non renseigné'),
          (LucideIcons.users, 'Niveau', _level(p.fitnessLevel)),
          (LucideIcons.calendarDays, 'Fréquence', _frequency(p.activityFrequency)),
          if (p.hasInjuries == true && (p.injuredZones?.isNotEmpty ?? false))
            (LucideIcons.bandage, 'Zones à ménager', p.injuredZones!.join(', ')),
          if (p.trainingFocus?.isNotEmpty ?? false)
            (LucideIcons.crosshair, 'Focus', p.trainingFocus!.join(', ')),
        ];

        return _Body(
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label: 'Générer mon programme',
                icon: LucideIcons.sparkles,
                size: AppButtonSize.lg,
                fullWidth: true,
                onPressed: complete ? onGenerate : null,
              ),
              const SizedBox(height: 12),
              const Text('Quelques secondes suffisent', style: AppText.caption),
            ],
          ),
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: IconTile(icon: LucideIcons.sparkles, size: 64, iconSize: 32),
            ),
            const SizedBox(height: 20),
            Semantics(header: true, child: const Text('Récap de ton profil', style: AppText.metric)),
            const SizedBox(height: 8),
            Text(
              'Ton coach IA s\'appuie sur ces informations pour construire une semaine d\'entraînement équilibrée.',
              style: AppText.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                children: [
                  for (final (index, (icon, label, value)) in rows.indexed) ...[
                    if (index > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
                    Row(
                      children: [
                        IconTile(icon: icon, background: AppColors.surface2, size: 44),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label, style: AppText.caption),
                              Text(value, style: AppText.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!complete) ...[
              const SizedBox(height: 16),
              AppCard(
                accentColor: AppColors.warning,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Profil incomplet', style: AppText.bodyMedium),
                    const SizedBox(height: 4),
                    const Text(
                      'Taille, poids, date de naissance et fréquence d\'activité sont nécessaires pour générer un programme.',
                      style: AppText.caption,
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Compléter mon profil',
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.sm,
                      onPressed: onCompleteProfile,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ==================== Loading ====================

class _LoadingView extends StatelessWidget {
  final String status;
  final VoidCallback onCancel;

  const _LoadingView({required this.status, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return _Body(
      bottom: AppButton(
        label: 'Annuler',
        variant: AppButtonVariant.secondary,
        fullWidth: true,
        onPressed: onCancel,
      ),
      children: [
        const SizedBox(height: 24),
        const Center(child: _PulsingSparkles()),
        const SizedBox(height: 24),
        // Announced once; the status below changes too often to be read out.
        Semantics(
          liveRegion: true,
          child: const Text('Construction de ton programme…', style: AppText.metric, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 8),
        Text(
          status,
          style: AppText.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        const Row(
          children: [
            Skeleton(width: 128, height: 20),
            Spacer(),
            Skeleton(width: 64, height: 20, radius: 999),
          ],
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < 3; i++) ...[
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Skeleton(width: 80, height: 16), Spacer(), Skeleton(width: 56, height: 16)]),
                SizedBox(height: 12),
                FractionallySizedBox(widthFactor: 0.66, child: Skeleton(height: 24)),
                SizedBox(height: 12),
                Row(
                  children: [
                    Skeleton(width: 64, height: 24, radius: 999),
                    SizedBox(width: 8),
                    Skeleton(width: 80, height: 24, radius: 999),
                  ],
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

class _PulsingSparkles extends StatefulWidget {
  const _PulsingSparkles();

  @override
  State<_PulsingSparkles> createState() => _PulsingSparklesState();
}

class _PulsingSparklesState extends State<_PulsingSparkles> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.4).animate(_controller),
        child: const Icon(LucideIcons.sparkles, size: 44, color: AppColors.primary),
      ),
    );
  }
}

// ==================== Result ====================

class _ResultView extends StatefulWidget {
  final GeneratedProgram program;
  final bool saving;
  final VoidCallback onStart;
  final VoidCallback onRegenerate;

  const _ResultView({
    required this.program,
    required this.saving,
    required this.onStart,
    required this.onRegenerate,
  });

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  bool _showRationale = false;

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    final perWeek = program.sessionsPerWeek;

    return _Body(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            label: 'Démarrer ce programme',
            fullWidth: true,
            loading: widget.saving,
            onPressed: widget.saving ? null : widget.onStart,
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Régénérer',
            icon: LucideIcons.rotateCcw,
            variant: AppButtonVariant.secondary,
            fullWidth: true,
            onPressed: widget.saving ? null : widget.onRegenerate,
          ),
        ],
      ),
      children: [
        Row(
          children: [
            const Icon(LucideIcons.sparkles, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'GÉNÉRÉ POUR TOI PAR L\'IA',
                style: AppText.caption.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(program.name, style: AppText.metric),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(LucideIcons.calendarDays, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${program.weeks} semaines · $perWeek séance${perWeek > 1 ? 's' : ''} par semaine',
                style: AppText.caption,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (program.fromCache) ...[
          AppCard(
            accentColor: AppColors.warning,
            padding: const EdgeInsets.all(16),
            child: Text(
              'Dernier programme généré le ${AppDateUtils.weekdayDayMonth(program.generatedAt.toLocal())} : '
              'le coach IA ne répond pas, impossible de l\'actualiser pour le moment.',
              style: AppText.caption,
            ),
          ),
          const SizedBox(height: 16),
        ],
        for (final session in program.sessions) ...[
          _SessionCard(session: session),
          const SizedBox(height: 12),
        ],
        if (program.rationale != null) ...[
          const SizedBox(height: 12),
          AppCard(
            onTap: () => setState(() => _showRationale = !_showRationale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Pourquoi ce programme ?', style: AppText.bodyMedium)),
                    AnimatedRotation(
                      turns: _showRationale ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(LucideIcons.chevronDown, size: 20),
                    ),
                  ],
                ),
                if (_showRationale) ...[
                  const SizedBox(height: 16),
                  Text(program.rationale!, style: AppText.body.copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ProgramSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final count = session.exercises.length;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppDateUtils.weekdayDayMonth(session.workoutDate).toUpperCase(),
                      style: AppText.caption.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(session.name, style: AppText.h3),
                  ],
                ),
              ),
              if (session.durationMinutes != null)
                Row(
                  children: [
                    const Icon(LucideIcons.clock3, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${session.durationMinutes} min', style: AppText.caption),
                  ],
                ),
            ],
          ),
          if (session.focus.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final focus in session.focus)
                  Pill(text: focus, color: AppColors.textSecondary, background: AppColors.surface2),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(LucideIcons.dumbbell, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text('$count exercice${count > 1 ? 's' : ''}', style: AppText.caption),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== Error ====================

class _ErrorView extends StatelessWidget {
  final ProgramGenerationException error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _Body(
      bottom: AppButton(label: 'Réessayer', fullWidth: true, onPressed: onRetry),
      children: [
        const SizedBox(height: 48),
        const Center(
          child: IconTile(
            icon: LucideIcons.triangleAlert,
            color: AppColors.error,
            size: 80,
            iconSize: 36,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Impossible de générer un nouveau programme',
          style: AppText.metric,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          error.isTimeout
              ? 'Le coach IA met plus de temps que prévu. Tes données d\'entraînement sont intactes.'
              : '${error.message} Tes données d\'entraînement sont intactes.',
          style: AppText.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
