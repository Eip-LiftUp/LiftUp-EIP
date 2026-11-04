import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/models/user.dart';
import 'package:app/core/providers/active_program_provider.dart';
import 'package:app/core/providers/active_workout_provider.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/connectivity_provider.dart';
import 'package:app/core/providers/review_history_provider.dart';
import 'package:app/core/providers/user_profile_provider.dart';
import 'package:app/core/providers/workout_provider.dart';
import 'package:app/core/services/auth_api_service.dart';
import 'package:app/core/utils/local_user_data.dart';
import 'package:app/core/utils/workout_stats.dart';
import 'package:app/core/widgets/sync_status.dart';
import 'package:app/core/widgets/ui/ui.dart';
import 'package:app/features/profile/data/data_export.dart';

/// "Profil" tab: who you are, your data (view, edit, export, delete), help.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final userId = auth.userId;
    if (userId == null) {
      return const Center(child: Text('Non connecté', style: AppText.caption));
    }

    final profile = ref.watch(userProfileProvider(userId));
    final stats = WorkoutStats(ref.watch(apiWorkoutProvider(userId)).workouts);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(userProfileProvider(userId).future),
        child: PageListView(
          children: [
            Semantics(header: true, child: const Text('Profil', style: AppText.h1)),
            const SizedBox(height: 24),
            profile.when(
              loading: () => const AppCard(child: SizedBox(height: 160, child: Center(child: CircularProgressIndicator()))),
              error: (_, _) => AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InlineError(
                      ref.watch(isOnlineProvider) ? 'Impossible de charger ton profil.' : offlineProfileMessage,
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Réessayer',
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.sm,
                      onPressed: () => ref.invalidate(userProfileProvider(userId)),
                    ),
                  ],
                ),
              ),
              data: (p) => _UserCard(
                profile: p,
                stats: stats,
                onEdit: () => _showNameDialog(context, ref, userId, p),
              ),
            ),
            const SizedBox(height: 16),
            SyncStatusCard(userId: userId),
            const SizedBox(height: 24),
            const SectionTitle('Mes données'),
            _Group(
              children: [
                _Row(
                  icon: LucideIcons.userPen,
                  title: 'Informations personnelles',
                  subtitle: 'Taille, poids, âge, niveau, objectif',
                  onTap: profile.hasValue
                      ? () => _showPersonalInfoDialog(context, ref, userId, profile.requireValue)
                      : null,
                ),
                _Row(
                  icon: LucideIcons.heartPulse,
                  title: 'Profil d\'entraînement',
                  subtitle: 'Fréquence, blessures, focus',
                  onTap: () => context.push('/profile/training'),
                ),
                _Row(
                  icon: LucideIcons.download,
                  title: 'Exporter mes données',
                  subtitle: 'Profil, séances et analyses au format JSON',
                  onTap: profile.hasValue ? () => _export(context, ref, userId, profile.requireValue) : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionTitle('Préférences'),
            const _Group(
              children: [
                _Row(icon: LucideIcons.bell, title: 'Notifications', subtitle: 'Rappels de séance', comingSoon: true),
              ],
            ),
            const SizedBox(height: 24),
            const SectionTitle('Aide'),
            _Group(
              children: [
                _Row(
                  icon: LucideIcons.circleHelp,
                  title: 'Questions fréquentes',
                  onTap: () => _showFaqDialog(context),
                ),
                const _Row(
                  icon: LucideIcons.messageSquare,
                  title: 'Contacter l\'équipe',
                  subtitle: 'Support, bug ou suggestion',
                  comingSoon: true,
                ),
                _Row(
                  icon: LucideIcons.info,
                  title: 'À propos de LiftUp',
                  onTap: () => _showAboutDialog(context),
                ),
                _Row(
                  icon: LucideIcons.trash2,
                  title: 'Supprimer mon compte',
                  subtitle: 'Efface ton compte et tes données',
                  color: AppColors.error,
                  onTap: () => _confirmDeleteAccount(context, ref, userId),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const AppCard(
              accentColor: AppColors.primary,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.wifiOff, size: 20, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Utilisable hors ligne', style: AppText.bodyMedium),
                        SizedBox(height: 4),
                        Text(
                          'Tes séances sont enregistrées sur l\'appareil et se synchronisent dès que tu es en ligne. '
                          'La génération de programme, l\'analyse vidéo et la modification du profil demandent une connexion.',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Se déconnecter',
              icon: LucideIcons.logOut,
              variant: AppButtonVariant.destructive,
              fullWidth: true,
              onPressed: () => _confirmLogout(context, ref),
            ),
            const SizedBox(height: 16),
            Text(
              'LiftUp v${AppConstants.appVersion}',
              style: AppText.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== User card ====================

class _UserCard extends StatelessWidget {
  final UserProfileResponse profile;
  final WorkoutStats stats;
  final VoidCallback onEdit;

  const _UserCard({required this.profile, required this.stats, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final completed = stats.completed;
    final volume = completed.fold<double>(0, (sum, w) => sum + WorkoutStats.volumeKg(w));
    final activeDays = {for (final w in completed) dateOnly(w.workoutDate)}.length;
    final name = (profile.displayName?.isNotEmpty ?? false) ? profile.displayName! : profile.username;
    final memberSince = toBeginningOfSentenceCase(DateFormat('MMMM y').format(profile.createdAt));

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const GradientTile(icon: LucideIcons.user),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppText.h2, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(profile.email, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Pill(
                      text: 'Membre depuis ${memberSince.toLowerCase()}',
                      color: AppColors.textSecondary,
                      background: AppColors.surface2,
                      dense: true,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Modifier le pseudo',
                onPressed: onEdit,
                icon: const Icon(LucideIcons.pencil, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _Stat(value: '${completed.length}', label: 'Séances')),
              Expanded(
                child: _Stat(
                  value: volume == 0 ? '0' : NumberFormat.compact().format(volume),
                  label: 'Volume (kg)',
                ),
              ),
              Expanded(child: _Stat(value: '$activeDays', label: 'Jours actifs')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppText.metric.copyWith(fontSize: 20, height: 28 / 20)),
        const SizedBox(height: 2),
        Text(label, style: AppText.caption),
      ],
    );
  }
}

// ==================== Settings rows ====================

class _Group extends StatelessWidget {
  final List<Widget> children;

  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (index, child) in children.indexed) ...[
            if (index > 0) const Divider(indent: 20, endIndent: 20),
            child,
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? color;
  final bool comingSoon;

  const _Row({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.color,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.textSecondary;
    final enabled = !comingSoon && onTap != null;
    return Semantics(
      container: true,
      button: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        hoverColor: AppColors.surface2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: tint),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.body.copyWith(color: color ?? AppColors.textPrimary)),
                    if (subtitle != null) Text(subtitle!, style: AppText.caption),
                  ],
                ),
              ),
              if (comingSoon)
                const Pill(text: 'Bientôt', color: AppColors.textSecondary, background: AppColors.surface2, dense: true)
              else
                Icon(LucideIcons.chevronRight, size: 20, color: tint),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== Actions ====================

void _snack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? LucideIcons.circleAlert : LucideIcons.circleCheck,
              size: 20,
              color: error ? AppColors.error : AppColors.success,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: AppText.body)),
          ],
        ),
      ),
    );
}

Future<void> _showNameDialog(BuildContext context, WidgetRef ref, String userId, UserProfileResponse profile) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ProfileFormDialog(
      title: 'Modifier le pseudo',
      userId: userId,
      fields: [
        _Field.text('displayName', 'Pseudo', profile.displayName ?? profile.username),
      ],
      onSaved: (values) {
        final name = values['displayName'] as String?;
        if (name != null && name.isNotEmpty) ref.read(authProvider.notifier).updateDisplayName(name);
      },
    ),
  );
}

