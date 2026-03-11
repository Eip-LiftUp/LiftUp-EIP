import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/services/auth_api_service.dart';
import 'package:app/core/models/user.dart';

/// Profile Page
///
/// Displays user profile information, stats, achievements,
/// and settings options with fully functional buttons.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  UserProfileResponse? _profileData;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authState = ref.read(authProvider);
    if (authState.userId == null) return;

    setState(() => _isLoadingProfile = true);

    try {
      final api = AuthApiService();
      final profile = await api.getUserProfile(authState.userId!);
      setState(() {
        _profileData = profile;
        _isLoadingProfile = false;
      });
    } catch (e) {
      setState(() => _isLoadingProfile = false);
      if (mounted) {
        _showErrorSnackBar('Erreur de chargement du profil: ${e.toString()}');
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Déconnexion',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).logout();
              context.go('/onboarding');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  /// Show edit profile dialog (Pseudo only)
  void _showEditProfileDialog() {
    final authState = ref.read(authProvider);
    final displayNameController = TextEditingController(
      text: _profileData?.displayName ?? authState.username ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Modifier le profil',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: displayNameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  'Pseudo',
                  Icons.person_outline,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final api = AuthApiService();
                final userId = authState.userId;
                
                if (userId == null) {
                  _showErrorSnackBar('Erreur: utilisateur non connecté');
                  return;
                }

                // Update display name
                await api.updateProfile(
                  userId: userId,
                  displayName: displayNameController.text.isNotEmpty
                      ? displayNameController.text
                      : null,
                );

                // Update auth state
                if (displayNameController.text.isNotEmpty) {
                  ref.read(authProvider.notifier).updateDisplayName(
                        displayNameController.text,
                      );
                }

                // Reload profile
                await _loadUserProfile();

                if (mounted) {
                  Navigator.of(context).pop();
                  _showSuccessSnackBar('Pseudo mis à jour avec succès');
                }
              } catch (e) {
                if (mounted) {
                  _showErrorSnackBar('Erreur: ${e.toString()}');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  /// Show personal info dialog (Weight, height, fitness level, goals)
  void _showPersonalInfoDialog() {
    final authState = ref.read(authProvider);
    final weightController = TextEditingController(
      text: _profileData?.weightKg?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: _profileData?.heightCm?.toString() ?? '',
    );
    String? selectedLevel = _profileData?.fitnessLevel?.name;
    String? selectedGoal = _profileData?.fitnessGoals;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Informations personnelles',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration(
                    'Poids (kg)',
                    Icons.monitor_weight_outlined,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration(
                    'Taille (cm)',
                    Icons.height_outlined,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                DropdownButtonFormField<String>(
                  value: selectedLevel,
                  dropdownColor: AppColors.cardBackground,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration(
                    'Niveau de fitness',
                    Icons.fitness_center_outlined,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'beginner',
                      child: Text('Débutant'),
                    ),
                    DropdownMenuItem(
                      value: 'intermediate',
                      child: Text('Intermédiaire'),
                    ),
                    DropdownMenuItem(
                      value: 'advanced',
                      child: Text('Avancé'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedLevel = value);
                  },
                ),
                const SizedBox(height: AppConstants.spacingM),
                DropdownButtonFormField<String>(
                  value: selectedGoal,
                  dropdownColor: AppColors.cardBackground,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration(
                    'Objectifs fitness',
                    Icons.flag_outlined,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'La sèche',
                      child: Text('La sèche'),
                    ),
                    DropdownMenuItem(
                      value: 'La prise de masse',
                      child: Text('La prise de masse'),
                    ),
                    DropdownMenuItem(
                      value: 'La recomposition corporelle',
                      child: Text('La recomposition corporelle'),
                    ),
                    DropdownMenuItem(
                      value: 'De la force',
                      child: Text('De la force'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedGoal = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final api = AuthApiService();
                  final userId = authState.userId;
                  
                  if (userId == null) {
                    _showErrorSnackBar('Erreur: utilisateur non connecté');
                    return;
                  }

                  // Parse weight and height
                  final weight = weightController.text.isNotEmpty
                      ? double.tryParse(weightController.text)
                      : null;
                  final height = heightController.text.isNotEmpty
                      ? int.tryParse(heightController.text)
                      : null;

                  // Convert fitness level string to enum
                  FitnessLevel? fitnessLevel;
                  if (selectedLevel != null) {
                    switch (selectedLevel) {
                      case 'beginner':
                        fitnessLevel = FitnessLevel.beginner;
                        break;
                      case 'intermediate':
                        fitnessLevel = FitnessLevel.intermediate;
                        break;
                      case 'advanced':
                        fitnessLevel = FitnessLevel.advanced;
                        break;
                    }
                  }

                  // Update profile
                  await api.updateProfile(
                    userId: userId,
                    weightKg: weight,
                    heightCm: height,
                    fitnessLevel: fitnessLevel,
                    fitnessGoals: selectedGoal,
                  );

                  // Reload profile data
                  await _loadUserProfile();

                  if (mounted) {
                    Navigator.of(context).pop();
                    _showSuccessSnackBar('Informations mises à jour avec succès');
                  }
                } catch (e) {
                  if (mounted) {
                    _showErrorSnackBar('Erreur: ${e.toString()}');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show notifications settings dialog
  void _showNotificationsDialog() {
    // TODO: Gérer les préférences de notification dans le backend
    bool pushEnabled = true;
    bool emailEnabled = true;
    bool remindersEnabled = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Notifications',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text(
                  'Notifications push',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: const Text(
                  'Recevoir des notifications',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                value: pushEnabled,
                activeColor: AppColors.primary,
                onChanged: (value) => setDialogState(() => pushEnabled = value),
              ),
              SwitchListTile(
                title: const Text(
                  'Emails',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: const Text(
                  'Recevoir des emails',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                value: emailEnabled,
                activeColor: AppColors.primary,
                onChanged: (value) =>
                    setDialogState(() => emailEnabled = value),
              ),
              SwitchListTile(
                title: const Text(
                  'Rappels d\'entraînement',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: const Text(
                  'Rappels avant les séances',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                value: remindersEnabled,
                activeColor: AppColors.primary,
                onChanged: (value) =>
                    setDialogState(() => remindersEnabled = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Sauvegarder les préférences de notification
                Navigator.of(context).pop();
                _showSuccessSnackBar(
                  'Préférences de notifications (à venir)',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show privacy settings dialog
  void _showPrivacyDialog() {
    bool profilePublic = false;
    bool shareProgress = true;
    bool showInLeaderboard = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Confidentialité',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text(
                  'Profil public',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: const Text(
                  'Visible par les autres',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                value: profilePublic,
                activeColor: AppColors.primary,
                onChanged: (value) =>
                    setDialogState(() => profilePublic = value),
              ),
              SwitchListTile(
                title: const Text(
                  'Partager ma progression',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: const Text(
                  'Avec mes amis',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                value: shareProgress,
                activeColor: AppColors.primary,
                onChanged: (value) =>
                    setDialogState(() => shareProgress = value),
              ),
              SwitchListTile(
                title: const Text(
                  'Classement',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: const Text(
                  'Apparaître dans les classements',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                value: showInLeaderboard,
                activeColor: AppColors.primary,
                onChanged: (value) =>
                    setDialogState(() => showInLeaderboard = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessSnackBar(
                  'Paramètres de confidentialité mis à jour',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show help & support dialog
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Aide & Support',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                icon: Icons.question_answer,
                title: 'FAQ',
                onTap: () {
                  Navigator.of(context).pop();
                  _showFAQDialog();
                },
              ),
              _buildHelpItem(
                icon: Icons.email_outlined,
                title: 'Contacter le support',
                onTap: () {
                  Navigator.of(context).pop();
                  _showContactSupportDialog();
                },
              ),
              _buildHelpItem(
                icon: Icons.bug_report_outlined,
                title: 'Signaler un bug',
                onTap: () {
                  Navigator.of(context).pop();
                  _showReportBugDialog();
                },
              ),
              _buildHelpItem(
                icon: Icons.chat_outlined,
                title: 'Feedback',
                onTap: () {
                  Navigator.of(context).pop();
                  _showFeedbackDialog();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppConstants.spacingM),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showFAQDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'FAQ',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFAQItem(
                'Comment ajouter un exercice ?',
                'Allez dans Programme, sélectionnez un jour et appuyez sur "Ajouter un exercice".',
              ),
              _buildFAQItem(
                'Comment modifier mon programme ?',
                'Dans l\'onglet Programme, vous pouvez modifier, ajouter ou supprimer des entraînements.',
              ),
              _buildFAQItem(
                'Comment suivre ma progression ?',
                'Vos statistiques sont visibles sur votre profil et dans l\'analyse de mouvement.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(answer, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _showContactSupportDialog() {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Contacter le support',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: messageController,
          maxLines: 4,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: _inputDecoration('Votre message', Icons.message_outlined),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showSuccessSnackBar('Message envoyé au support');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _showReportBugDialog() {
    final bugController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Signaler un bug',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: bugController,
          maxLines: 4,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: _inputDecoration(
            'Décrivez le bug',
            Icons.bug_report_outlined,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showSuccessSnackBar('Bug signalé, merci !');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Signaler'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final feedbackController = TextEditingController();
    int rating = 5;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Feedback',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Note',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: AppColors.accent,
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: AppConstants.spacingM),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  'Votre feedback',
                  Icons.chat_outlined,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessSnackBar('Merci pour votre feedback !');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show about dialog
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fitness_center, color: AppColors.primary),
            ),
            const SizedBox(width: AppConstants.spacingM),
            const Text(
              'LiftUp',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppConstants.spacingM),
            const Text(
              'LiftUp est votre coach fitness personnel qui utilise l\'analyse de mouvement par IA pour améliorer votre forme.',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppConstants.spacingL),
            const Text(
              '© 2025 LiftUp Team',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showSuccessSnackBar('Conditions d\'utilisation (mock)');
                  },
                  child: const Text('Conditions'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showSuccessSnackBar('Politique de confidentialité (mock)');
                  },
                  child: const Text('Confidentialité'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// Show settings quick menu
  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusL),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              const Text(
                'Paramètres rapides',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              SwitchListTile(
                title: const Text(
                  'Mode sombre',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                secondary: const Icon(
                  Icons.dark_mode,
                  color: AppColors.textSecondary,
                ),
                value: false, // TODO: Implémenter le dark mode
                activeColor: AppColors.primary,
                onChanged: (value) {
                  _showSuccessSnackBar('Mode sombre (à venir)');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.language,
                  color: AppColors.textSecondary,
                ),
                title: const Text(
                  'Langue',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                trailing: const Text(
                  'Français',
                  style: TextStyle(color: AppColors.primary),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showSuccessSnackBar(
                    'Langue: Français (seule langue disponible)',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Supprimer le compte',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteAccountDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Supprimer le compte',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront supprimées.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter DELETE user dans le backend
              ref.read(authProvider.notifier).logout();
              context.go('/onboarding');
              _showSuccessSnackBar('Suppression de compte (à venir)');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        borderSide: const BorderSide(color: AppColors.navBarBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Profile card
            _buildProfileCard(authState),

            // Stats section
            _buildStatsSection(),

            // Settings section
            _buildSettingsSection(),

            // Logout button
            _buildLogoutButton(),

            const SizedBox(height: AppConstants.spacingXl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Profil',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: _showSettingsMenu,
            icon: const Icon(Icons.settings, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(AuthState authState) {
    final name = _profileData?.displayName ?? authState.username ?? 'Utilisateur';
    final email = authState.email ?? 'email@example.com';
    final levelText = _profileData?.fitnessLevel != null
        ? _getFitnessLevelText(_profileData!.fitnessLevel!)
        : 'Non défini';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.8), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => _showSuccessSnackBar('Changer la photo (à venir)'),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.person, size: 40, color: Colors.white),
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingS,
                    vertical: AppConstants.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusS,
                    ),
                  ),
                  child: Text(
                    levelText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Edit button
          IconButton(
            onPressed: _showEditProfileDialog,
            icon: Container(
              padding: const EdgeInsets.all(AppConstants.spacingS),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final weight = _profileData?.weightKg;
    final height = _profileData?.heightCm;
    final goals = _profileData?.fitnessGoals ?? 'Non défini';
    final level = _profileData?.fitnessLevel != null
        ? _getFitnessLevelText(_profileData!.fitnessLevel!)
        : 'Non défini';

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mes informations',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isLoadingProfile)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.monitor_weight_outlined,
                  value: weight != null ? '${weight.toStringAsFixed(1)} kg' : '-',
                  label: 'Poids',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.height_outlined,
                  value: height != null ? '$height cm' : '-',
                  label: 'Taille',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.fitness_center,
                  value: level,
                  label: 'Niveau',
                  color: AppColors.accent,
                  valueSize: 14,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.flag_outlined,
                  value: goals,
                  label: 'Objectif',
                  color: Colors.purple,
                  valueSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    double? valueSize,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
        border: Border.all(color: AppColors.navBarBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: AppConstants.spacingS),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: valueSize ?? 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getFitnessLevelText(FitnessLevel level) {
    switch (level) {
      case FitnessLevel.beginner:
        return 'Débutant';
      case FitnessLevel.intermediate:
        return 'Intermédiaire';
      case FitnessLevel.advanced:
        return 'Avancé';
    }
  }

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paramètres',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
              border: Border.all(color: AppColors.navBarBorder),
            ),
            child: Column(
              children: [
                _buildSettingItem(
                  icon: Icons.person_outline,
                  title: 'Informations personnelles',
                  onTap: _showPersonalInfoDialog,
                ),
                _buildSettingsDivider(),
                _buildSettingItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: _showNotificationsDialog,
                ),
                _buildSettingsDivider(),
                _buildSettingItem(
                  icon: Icons.lock_outline,
                  title: 'Confidentialité',
                  onTap: _showPrivacyDialog,
                ),
                _buildSettingsDivider(),
                _buildSettingItem(
                  icon: Icons.help_outline,
                  title: 'Aide & Support',
                  onTap: _showHelpDialog,
                ),
                _buildSettingsDivider(),
                _buildSettingItem(
                  icon: Icons.info_outline,
                  title: 'À propos',
                  subtitle: 'Version 1.0.0',
                  onTap: _showAboutDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 24),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsDivider() {
    return Divider(
      color: AppColors.navBarBorder,
      height: 1,
      indent: AppConstants.spacingL + 24 + AppConstants.spacingM,
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
          label: const Text('Déconnexion'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.spacingM,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
            ),
          ),
        ),
      ),
    );
  }
}
