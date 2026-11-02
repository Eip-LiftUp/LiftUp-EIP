import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/user_profile_provider.dart';
import 'package:app/core/services/auth_api_service.dart';
import 'package:app/core/models/user.dart';
import 'package:app/core/widgets/ui/ui.dart';

/// Training focus options offered on the third onboarding page.
const List<String> kTrainingFocusOptions = [
  'Pectoraux',
  'Dos',
  'Jambes',
  'Épaules',
  'Bras',
  'Abdos',
  'Cardio',
  'Full Body',
  'Perte de poids',
  'Prise de masse',
  'Force',
  'Mobilité',
];

/// Structured body zones offered when the user reports an injury — kept distinct
/// from [kTrainingFocusOptions] since injuries map to joints/areas, not muscle
/// groups. This is the machine-readable counterpart to the free-text notes field.
const List<String> kInjuryZoneOptions = [
  'Épaules',
  'Coudes',
  'Poignets',
  'Dos / Lombaires',
  'Cervicales',
  'Hanches',
  'Genoux',
  'Chevilles',
];

const List<(ActivityFrequency, String, String)> kActivityFrequencyOptions = [
  (ActivityFrequency.sedentary, 'Sédentaire', 'Peu ou pas d\'activité physique'),
  (ActivityFrequency.light, 'Légère', '1 à 2 séances par semaine'),
  (ActivityFrequency.moderate, 'Modérée', '3 à 4 séances par semaine'),
  (ActivityFrequency.active, 'Active', '5 à 6 séances par semaine'),
  (ActivityFrequency.veryActive, 'Très active', 'Entraînement quotidien'),
];

/// First-launch onboarding wizard, reused from the profile to edit the same
/// answers ([editMode]).
///
/// - Page 1 (mandatory): height, weight, birth date, activity frequency.
/// - Page 2 (skippable): injuries + free-text medical history.
/// - Page 3 (skippable): training focus areas.
class ProfileSetupPage extends ConsumerStatefulWidget {
  final bool editMode;

  const ProfileSetupPage({super.key, this.editMode = false});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  static const _pageCount = 3;

  final PageController _pageController = PageController();
  final _mandatoryFormKey = GlobalKey<FormState>();

  int _currentPage = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Page 1 — mandatory
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _birthDateController = TextEditingController();
  DateTime? _birthDate;
  ActivityFrequency? _activityFrequency;

  // Page 2 — optional
  bool _hasInjuries = false;
  final Set<String> _injuredZones = {};
  final _medicalNotesController = TextEditingController();

  // Page 3 — optional
  final Set<String> _trainingFocus = {};

