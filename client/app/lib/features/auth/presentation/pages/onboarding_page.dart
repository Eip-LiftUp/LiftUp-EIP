import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';

/// Onboarding Page (Get Started)
/// 
/// The initial page shown to new users with app introduction
/// and options to login or register.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      icon: null,
      imagePath: 'lib/assets/image.png',
      title: 'Bienvenue sur LiftUp',
      description:
          'Votre coach personnel alimenté par l\'IA pour améliorer vos performances sportives.',
      color: AppColors.primary,
    ),
    _OnboardingData(
      icon: Icons.videocam_rounded,
      title: 'Analysez vos Mouvements',
      description:
          'Filmez vos exercices et obtenez des conseils personnalisés pour perfectionner votre technique.',
      color: AppColors.secondary,
    ),
    _OnboardingData(
      icon: Icons.trending_up_rounded,
      title: 'Suivez vos Progrès',
      description:
          'Visualisez votre évolution et atteignez vos objectifs avec un programme adapté.',
      color: AppColors.accent,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Passer',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildIndicator(index),
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: _currentPage == _pages.length - 1
                  ? _buildFinalButtons()
                  : _buildNextButton(),
            ),

            const SizedBox(height: AppConstants.spacingL),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon container
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: data.imagePath != null
                ? ClipOval(
                    child: Image.asset(
                      data.imagePath!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  )
                : Icon(
                    data.icon,
                    size: 80,
                    color: data.color,
                  ),
          ),
          const SizedBox(height: AppConstants.spacingXl),

          // Title
          Text(
            data.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingM),

          // Description
          Text(
            data.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.textSecondary,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
          ),
        ),
        child: const Text(
          'Suivant',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFinalButtons() {
    return Column(
      children: [
        // Get Started / Register button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
              ),
            ),
            child: const Text(
              'Commencer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),

        // Login button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
              ),
            ),
            child: const Text(
              'J\'ai déjà un compte',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

/// Data class for onboarding pages
class _OnboardingData {
  final IconData? icon;
  final String? imagePath;
  final String title;
  final String description;
  final Color color;

  _OnboardingData({
    this.icon,
    this.imagePath,
    required this.title,
    required this.description,
    required this.color,
  });
}
