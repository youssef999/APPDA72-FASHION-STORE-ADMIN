import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../controllers/notifications_controller.dart';
import '../models/notification_model.dart';

/// Latest notifications, both manual ones and the automatic order-status updates.
class NotificationsHistory extends StatelessWidget {
  final bool shrinkWrap;

  const NotificationsHistory({super.key, this.shrinkWrap = false});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NotificationsController>(
      builder: (controller) {
        if (controller.isLoading) return const AppLoader();
        if (controller.error != null) return AppErrorState(message: controller.error!);
        if (controller.history.isEmpty) {
          return const AppEmptyState(icon: AppIcons.notifications, title: 'لم يتم إرسال إشعارات بعد');
        }
        return ListView.separated(
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
          itemCount: controller.history.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => _NotificationTile(notification: controller.history[index]),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isOrder = notification.type == 'order_status';
    final audienceLabel = notification.isBroadcast
        ? 'كل المستخدمين'
        : (notification.targetEmail.isEmpty ? 'مستخدم واحد' : notification.targetEmail);
    final (String audience, Color tint, IconData icon) = notification.type == 'coupon'
        ? ('كوبون • $audienceLabel', c.warning, AppIcons.coupon)
        : notification.isBroadcast
            ? (audienceLabel, c.secondary, AppIcons.users)
            : isOrder
                ? ('طلب #${notification.orderId}', c.info, AppIcons.orders)
                : (audienceLabel, c.success, AppIcons.email);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Icon(icon, color: tint, size: AppIconSize.md),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.titleAr.isEmpty ? notification.title : notification.titleAr,
                    style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
                const SizedBox(height: 2),
                Text(notification.bodyAr.isEmpty ? notification.body : notification.bodyAr,
                    style: AppTextStyles.body2.copyWith(color: c.textSecondary)),
                const SizedBox(height: AppSpacing.xs),
                Text('$audience • ${Formatters.dateTime(notification.createdAt)}',
                    style: AppTextStyles.caption.copyWith(color: tint)),
              ],
            ),
          ),
          AppIconButton(
            icon: AppIcons.delete,
            tooltip: 'حذف',
            color: c.error,
            onPressed: () => Get.find<NotificationsController>().delete(notification),
          ),
        ],
      ),
    );
  }
}
