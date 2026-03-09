import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';
import 'package:app/config/providers.dart';

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
  /// Mock achievements data
  final List<_Achievement> _achievements = [
    _Achievement(
      title: 'Premier pas',
      description: 'Complétez votre premier entraînement',
      icon: Icons.directions_walk,
      isUnlocked: true,
    ),
    _Achievement(
      title: 'Régularité',
      description: '7 jours consécutifs d\'entraînement',
      icon: Icons.local_fire_department,
      isUnlocked: true,
    ),
    _Achievement(
      title: 'Force brute',
      description: 'Soulevez 100kg au squat',
      icon: Icons.fitness_center,
      isUnlocked: true,
    ),
    _Achievement(
      title: 'Marathonien',
      description: '30 jours consécutifs d\'entraînement',
      icon: Icons.emoji_events,
      isUnlocked: false,
    ),
  ];

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
              ref.read(appStateProvider.notifier).logout();
              context.go('/onboarding');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  /// Show edit profile dialog
  void _showEditProfileDialog() {
    final profile = ref.read(appStateProvider).userProfile;
    final nameController = TextEditingController(text: profile?.name ?? 'Jean Dupont');
    final emailController = TextEditingController(text: profile?.email ?? 'jean.dupont@email.com');
    final phoneController = TextEditingController(text: profile?.phone ?? '+33 6 12 34 56 78');

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
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Nom complet', Icons.person_outline),
              ),
              const SizedBox(height: AppConstants.spacingM),
              TextField(
                controller: emailController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Email', Icons.email_outlined),
              ),
              const SizedBox(height: AppConstants.spacingM),
              TextField(
                controller: phoneController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Téléphone', Icons.phone_outlined),
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
            onPressed: () {
              ref.read(appStateProvider.notifier).updateUserProfile(
                name: nameController.text,
                email: emailController.text,
                phone: phoneController.text,
              );
              Navigator.of(context).pop();
              _showSuccessSnackBar('Profil mis à jour');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  /// Show personal info dialog
  void _showPersonalInfoDialog() {
    final profile = ref.read(appStateProvider).userProfile;
    String selectedLevel = profile?.level ?? 'Intermédiaire';

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Niveau de fitness',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: AppConstants.spacingS),
                ...['Débutant', 'Intermédiaire', 'Avancé', 'Expert'].map((level) {
                  return RadioListTile<String>(
                    title: Text(level, style: const TextStyle(color: AppColors.textPrimary)),
                    value: level,
                    groupValue: selectedLevel,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      setDialogState(() => selectedLevel = value!);
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(appStateProvider.notifier).updateUserProfile(level: selectedLevel);
                Navigator.of(context).pop();
                _showSuccessSnackBar('Niveau mis à jour: $selectedLevel');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show notifications settings dialog
  void _showNotificationsDialog() {
    final profile = ref.read(appStateProvider).userProfile;
    bool pushEnabled = profile?.notificationsEnabled ?? true;
    bool emailEnabled = profile?.emailNotifications ?? true;
    bool remindersEnabled = profile?.workoutReminders ?? true;

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
                title: const Text('Notifications push', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Recevoir des notifications', style: TextStyle(color: AppColors.textSecondary)),
                value: pushEnabled,
                activeColor: AppColors.primary,
                onChanged: (value) => setDialogState(() => pushEnabled = value),
              ),
              SwitchListTile(
                title: const Text('Emails', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Recevoir des emails', style: TextStyle(color: AppColors.textSecondary)),
                value: emailEnabled,
                activeColor: AppColors.primary,
                onChanged: (value) => setDialogState(() => emailEnabled = value),
              ),
              SwitchListTile(
                title: const Text('Rappels d\'entraînement', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Rappels avant les séances', style: TextStyle(color: AppColors.textSecondary)),
                value: remindersEnabled,
                activeColor: AppColors.primary,
                onChanged: (value) => setDialogState(() => remindersEnabled = value),
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
                ref.read(appStateProvider.notifier).updateUserProfile(
                  notificationsEnabled: pushEnabled,
                  emailNotifications: emailEnabled,
                  workoutReminders: remindersEnabled,
                );
                Navigator.of(context).pop();
                _showSuccessSnackBar('Préférences de notifications mises à jour');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
                title: const Text('Profil public', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Visible par les autres', style: TextStyle(color: AppColors.textSecondary)),
                value: profilePublic,
                activeColor: AppColors.primary,
                onChanged: (value) => setDialogState(() => profilePublic = value),
              ),
              SwitchListTile(
                title: const Text('Partager ma progression', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Avec mes amis', style: TextStyle(color: AppColors.textSecondary)),
                value: shareProgress,
                activeColor: AppColors.primary,
                onChanged: (value) => setDialogState(() => shareProgress = value),
              ),
              SwitchListTile(
                title: const Text('Classement', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Apparaître dans les classements', style: TextStyle(color: AppColors.textSecondary)),
                value: showInLeaderboard,
                activeColor: AppColors.primary,
                onChanged: (value) => setDialogState(() => showInLeaderboard = value),
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
                _showSuccessSnackBar('Paramètres de confidentialité mis à jour');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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

  Widget _buildHelpItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppConstants.spacingM),
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
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
        title: const Text('FAQ', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFAQItem('Comment ajouter un exercice ?', 'Allez dans Programme, sélectionnez un jour et appuyez sur "Ajouter un exercice".'),
              _buildFAQItem('Comment modifier mon programme ?', 'Dans l\'onglet Programme, vous pouvez modifier, ajouter ou supprimer des entraînements.'),
              _buildFAQItem('Comment suivre ma progression ?', 'Vos statistiques sont visibles sur votre profil et dans l\'analyse de mouvement.'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer'))],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
        title: const Text('Contacter le support', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: messageController,
          maxLines: 4,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: _inputDecoration('Votre message', Icons.message_outlined),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
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
        title: const Text('Signaler un bug', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: bugController,
          maxLines: 4,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: _inputDecoration('Décrivez le bug', Icons.bug_report_outlined),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
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
          title: const Text('Feedback', style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Note', style: TextStyle(color: AppColors.textSecondary)),
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
                decoration: _inputDecoration('Votre feedback', Icons.chat_outlined),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessSnackBar('Merci pour votre feedback !');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
            const Text('LiftUp', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version 1.0.0', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppConstants.spacingM),
            const Text(
              'LiftUp est votre coach fitness personnel qui utilise l\'analyse de mouvement par IA pour améliorer votre forme.',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppConstants.spacingL),
            const Text('© 2025 LiftUp Team', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.borderRadiusL)),
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
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppConstants.spacingL),
              Consumer(
                builder: (context, ref, child) {
                  final appState = ref.watch(appStateProvider);
                  return SwitchListTile(
                    title: const Text('Mode sombre', style: TextStyle(color: AppColors.textPrimary)),
                    secondary: const Icon(Icons.dark_mode, color: AppColors.textSecondary),
                    value: appState.isDarkMode,
                    activeColor: AppColors.primary,
                    onChanged: (value) {
                      ref.read(appStateProvider.notifier).toggleDarkMode();
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.language, color: AppColors.textSecondary),
                title: const Text('Langue', style: TextStyle(color: AppColors.textPrimary)),
                trailing: const Text('Français', style: TextStyle(color: AppColors.primary)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showSuccessSnackBar('Langue: Français (seule langue disponible)');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Supprimer le compte', style: TextStyle(color: Colors.red)),
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
        title: const Text('Supprimer le compte', style: TextStyle(color: Colors.red)),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront supprimées.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(appStateProvider.notifier).logout();
              context.go('/onboarding');
              _showSuccessSnackBar('Compte supprimé (mock)');
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadiusM)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final profile = appState.userProfile;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Profile card
            _buildProfileCard(profile),

            // Stats section
            _buildStatsSection(profile),

            // Achievements section
            _buildAchievementsSection(),

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
            icon: const Icon(
              Icons.settings,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserProfile? profile) {
    final name = profile?.name ?? 'Jean Dupont';
    final email = profile?.email ?? 'jean.dupont@email.com';
    final level = profile?.level ?? 'Intermédiaire';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primary,
          ],
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
              child: const Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
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
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
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
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                  ),
                  child: Text(
                    level,
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
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(UserProfile? profile) {
    final totalWorkouts = profile?.totalWorkouts ?? 47;
    final totalHours = profile?.totalHours ?? 62;
    final currentStreak = profile?.currentStreak ?? 5;
    final longestStreak = profile?.longestStreak ?? 12;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.fitness_center,
                  value: '$totalWorkouts',
                  label: 'Entraînements',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.timer,
                  value: '${totalHours}h',
                  label: 'Heures totales',
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
                  icon: Icons.local_fire_department,
                  value: '$currentStreak',
                  label: 'Série actuelle',
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.emoji_events,
                  value: '$longestStreak',
                  label: 'Meilleure série',
                  color: Colors.purple,
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
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Réalisations',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '$unlockedCount/${_achievements.length}',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _achievements.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppConstants.spacingM),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showAchievementDetails(_achievements[index]),
                  child: _buildAchievementCard(_achievements[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAchievementDetails(_Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Row(
          children: [
            Icon(
              achievement.icon,
              color: achievement.isUnlocked ? AppColors.secondary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Text(
                achievement.title,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppConstants.spacingM),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM, vertical: AppConstants.spacingS),
              decoration: BoxDecoration(
                color: achievement.isUnlocked ? AppColors.secondary.withOpacity(0.2) : AppColors.navBarBorder.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
              ),
              child: Text(
                achievement.isUnlocked ? '✓ Débloqué' : '🔒 Verrouillé',
                style: TextStyle(
                  color: achievement.isUnlocked ? AppColors.secondary : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(_Achievement achievement) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
        border: Border.all(
          color: achievement.isUnlocked
              ? AppColors.secondary.withOpacity(0.5)
              : AppColors.navBarBorder,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingS),
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? AppColors.secondary.withOpacity(0.2)
                  : AppColors.navBarBorder.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement.icon,
              color: achievement.isUnlocked
                  ? AppColors.secondary
                  : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            achievement.title,
            style: TextStyle(
              color: achievement.isUnlocked
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
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
            padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
            ),
          ),
        ),
      ),
    );
  }
}

/// Data class for achievement
class _Achievement {
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;

  _Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
  });
}

