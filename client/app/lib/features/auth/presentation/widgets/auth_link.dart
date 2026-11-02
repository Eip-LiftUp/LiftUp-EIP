import 'package:flutter/material.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';

/// "Prefix text + tappable link" line shown under the auth forms.
class AuthLink extends StatelessWidget {
  final String prefix;
  final String link;
  final VoidCallback onTap;

  const AuthLink({
    super.key,
    this.prefix = '',
    required this.link,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (prefix.isNotEmpty)
          Text(prefix, style: AppText.body.copyWith(color: AppColors.textSecondary)),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            child: Text(link, style: AppText.bodyMedium.copyWith(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }
}
