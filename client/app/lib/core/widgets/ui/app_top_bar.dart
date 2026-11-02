import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';

/// Figma `AppBar`: left-aligned h1 title, optional 44px back button,
/// bottom border. Grows with the system text size; a title that still does
/// not fit wraps on two lines, then shrinks.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;

  /// Defaults to popping the current route.
  final VoidCallback? onBack;
  final List<Widget> actions;

  const AppTopBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.onBack,
    this.actions = const [],
  });

  @override
  Size get preferredSize => Size.fromHeight(43 + 34 * _textScale);

  /// Read from the platform because [preferredSize] has no context.
  static double get _textScale =>
      WidgetsBinding.instance.platformDispatcher.textScaleFactor.clamp(1.0, 2.0);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: preferredSize.height,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              if (showBack) ...[
                Transform.translate(
                  offset: const Offset(-8, 0),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                      tooltip: 'Retour',
                      icon: const Icon(LucideIcons.arrowLeft, size: 24),
                      color: AppColors.textPrimary,
                      hoverColor: AppColors.surface1,
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      child: Semantics(
                        header: true,
                        child: Text(title, style: AppText.h1, maxLines: 2),
                      ),
                    ),
                  ),
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