Future<void> _showPersonalInfoDialog(BuildContext context, WidgetRef ref, String userId, UserProfileResponse p) {
  String number(num? v) =>
      v == null ? '' : (v == v.roundToDouble() ? v.toInt().toString() : v.toString().replaceAll('.', ','));
  return showDialog<void>(
    context: context,
    builder: (_) => _ProfileFormDialog(
      title: 'Informations personnelles',
      userId: userId,
      fields: [
        _Field.number('weightKg', 'Poids (kg)', number(p.weightKg), decimal: true),
        _Field.number('heightCm', 'Taille (cm)', number(p.heightCm)),
        _Field.date('birthDate', 'Date de naissance', p.birthDate),
        _Field.choice('fitnessLevel', 'Niveau', p.fitnessLevel?.name, const {
          'beginner': 'Débutant',
          'intermediate': 'Intermédiaire',
          'advanced': 'Avancé',
        }),
        _Field.choice('fitnessGoals', 'Objectif', p.fitnessGoals, const {
          'La sèche': 'La sèche',
          'La prise de masse': 'La prise de masse',
          'La recomposition corporelle': 'La recomposition corporelle',
          'De la force': 'De la force',
        }),
      ],
    ),
  );
}

Future<void> _export(BuildContext context, WidgetRef ref, String userId, UserProfileResponse profile) async {
  await ref.read(apiWorkoutProvider(userId).notifier).loadWorkouts();
  final json = buildDataExport(
    profile: profile,
    workouts: ref.read(apiWorkoutProvider(userId)).workouts,
    reviews: await ref.read(reviewHistoryProvider(userId).notifier).loaded(),
    program: await ref.read(activeProgramProvider(userId).notifier).loaded(),
  );
  final message = await saveDataExport(json);
  if (context.mounted) _snack(context, message);
}

Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Se déconnecter ?'),
      content: const Text('Tu pourras te reconnecter à tout moment.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
        AppButton(
          label: 'Se déconnecter',
          variant: AppButtonVariant.destructive,
          size: AppButtonSize.sm,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final active = ref.read(activeWorkoutProvider);
  if (active.isActive) active.finish();
  ref.read(authProvider.notifier).logout();
  context.go('/onboarding');
}

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref, String userId) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer ton compte ?'),
      content: const Text(
        'Ton compte, ton profil et toutes tes séances seront définitivement supprimés. '
        'Pense à exporter tes données avant si tu veux les garder.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
        AppButton(
          label: 'Supprimer',
          variant: AppButtonVariant.destructive,
          size: AppButtonSize.sm,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  if (!ref.read(isOnlineProvider)) {
    _snack(context, offlineMessage, error: true);
    return;
  }

  try {
    await ref.read(authApiServiceProvider).deleteAccount(userId);
  } on AccountDeletionUnavailableException {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pas encore disponible'),
        content: const Text(
          'La suppression de compte n\'est pas encore proposée par le serveur. '
          'Ton compte et tes données n\'ont pas été supprimés.',
        ),
        actions: [
          AppButton(label: 'Compris', size: AppButtonSize.sm, onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
    return;
  } catch (_) {
    if (context.mounted) _snack(context, 'La suppression du compte a échoué', error: true);
    return;
  }

  await clearLocalUserData(userId);
  final active = ref.read(activeWorkoutProvider);
  if (active.isActive) active.finish();
  ref.read(authProvider.notifier).logout();
  if (!context.mounted) return;
  context.go('/onboarding');
  _snack(context, 'Ton compte a été supprimé');
}

void _showFaqDialog(BuildContext context) {
  const faq = [
    (
      'Comment créer une séance ?',
      'Onglet Entraînement › « Créer une séance », puis ajoute tes exercices depuis le menu de la séance.',
    ),
    (
      'Comment générer un programme ?',
      'Onglet Entraînement › « Générer un programme ». Il s\'appuie sur ton profil d\'entraînement.',
    ),
    (
      'Comment faire analyser ma technique ?',
      'Onglet Entraînement › « Analyser une vidéo ». Le verdict (Parfait, Améliorable ou À corriger) '
          'apparaît ensuite dans ton planning.',
    ),
    (
      'Où voir ma progression ?',
      'L\'onglet Progrès réunit ta timeline, ta courbe de volume et tes records.',
    ),
  ];
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Questions fréquentes'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (question, answer) in faq) ...[
              Text(question, style: AppText.bodyMedium.copyWith(color: AppColors.primary)),
              const SizedBox(height: 4),
              Text(answer, style: AppText.body.copyWith(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      actions: [
        AppButton(label: 'Fermer', size: AppButtonSize.sm, onPressed: () => Navigator.of(context).pop()),
      ],
    ),
  );
}

void _showAboutDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          GradientTile(icon: LucideIcons.dumbbell, size: 40),
          SizedBox(width: 12),
          Text('LiftUp'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Version ${AppConstants.appVersion}', style: AppText.caption),
          const SizedBox(height: 12),
          const Text(
            'LiftUp est ton coach personnel : programmes adaptés à ton profil et analyse de tes '
            'mouvements par l\'IA.',
            style: AppText.body,
          ),
          const SizedBox(height: 16),
          const Text('© 2025 LiftUp Team', style: AppText.caption),
        ],
      ),
      actions: [
        AppButton(label: 'Fermer', size: AppButtonSize.sm, onPressed: () => Navigator.of(context).pop()),
      ],
    ),
  );
}

