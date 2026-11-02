import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';
import 'package:app/core/providers/auth_provider.dart';
import 'package:app/core/providers/connectivity_provider.dart';
import 'package:app/core/widgets/ui/ui.dart';
import 'package:app/features/auth/presentation/widgets/auth_link.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  static String? _passwordError(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez entrer un mot de passe';
    if (value.length < 8) return 'Le mot de passe doit contenir au moins 8 caractères';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Le mot de passe doit contenir une majuscule';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Le mot de passe doit contenir un chiffre';
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      setState(() => _errorMessage = 'Veuillez accepter les conditions d\'utilisation');
      return;
    }

    if (!ref.read(isOnlineProvider)) {
      setState(() => _errorMessage = offlineMessage);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authProvider.notifier).register(
          email: _emailController.text.trim(),
          username: _nameController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte créé avec succès !')),
      );
      final onboardingCompleted = ref.read(authProvider).onboardingCompleted;
      context.go(onboardingCompleted ? '/home' : '/profile-setup');
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = ref.read(authProvider).errorMessage ?? 'Erreur d\'inscription';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 32),
                  Semantics(header: true, child: const Text('Créer un compte', style: AppText.metric)),
                  const SizedBox(height: 8),
                  Text(
                    'Rejoignez LiftUp et commencez votre transformation',
                    style: AppText.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  AppCard(child: _buildForm()),
                  const SizedBox(height: 20),
                  _buildTermsCheckbox(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    InlineError(_errorMessage!),
                  ],
                  const SizedBox(height: 32),
                  AppButton(
                    label: _isLoading ? 'Création du compte…' : 'Créer mon compte',
                    loading: _isLoading,
                    fullWidth: true,
                    onPressed: _isLoading ? null : _register,
                  ),
                  const SizedBox(height: 8),
                  AuthLink(
                    prefix: 'Déjà un compte ? ',
                    link: 'Se connecter',
                    onTap: () => context.go('/login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: IconButton(
            tooltip: 'Retour',
            onPressed: () => context.go('/onboarding'),
            icon: const Icon(LucideIcons.arrowLeft, size: 20),
          ),
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
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Nom complet',
              hint: 'Jean Dupont',
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Veuillez entrer votre nom';
                if (value.length < 2) return 'Le nom doit contenir au moins 2 caractères';
                return null;
              },
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Email',
              hint: 'vous@exemple.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Veuillez entrer votre email';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Veuillez entrer un email valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Mot de passe',
              hint: '8 caractères minimum',
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              onChanged: (_) => setState(() {}),
              trailing: _visibilityButton(
                obscured: _obscurePassword,
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: _passwordError,
            ),
            const SizedBox(height: 8),
            _PasswordHint(valid: _passwordError(_passwordController.text) == null),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Confirmer le mot de passe',
              hint: 'Retapez votre mot de passe',
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              trailing: _visibilityButton(
                obscured: _obscureConfirmPassword,
                onPressed: () =>
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Veuillez confirmer votre mot de passe';
                if (value != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _visibilityButton({required bool obscured, required VoidCallback onPressed}) {
    return IconButton(
      tooltip: obscured ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
      onPressed: onPressed,
      icon: Icon(obscured ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
    );
  }

  Widget _buildTermsCheckbox() {
    void toggle() => setState(() {
          _acceptTerms = !_acceptTerms;
          if (_acceptTerms) _errorMessage = null;
        });

    // One control for screen readers: "J'accepte les conditions…, case cochée".
    return MergeSemantics(
      child: InkWell(
        onTap: toggle,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Checkbox(value: _acceptTerms, onChanged: (_) => toggle()),
              const SizedBox(width: 4),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: AppText.caption.copyWith(fontSize: 14, height: 20 / 14),
                    children: const [
                      TextSpan(text: 'J\'accepte les '),
                      TextSpan(
                        text: 'conditions d\'utilisation',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      TextSpan(text: ' et la '),
                      TextSpan(
                        text: 'politique de confidentialité',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordHint extends StatelessWidget {
  final bool valid;

  const _PasswordHint({required this.valid});

  @override
  Widget build(BuildContext context) {
    final color = valid ? AppColors.success : AppColors.textSecondary;
    return Row(
      children: [
        Icon(valid ? LucideIcons.circleCheck : LucideIcons.info, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            valid
                ? 'Mot de passe valide'
                : '8 caractères minimum, dont une majuscule et un chiffre',
            style: AppText.caption.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
