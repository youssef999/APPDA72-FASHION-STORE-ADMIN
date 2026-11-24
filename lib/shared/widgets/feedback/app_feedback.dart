import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../buttons/app_button.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  const AppEmptyState({super.key, required this.icon, required this.title, this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.secondary.withValues(alpha: 0.1),
                border: Border.all(color: c.secondary.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: c.secondary, size: AppIconSize.xl),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTextStyles.h5.copyWith(color: c.textPrimary)),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(message!, textAlign: TextAlign.center, style: AppTextStyles.body2.copyWith(color: c.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  final String message;

  const AppErrorState({super.key, required this.message});

  @override
  Widget build(BuildContext context) =>
      AppEmptyState(icon: Icons.cloud_off_rounded, title: 'تعذر تحميل البيانات', message: message);
}

enum AppSnackbarType { success, error, info }

class AppSnackbar {
  AppSnackbar._();

  static void show(String message, {AppSnackbarType type = AppSnackbarType.success}) {
    final context = Get.context;
    if (context == null) return;
    final c = context.colors;
    final (Color tint, IconData icon) = switch (type) {
      AppSnackbarType.success => (c.success, Icons.check_circle_outline_rounded),
      AppSnackbarType.error => (c.error, Icons.error_outline_rounded),
      AppSnackbarType.info => (c.secondary, Icons.info_outline_rounded),
    };
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 420,
        backgroundColor: AppColors.light.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        content: Row(
          children: [
            Icon(icon, color: tint, size: AppIconSize.md),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message, style: AppTextStyles.body2.copyWith(color: Colors.white))),
          ],
        ),
      ));
  }
}

class AppConfirmDialog {
  AppConfirmDialog._();

  static Future<bool> show({
    required String title,
    required String message,
    String confirmLabel = 'تأكيد',
    bool isDanger = false,
  }) async {
    final result = await Get.dialog<bool>(
      Builder(builder: (context) {
        final c = context.colors;
        return AlertDialog(
          title: Text(title, style: AppTextStyles.h4.copyWith(color: c.textPrimary)),
          content: Text(message, style: AppTextStyles.body1.copyWith(color: c.textSecondary)),
          actionsPadding: const EdgeInsets.all(AppSpacing.md),
          actions: [
            AppButton(
              label: 'إلغاء',
              variant: AppButtonVariant.outlined,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            AppButton(
              label: confirmLabel,
              variant: isDanger ? AppButtonVariant.danger : AppButtonVariant.primary,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      }),
    );
    return result ?? false;
  }
}
