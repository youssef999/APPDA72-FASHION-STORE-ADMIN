import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../controllers/notifications_controller.dart';

class NotificationComposer extends StatelessWidget {
  const NotificationComposer({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NotificationsController>(
      id: NotificationsController.formId,
      builder: (controller) => AppCard(
        title: 'إشعار جديد',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RecipientBanner(controller: controller),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'العنوان (عربي)', controller: controller.titleArController),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'النص (عربي)', controller: controller.bodyArController, maxLines: 3),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Title (English) — اختياري',
              controller: controller.titleController,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Body (English) — اختياري',
              controller: controller.bodyController,
              maxLines: 3,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'إرسال الإشعار',
              icon: AppIcons.send,
              expanded: true,
              isLoading: controller.isSending,
              onPressed: controller.send,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientBanner extends StatelessWidget {
  final NotificationsController controller;

  const _RecipientBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final recipient = controller.recipient;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: c.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(recipient == null ? AppIcons.users : AppIcons.email, color: c.secondary, size: AppIconSize.md),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipient == null ? 'إلى: كل المستخدمين' : 'إلى: ${recipient.name}',
                  style: AppTextStyles.h6.copyWith(color: c.textPrimary),
                ),
                Text(
                  recipient == null ? 'لإرسال لعميل واحد اختره من صفحة المستخدمين' : recipient.email,
                  style: AppTextStyles.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          if (recipient != null)
            AppIconButton(icon: AppIcons.close, tooltip: 'إرسال للكل بدلاً من ذلك', onPressed: controller.clearRecipient),
        ],
      ),
    );
  }
}
