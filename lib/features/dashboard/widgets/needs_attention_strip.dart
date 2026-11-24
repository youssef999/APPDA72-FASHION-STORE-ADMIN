import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../orders/controllers/orders_controller.dart';
import '../../orders/models/order_model.dart';
import '../controllers/dashboard_controller.dart';
import '../repositories/dashboard_repository.dart';

/// Action strip for waiting orders + low stock — placed above dashboard stats.
class NeedsAttentionStrip extends StatelessWidget {
  const NeedsAttentionStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GetBuilder<OrdersController>(
      builder: (orders) => GetBuilder<DashboardController>(
        builder: (dashboard) {
          final waiting = orders.countFor(OrderStatus.waiting);
          final lowStock = dashboard.counts?.lowStock ?? 0;
          final loading = orders.isLoading || dashboard.isLoading;
          if (!loading && waiting == 0 && lowStock == 0) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('يحتاج انتباهك', style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _AttentionChip(
                    icon: AppIcons.pending,
                    label: loading ? '…' : '$waiting طلب بانتظار المراجعة',
                    tint: c.warning,
                    onTap: () => Get.offAllNamed(AppRoutes.orders),
                  ),
                  _AttentionChip(
                    icon: AppIcons.stock,
                    label: loading
                        ? '…'
                        : '$lowStock منتج بمخزون ≤ ${DashboardRepository.lowStockLimit}',
                    tint: c.error,
                    onTap: () => Get.offAllNamed(AppRoutes.products),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          );
        },
      ),
    );
  }
}

class _AttentionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  const _AttentionChip({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: tint.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIconSize.sm, color: tint),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: AppTextStyles.body2.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.chevron_left_rounded, size: AppIconSize.sm, color: tint),
            ],
          ),
        ),
      ),
    );
  }
}
