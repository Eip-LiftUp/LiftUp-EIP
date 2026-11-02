import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';

// Most pages still import AppColors through this file.
export 'package:app/config/app_colors.dart';

class _NavTab {
  final String label;
  final IconData icon;
  final String path;

  const _NavTab(this.label, this.icon, this.path);
}

const _tabs = [
  _NavTab('Accueil', LucideIcons.house, '/home'),
  _NavTab('Entraînement', LucideIcons.dumbbell, '/training'),
  _NavTab('Progrès', LucideIcons.trendingUp, '/progress'),
  _NavTab('Profil', LucideIcons.user, '/profile'),
];

class MainScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface1.withValues(alpha: 0.95),
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Expanded(
                        child: _NavItem(
                          tab: _tabs[i],
                          selected: i == currentIndex,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final _NavTab tab;
  final bool selected;

  const _NavItem({required this.tab, required this.selected});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected
        ? AppColors.primary
        : _hovered
            ? AppColors.textPrimary
            : AppColors.textSecondary;

    return Semantics(
      selected: widget.selected,
      button: true,
      label: widget.tab.label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => context.go(widget.tab.path),
          onHover: (value) => setState(() => _hovered = value),
          borderRadius: BorderRadius.circular(8),
          hoverColor: widget.selected
              ? Colors.transparent
              : AppColors.surface2.withValues(alpha: 0.5),
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Icon(widget.tab.icon, size: 24, color: color),
                    if (widget.selected)
                      Positioned(
                        bottom: -4,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