// ==================== Profile form dialog ====================

class _Field {
  final String key;
  final String label;
  final String? initial;
  final bool number;
  final bool decimal;
  final Map<String, String>? choices;
  final bool isDate;
  final DateTime? initialDate;

  const _Field._(
    this.key,
    this.label,
    this.initial, {
    this.number = false,
    this.decimal = false,
    this.choices,
    this.isDate = false,
    this.initialDate,
  });

  factory _Field.text(String key, String label, String? initial) => _Field._(key, label, initial);

  factory _Field.number(String key, String label, String initial, {bool decimal = false}) =>
      _Field._(key, label, initial, number: true, decimal: decimal);

  factory _Field.choice(String key, String label, String? initial, Map<String, String> choices) =>
      _Field._(key, label, initial, choices: choices);

  factory _Field.date(String key, String label, DateTime? initial) =>
      _Field._(key, label, initial == null ? null : _formatDate(initial), isDate: true, initialDate: initial);
}

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Edits a few profile fields and PATCHes them.
class _ProfileFormDialog extends ConsumerStatefulWidget {
  final String title;
  final String userId;
  final List<_Field> fields;
  final void Function(Map<String, Object?> values)? onSaved;

  const _ProfileFormDialog({required this.title, required this.userId, required this.fields, this.onSaved});

