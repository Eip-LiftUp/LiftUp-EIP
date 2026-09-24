import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/services/auth_api_service.dart';
import 'package:app/core/models/user.dart';

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

/// First-launch onboarding wizard.
///
/// - Page 1 (mandatory): height, weight, birth date, activity frequency.
/// - Page 2 (skippable): injuries + free-text medical history.
/// - Page 3 (skippable): training focus areas, editable later from the profile.
class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final PageController _pageController = PageController();
  final _mandatoryFormKey = GlobalKey<FormState>();

  int _currentPage = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Page 1 — mandatory
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _birthDate;
  ActivityFrequency? _activityFrequency;

  // Page 2 — optional
  bool _hasInjuries = false;
  final Set<String> _injuredZones = {};
  final _medicalNotesController = TextEditingController();

  // Page 3 — optional
  final Set<String> _trainingFocus = {};

  @override
  void dispose() {
    _pageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  void _goToPage(int index) {
    setState(() => _currentPage = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleMandatoryNext() {
    final formValid = _mandatoryFormKey.currentState?.validate() ?? false;
    if (!formValid || _birthDate == null || _activityFrequency == null) {
      setState(() {
        _errorMessage = _birthDate == null || _activityFrequency == null
            ? 'Merci de compléter tous les champs pour continuer.'
            : null;
      });
      return;
    }
    setState(() => _errorMessage = null);
    _goToPage(1);
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

    try {
      final api = ref.read(authApiServiceProvider);
      await api.updateProfile(
        userId: userId,
        heightCm: int.tryParse(_heightController.text.trim()),
        weightKg: double.tryParse(_weightController.text.trim().replaceAll(',', '.')),
        birthDate: _birthDate,
        activityFrequency: _activityFrequency,
        hasInjuries: _hasInjuries,
        medicalNotes: _medicalNotesController.text.trim().isEmpty
            ? null
            : _medicalNotesController.text.trim(),
        // Always send injuredZones (even as an empty list) once injuries are
        // toggled off, so unchecking clears a previously selected zone.
        injuredZones: _hasInjuries ? _injuredZones.toList() : const [],
        trainingFocus: _trainingFocus.isEmpty ? null : _trainingFocus.toList(),
        onboardingCompleted: true,
      );

      ref.read(authProvider.notifier).markOnboardingCompleted();

      if (mounted) {
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressHeader(),
            Expanded(
              child: PageView(
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
    );
  }

  Widget _buildProgressHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingL,
        AppConstants.spacingM,
        AppConstants.spacingL,
        AppConstants.spacingS,
      ),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentPage;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 2 ? AppConstants.spacingS : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.navBarBorder,
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.textSecondary) : null,
      filled: true,
      fillColor: AppColors.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        borderSide: const BorderSide(color: AppColors.navBarBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        borderSide: const BorderSide(color: AppColors.navBarBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  // ==================== PAGE 1 — MANDATORY ====================

  Widget _buildMandatoryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Form(
        key: _mandatoryFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Parlons de toi',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Ces informations nous permettent de calibrer ton programme. Tous les champs sont obligatoires.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppConstants.spacingXl),

            _buildErrorMessage(),

            TextFormField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration(
                label: 'Taille (cm)',
                hint: 'ex: 178',
                icon: Icons.height,
              ),
              validator: (value) {
                final n = int.tryParse(value?.trim() ?? '');
                if (n == null || n <= 0 || n >= 300) {
                  return 'Taille invalide (1-299 cm)';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.spacingM),

            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration(
                label: 'Poids (kg)',
                hint: 'ex: 72.5',
                icon: Icons.monitor_weight_outlined,
              ),
              validator: (value) {
                final n = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
                if (n == null || n <= 0 || n >= 700) {
                  return 'Poids invalide (1-699 kg)';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.spacingM),

            InkWell(
              onTap: _pickBirthDate,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
              child: InputDecorator(
                decoration: _inputDecoration(
                  label: 'Date de naissance',
                  icon: Icons.cake_outlined,
                ),
                child: Text(
                  _birthDate == null
                      ? 'Sélectionner une date'
                      : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                  style: TextStyle(
                    color: _birthDate == null
                        ? AppColors.textSecondary.withOpacity(0.5)
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),

            Text(
              'Fréquence d\'activité sportive',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppConstants.spacingS),
            ...kActivityFrequencyOptions.map((option) {
              final (value, label, description) = option;
              final selected = _activityFrequency == value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
                child: InkWell(
                  onTap: () => setState(() => _activityFrequency = value),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingM,
                      vertical: AppConstants.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.navBarBorder,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: selected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppConstants.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                description,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: AppConstants.spacingXl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleMandatoryNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
                  ),
                ),
                child: const Text('Suivant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PAGE 2 — MEDICAL (OPTIONAL) ====================

  Widget _buildMedicalPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Blessures & antécédents',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Facultatif. Ça nous aide à adapter les exercices proposés. Un simple résumé suffit, pas besoin d\'envoyer ton dossier médical.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppConstants.spacingXl),

          _buildErrorMessage(),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
              border: Border.all(color: AppColors.navBarBorder),
            ),
            child: SwitchListTile(
              value: _hasInjuries,
              onChanged: (value) => setState(() => _hasInjuries = value),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'J\'ai une blessure actuelle ou passée',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),

          if (_hasInjuries) ...[
            Text(
              'Zone(s) concernée(s)',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppConstants.spacingS),
            Wrap(
              spacing: AppConstants.spacingS,
              runSpacing: AppConstants.spacingS,
              children: kInjuryZoneOptions.map((zone) {
                final selected = _injuredZones.contains(zone);
                return FilterChip(
                  label: Text(zone),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _injuredZones.add(zone);
                      } else {
                        _injuredZones.remove(zone);
                      }
                    });
                  },
                  backgroundColor: AppColors.cardBackground,
                  selectedColor: AppColors.primary.withOpacity(0.25),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.primary : AppColors.navBarBorder,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.spacingM),
          ],

          TextFormField(
            controller: _medicalNotesController,
            maxLines: 6,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDecoration(
              label: 'Détails complémentaires (facultatif)',
              hint: 'ex: tendinite à l\'épaule droite en 2024, lombalgie chronique...',
            ),
          ),

          const SizedBox(height: AppConstants.spacingXl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => _goToPage(2),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.navBarBorder),
                    padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
                    ),
                  ),
                  child: const Text('Passer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _goToPage(2),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
                    ),
                  ),
                  child: const Text('Suivant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== PAGE 3 — TRAINING FOCUS (OPTIONAL) ====================

  Widget _buildTrainingFocusPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sur quoi veux-tu bosser ?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Facultatif, tu pourras toujours changer ça plus tard dans ton profil. Sélectionne autant de zones/objectifs que tu veux.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppConstants.spacingXl),

          _buildErrorMessage(),

          Wrap(
            spacing: AppConstants.spacingS,
            runSpacing: AppConstants.spacingS,
            children: kTrainingFocusOptions.map((option) {
              final selected = _trainingFocus.contains(option);
              return FilterChip(
                label: Text(option),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _trainingFocus.add(option);
                    } else {
                      _trainingFocus.remove(option);
                    }
                  });
                },
                backgroundColor: AppColors.cardBackground,
                selectedColor: AppColors.primary.withOpacity(0.25),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.navBarBorder,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppConstants.spacingXl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _finish,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.navBarBorder),
                    padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
                    ),
                  ),
                  child: const Text('Passer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _finish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Terminer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
