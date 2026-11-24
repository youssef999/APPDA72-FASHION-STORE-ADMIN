import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../controllers/coupons_controller.dart';
import '../models/coupon_model.dart';

/// Table rows on tablet/desktop, stacked cards on mobile.
class CouponsList extends StatelessWidget {
  final List<CouponModel> coupons;

  const CouponsList({super.key, required this.coupons});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return ListView.separated(
      itemCount: coupons.length + (isMobile ? 0 : 1),
      separatorBuilder: (_, __) => SizedBox(height: isMobile ? AppSpacing.sm + 4 : 0),
      itemBuilder: (context, index) {
        if (!isMobile && index == 0) return const _HeaderRow();
        final coupon = coupons[isMobile ? index : index - 1];
        return isMobile ? _CouponCard(coupon: coupon) : _CouponRow(coupon: coupon);
      },
    );
  }
}

class CouponStatusChip extends StatelessWidget {
  final CouponStatus status;

  const CouponStatusChip({super.key, required this.status});

  static String label(CouponStatus status) => switch (status) {
        CouponStatus.active => 'فعّال',
        CouponStatus.expired => 'منتهي',
        CouponStatus.used => 'مُستخدم',
        CouponStatus.disabled => 'موقوف',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Color tint = switch (status) {
      CouponStatus.active => c.success,
      CouponStatus.expired => c.textDisabled,
      CouponStatus.used => c.info,
      CouponStatus.disabled => c.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: 2),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label(status), style: AppTextStyles.caption.copyWith(color: tint)),
    );
  }
}

String _recipient(CouponModel coupon) {
  if (coupon.isPublic) return 'كل المستخدمين';
  if (coupon.targetName.isNotEmpty) return coupon.targetName;
  return coupon.targetEmail.isEmpty ? 'مستخدم واحد' : coupon.targetEmail;
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.caption.copyWith(color: context.colors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('الكود', style: style)),
          Expanded(flex: 2, child: Text('الخصم', style: style)),
          Expanded(flex: 3, child: Text('المستفيد', style: style)),
          Expanded(flex: 2, child: Text('ينتهي في', style: style)),
          Expanded(flex: 1, child: Text('الاستخدام', style: style)),
          Expanded(flex: 2, child: Text('الحالة', style: style)),
          const SizedBox(width: 128),
        ],
      ),
    );
  }
}

class _CouponRow extends StatelessWidget {
  final CouponModel coupon;

  const _CouponRow({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.divider))),
      child: Row(
        children: [
          Expanded(flex: 3, child: SelectableText(coupon.code, style: AppTextStyles.h6.copyWith(color: c.textPrimary, letterSpacing: 1))),
          Expanded(flex: 2, child: Text(coupon.valueLabel, style: AppTextStyles.h6.copyWith(color: c.secondary))),
          Expanded(
            flex: 3,
            child: Text(
              coupon.isInfluencer
                  ? '${coupon.influencerDisplay} · ${_recipient(coupon)}'
                  : _recipient(coupon),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body2.copyWith(color: c.textPrimary),
            ),
          ),
          Expanded(flex: 2, child: Text(Formatters.date(coupon.expiresAt), style: AppTextStyles.body2.copyWith(color: c.textSecondary))),
          Expanded(flex: 1, child: Text('${coupon.usedCount}', style: AppTextStyles.body2.copyWith(color: c.textPrimary))),
          Expanded(flex: 2, child: Align(alignment: AlignmentDirectional.centerStart, child: CouponStatusChip(status: coupon.status))),
          _CouponActions(coupon: coupon),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final CouponModel coupon;

  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: SelectableText(coupon.code, style: AppTextStyles.h5.copyWith(color: c.textPrimary, letterSpacing: 1))),
              CouponStatusChip(status: coupon.status),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('خصم ${coupon.valueLabel} • ${_recipient(coupon)}', style: AppTextStyles.body2.copyWith(color: c.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  'ينتهي ${Formatters.date(coupon.expiresAt)} • استُخدم ${coupon.usedCount} مرة',
                  style: AppTextStyles.caption.copyWith(color: c.textSecondary),
                ),
              ),
              _CouponActions(coupon: coupon),
            ],
          ),
        ],
      ),
    );
  }
}

class _CouponActions extends StatelessWidget {
  final CouponModel coupon;

  const _CouponActions({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final controller = Get.find<CouponsController>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (coupon.isInfluencer) ...[
          AppIconButton(
            icon: AppIcons.analytics,
            tooltip: 'تقرير الحملة',
            onPressed: () => controller.openInfluencerReport(coupon),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        AppIconButton(
          icon: coupon.active ? AppIcons.pause : AppIcons.play,
          tooltip: coupon.active ? 'إيقاف' : 'تفعيل',
          onPressed: () => controller.toggleActive(coupon),
        ),
        const SizedBox(width: AppSpacing.xs),
        AppIconButton(icon: AppIcons.delete, tooltip: 'حذف', color: c.error, onPressed: () => controller.delete(coupon)),
      ],
    );
  }
}
