import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/shell/controllers/shell_controller.dart';
import '../buttons/app_button.dart';

class TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onMenu;

  const TopBar({super.key, required this.title, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shell = Get.find<ShellController>();
    final auth = Get.find<AuthController>();
    final isMobile = Breakpoints.isMobile(context);
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          AppIconButton(icon: AppIcons.menu, onPressed: onMenu, tooltip: 'القائمة'),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h4.copyWith(color: c.textPrimary)),
          ),
          if (!isMobile) ...[
            Text(auth.adminEmail, style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
            const SizedBox(width: AppSpacing.md),
          ],
          AppIconButton(
            icon: shell.isDark ? AppIcons.lightMode : AppIcons.darkMode,
            tooltip: 'تغيير الوضع',
            onPressed: shell.toggleTheme,
          ),
          const SizedBox(width: AppSpacing.sm),
          AppIconButton(
            icon: AppIcons.logout,
            tooltip: 'تسجيل الخروج',
            color: c.error,
            onPressed: auth.signOut,
          ),
        ],
      ),
    );
  }
}
