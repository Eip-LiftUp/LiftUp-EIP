import 'package:flutter/material.dart';
import 'package:app/config/app_colors.dart';
import 'package:app/config/theme.dart';

enum AppButtonVariant { primary, secondary, destructive, ghost }

enum AppButtonSize { sm, md, lg }

/// Figma `Button`: rounded-xl, 40/48/56px heights, scale(0.98) on press,
/// 50% opacity when disabled.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool fullWidth;
  final bool loading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.fullWidth = false,
    this.loading = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool value) {
    if (_enabled && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground, Color hover, BorderSide side) =
        switch (widget.variant) {
      AppButtonVariant.primary => (
          AppColors.primary,
          AppColors.onPrimary,
          AppColors.primaryStrong,
          BorderSide.none,
        ),
      AppButtonVariant.secondary => (
          Colors.transparent,
          AppColors.textPrimary,
          AppColors.surface2,
          const BorderSide(color: AppColors.border, width: 2),
        ),
      AppButtonVariant.destructive => (
          AppColors.error,
          AppColors.textPrimary,
          AppColors.error.withValues(alpha: 0.9),
          BorderSide.none,
        ),
      AppButtonVariant.ghost => (
          Colors.transparent,
          AppColors.textPrimary,
          AppColors.surface1,
          BorderSide.none,
        ),
    };

    final (double height, double padding, double fontSize) = switch (widget.size) {
      AppButtonSize.sm => (40.0, 16.0, 14.0),
      AppButtonSize.md => (48.0, 24.0, 16.0),
      AppButtonSize.lg => (56.0, 32.0, 16.0),
    };

    final Widget? leading = widget.loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : widget.icon != null
            ? Icon(widget.icon, size: 20, color: foreground)
            : null;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: side,
    );

    final button = Material(
      color: background,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _enabled ? widget.onPressed : null,
        hoverColor: hover,
        splashColor: hover,
        highlightColor: hover,
        focusColor: AppColors.primary.withValues(alpha: 0.25),
        child: SizedBox(
          height: height,
          width: widget.fullWidth ? double.infinity : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Row(
              mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[leading, const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyMedium.copyWith(
                      color: foreground,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      child: Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed && widget.variant != AppButtonVariant.ghost ? 0.98 : 1,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Opacity(
            opacity: widget.onPressed == null ? 0.5 : 1,
            child: button,
          ),
        ),
      ),
    );
  }
}