  @override
  ConsumerState<_ProfileFormDialog> createState() => _ProfileFormDialogState();
}

class _ProfileFormDialogState extends ConsumerState<_ProfileFormDialog> {
  late final Map<String, TextEditingController> _controllers = {
    for (final f in widget.fields)
      if (f.choices == null) f.key: TextEditingController(text: f.initial ?? ''),
  };
  late final Map<String, String?> _choices = {
    for (final f in widget.fields)
      if (f.choices != null) f.key: f.choices!.containsKey(f.initial) ? f.initial : null,
  };
  late final Map<String, DateTime?> _dates = {
    for (final f in widget.fields)
      if (f.isDate) f.key: f.initialDate,
  };
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(_Field field) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dates[field.key] ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _dates[field.key] = picked;
      _controllers[field.key]!.text = _formatDate(picked);
    });
  }

  Object? _value(_Field field) {
    if (field.choices != null) return _choices[field.key];
    if (field.isDate) return _dates[field.key];
    final text = _controllers[field.key]!.text.trim();
    if (text.isEmpty) return null;
    if (!field.number) return text;
    return field.decimal ? double.tryParse(text.replaceAll(',', '.')) : int.tryParse(text);
  }

  Future<void> _save() async {
    if (!ref.read(isOnlineProvider)) {
      setState(() => _error = offlineMessage);
      return;
    }
    final values = {for (final f in widget.fields) f.key: _value(f)};
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final level = values['fitnessLevel'] as String?;
      await ref.read(authApiServiceProvider).updateProfile(
            userId: widget.userId,
            displayName: values['displayName'] as String?,
            weightKg: (values['weightKg'] as num?)?.toDouble(),
            heightCm: values['heightCm'] as int?,
            birthDate: values['birthDate'] as DateTime?,
            fitnessLevel: level == null ? null : FitnessLevel.values.byName(level),
            fitnessGoals: values['fitnessGoals'] as String?,
          );
      widget.onSaved?.call(values);
      ref.invalidate(userProfileProvider(widget.userId));
      if (!mounted) return;
      Navigator.of(context).pop();
      _snack(context, 'Profil mis à jour');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'L\'enregistrement a échoué, réessaie.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, field) in widget.fields.indexed) ...[
              if (index > 0) const SizedBox(height: 16),
              if (field.isDate)
                AppTextField(
                  label: field.label,
                  hint: 'Sélectionner une date',
                  controller: _controllers[field.key],
                  readOnly: true,
                  onTap: () => _pickDate(field),
                  trailing: const Icon(LucideIcons.calendar, size: 20),
                )
              else if (field.choices == null)
                AppTextField(
                  label: field.label,
                  controller: _controllers[field.key],
                  keyboardType: field.number
                      ? TextInputType.numberWithOptions(decimal: field.decimal)
                      : TextInputType.text,
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(child: Text(field.label, style: AppText.bodyMedium)),
                    const SizedBox(height: 8),
                    Semantics(
                      container: true,
                      label: field.label,
                      child: DropdownButtonFormField<String>(
                        initialValue: _choices[field.key],
                        dropdownColor: AppColors.surface2,
                        style: AppText.body,
                        hint: const Text('Choisir'),
                        // Long choices wrap instead of overflowing the dialog.
                        isExpanded: true,
                        itemHeight: null,
                        items: [
                          for (final MapEntry(key: value, value: label) in field.choices!.entries)
                            DropdownMenuItem(value: value, child: Text(label)),
                        ],
                        onChanged: (value) => setState(() => _choices[field.key] = value),
                      ),
                    ),
                  ],
                ),
            ],
            if (_error != null) ...[const SizedBox(height: 12), InlineError(_error!)],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        AppButton(label: 'Enregistrer', size: AppButtonSize.sm, loading: _saving, onPressed: _saving ? null : _save),
      ],
    );
  }
}