  bool _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    if (widget.editMode) _prefill();
  }

  Future<void> _prefill() async {
    final userId = ref.read(authProvider).userId;
    if (userId == null) return;
    setState(() => _loadingProfile = true);
    try {
      final p = await ref.read(userProfileProvider(userId).future);
      if (!mounted) return;
      setState(() {
        _activityFrequency = p.activityFrequency;
        _hasInjuries = p.hasInjuries ?? false;
        _injuredZones.addAll(p.injuredZones ?? const []);
        _medicalNotesController.text = p.medicalNotes ?? '';
        _trainingFocus.addAll(p.trainingFocus ?? const []);
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
        _errorMessage = 'Impossible de charger ton profil.';
      });
    }
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  void dispose() {
    _pageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _birthDateController.dispose();
    _medicalNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateController.text = _formatDate(picked);
      });
    }
  }

  void _goToPage(int index) {
    setState(() {
      _currentPage = index;
      _errorMessage = null;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _handleMandatoryNext() {
    // In edit mode the body measurements live in "Informations personnelles".
    final formValid = widget.editMode || (_mandatoryFormKey.currentState?.validate() ?? false);
    if (!formValid || _activityFrequency == null) {
      setState(() {
        _errorMessage = _activityFrequency == null
            ? 'Merci de compléter tous les champs pour continuer.'
            : null;
      });
      return;
    }
    _goToPage(1);
  }

  void _toggle(Set<String> set, String value) {
    setState(() => set.contains(value) ? set.remove(value) : set.add(value));
  }

  Future<void> _finish() async {
    final userId = ref.read(authProvider).userId;
    if (userId == null) {
      // Should not happen: this wizard only runs right after register/login.
      context.go('/home');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final notes = _medicalNotesController.text.trim();
    try {
      final api = ref.read(authApiServiceProvider);
      await api.updateProfile(
        userId: userId,
        heightCm: widget.editMode ? null : int.tryParse(_heightController.text.trim()),
        weightKg: widget.editMode ? null : double.tryParse(_weightController.text.trim().replaceAll(',', '.')),
        birthDate: widget.editMode ? null : _birthDate,
        activityFrequency: _activityFrequency,
        hasInjuries: _hasInjuries,
        // The API ignores null fields: when editing, send '' and [] so that
        // clearing the notes or the focus actually clears them.
        medicalNotes: notes.isEmpty && !widget.editMode ? null : notes,
        // Always send injuredZones (even as an empty list) once injuries are
        // toggled off, so unchecking clears a previously selected zone.
        injuredZones: _hasInjuries ? _injuredZones.toList() : const [],
        trainingFocus: _trainingFocus.isEmpty && !widget.editMode ? null : _trainingFocus.toList(),
        onboardingCompleted: widget.editMode ? null : true,
      );
      ref.invalidate(userProfileProvider(userId));

      if (!mounted) return;
      if (widget.editMode) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil d\'entraînement mis à jour')),
        );
      } else {
        ref.read(authProvider.notifier).markOnboardingCompleted();
        context.go('/home');
      }
    } on ApiException catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Une erreur est survenue, réessaie.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _loadingProfile
                      ? const Center(child: CircularProgressIndicator())
                      : PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (index) => setState(() => _currentPage = index),
                          children: [
                            _buildMandatoryPage(),
                            _buildMedicalPage(),
                            _buildTrainingFocusPage(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: _currentPage > 0
                    ? IconButton(
                        tooltip: 'Étape précédente',
                        onPressed: _isSubmitting ? null : () => _goToPage(_currentPage - 1),
                        icon: const Icon(LucideIcons.arrowLeft, size: 20),
                      )
                    : widget.editMode
                        ? IconButton(
                            tooltip: 'Retour au profil',
                            onPressed: () => context.pop(),
                            icon: const Icon(LucideIcons.arrowLeft, size: 20),
                          )
                        : null,
              ),
              const Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.dumbbell, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('LiftUp', style: AppText.h3),
                  ],
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
          const SizedBox(height: 24),
          Semantics(
            label: 'Étape ${_currentPage + 1} sur $_pageCount',
            child: Row(
              children: [
                for (var i = 0; i < _pageCount; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 6,
                      decoration: BoxDecoration(
                        color: i <= _currentPage ? AppColors.primary : AppColors.surface2,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ÉTAPE ${_currentPage + 1} SUR $_pageCount',
            style: AppText.caption.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  /// Scrollable step content with its actions pinned at the bottom.
  Widget _buildStep({
    required String title,
    required String subtitle,
    required List<Widget> children,
    required Widget actions,
  }) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: AppText.metric),
                const SizedBox(height: 8),
                Text(subtitle, style: AppText.body.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ...children,
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  InlineError(_errorMessage!),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: actions,
        ),
      ],
    );
  }

  Widget _skipAndNext({required VoidCallback onSkip, required VoidCallback onNext, required String nextLabel}) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Passer',
            variant: AppButtonVariant.secondary,
            fullWidth: true,
            onPressed: _isSubmitting ? null : onSkip,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: nextLabel,
            fullWidth: true,
            loading: _isSubmitting,
            onPressed: _isSubmitting ? null : onNext,
          ),
        ),
      ],
    );
  }

  // ==================== PAGE 1 — MANDATORY ====================

  Widget _buildMandatoryPage() {
    return _buildStep(
      title: widget.editMode ? 'Ton activité' : 'Parlons de toi',
      subtitle: widget.editMode
          ? 'À quelle fréquence fais-tu du sport ? Taille, poids et âge se modifient dans « Informations personnelles ».'
          : 'Ces informations nous permettent de calibrer ton programme. Tous les champs sont obligatoires.',
      actions: AppButton(
        label: 'Suivant',
        fullWidth: true,
        onPressed: _handleMandatoryNext,
      ),
      children: [
        if (!widget.editMode) ...[
          Form(
            key: _mandatoryFormKey,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Taille (cm)',
                          hint: '178',
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            final n = int.tryParse(value?.trim() ?? '');
                            if (n == null || n <= 0 || n >= 300) return 'Entre 1 et 299 cm';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Poids (kg)',
                          hint: '72,5',
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            final n = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
                            if (n == null || n <= 0 || n >= 700) return 'Entre 1 et 699 kg';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Date de naissance',
                    hint: 'Sélectionner une date',
                    controller: _birthDateController,
                    readOnly: true,
                    onTap: _pickBirthDate,
                    trailing: const Icon(LucideIcons.calendar, size: 20),
                    validator: (_) => _birthDate == null ? 'Date de naissance requise' : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        const Text('Fréquence d\'activité sportive', style: AppText.bodyMedium),
        const Text('Obligatoire', style: AppText.caption),
        const SizedBox(height: 12),
        for (final (value, label, description) in kActivityFrequencyOptions) ...[
          SelectableCard(
            title: label,
            subtitle: description,
            selected: _activityFrequency == value,
            onTap: () => setState(() {
              _activityFrequency = value;
              _errorMessage = null;
            }),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // ==================== PAGE 2 — MEDICAL (OPTIONAL) ====================

  Widget _buildMedicalPage() {
    return _buildStep(
      title: 'Blessures & antécédents',
      subtitle:
          'Facultatif. Ça nous aide à adapter les exercices proposés. Un simple résumé suffit, pas besoin d\'envoyer ton dossier médical.',
      actions: _skipAndNext(
        onSkip: () => _goToPage(2),
        onNext: () => _goToPage(2),
        nextLabel: 'Suivant',
      ),
      children: [
        AppCard(
          onTap: () => setState(() => _hasInjuries = !_hasInjuries),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('J\'ai une blessure actuelle ou passée', style: AppText.bodyMedium),
                    Text('Active pour préciser les zones concernées', style: AppText.caption),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: _hasInjuries,
                onChanged: (value) => setState(() => _hasInjuries = value),
              ),
            ],
          ),
        ),
        if (_hasInjuries) ...[
          const SizedBox(height: 24),
          const Text('Zone(s) concernée(s)', style: AppText.bodyMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final zone in kInjuryZoneOptions)
                AppChip(
                  label: zone,
                  selected: _injuredZones.contains(zone),
                  onTap: () => _toggle(_injuredZones, zone),
                ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        AppTextField(
          label: 'Détails complémentaires (facultatif)',
          hint: 'ex : tendinite à l\'épaule droite en 2024, lombalgie chronique…',
          controller: _medicalNotesController,
          maxLines: 5,
        ),
      ],
    );
  }

  // ==================== PAGE 3 — TRAINING FOCUS (OPTIONAL) ====================

  Widget _buildTrainingFocusPage() {
    return _buildStep(
      title: 'Sur quoi veux-tu bosser ?',
      subtitle:
          'Facultatif, tu pourras toujours changer ça plus tard dans ton profil. Sélectionne autant de zones/objectifs que tu veux.',
      actions: _skipAndNext(
        onSkip: _finish,
        onNext: _finish,
        nextLabel: widget.editMode ? 'Enregistrer' : 'Terminer',
      ),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in kTrainingFocusOptions)
              AppChip(
                label: option,
                selected: _trainingFocus.contains(option),
                onTap: () => _toggle(_trainingFocus, option),
              ),
          ],
        ),
      ],
    );
  }
}
