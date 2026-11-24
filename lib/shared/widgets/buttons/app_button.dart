import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, outlined, danger, ghost }

/// The dashboard's only button; [isLoading] swaps the label for a spinner.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool expanded;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (Color background, Color foreground, Color borderColor) = switch (variant) {
      AppButtonVariant.primary => (c.primary, c.onPrimary, c.primary),
      AppButtonVariant.outlined => (Colors.transparent, c.textPrimary, c.border),
      AppButtonVariant.danger => (c.error, Colors.white, c.error),
      AppButtonVariant.ghost => (Colors.transparent, c.secondary, Colors.transparent),
    };

    final Widget content = isLoading
        ? SizedBox(
            width: AppIconSize.md,
            height: AppIconSize.md,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppIconSize.md, color: foreground),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: AppTextStyles.button.copyWith(color: foreground)),
            ],
          );

    final button = Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Opacity(
          opacity: onPressed == null ? 0.5 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
            child: Center(widthFactor: 1, child: content),
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Square icon-only button for table rows and toolbars.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;

  const AppIconButton({super.key, required this.icon, required this.onPressed, this.tooltip, this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final button = Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(color: c.border),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(icon, size: AppIconSize.md, color: color ?? c.textPrimary),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
