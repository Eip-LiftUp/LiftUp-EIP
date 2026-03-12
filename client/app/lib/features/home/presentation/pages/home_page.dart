import 'package:flutter/material.dart';
import 'package:app/core/constants/app_constants.dart';
import 'package:app/core/widgets/main_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          children: [
            const Spacer(),
            // Header
            _buildHeader(context),
            const Spacer(),
            // Version
            Text(
              'Version ${AppConstants.appVersion}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'lib/assets/image.png',
          width: 72,
          height: 72,
        ),
        const SizedBox(height: AppConstants.spacingM),
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
