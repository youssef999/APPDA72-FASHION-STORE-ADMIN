import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/inputs/app_dropdown.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../controllers/coupons_controller.dart';
import '../models/coupon_model.dart';

class CouponFormDialog extends StatelessWidget {
  const CouponFormDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: GetBuilder<CouponsController>(
            id: CouponsController.formId,
            builder: (controller) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('كوبون جديد', style: AppTextStyles.h4.copyWith(color: c.textPrimary)),
                const SizedBox(height: AppSpacing.xs),
                Text('يُستخدم مرة واحدة لكل عميل، وينتهي في التاريخ المحدد',
                    style: AppTextStyles.body2.copyWith(color: c.textSecondary)),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'كود الكوبون',
                        controller: controller.codeController,
                        icon: AppIcons.coupon,
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: AppIconButton(icon: AppIcons.generate, tooltip: 'كود عشوائي', onPressed: controller.generateCode),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('نوع الخصم', style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                const SizedBox(height: AppSpacing.xs + 2),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: CouponModel.percent, label: Text('نسبة %')),
                    ButtonSegment(value: CouponModel.fixed, label: Text('مبلغ ثابت ${Formatters.currency}')),
                  ],
                  selected: {controller.type},
                  onSelectionChanged: (selection) => controller.setType(selection.first),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: controller.type == CouponModel.percent ? 'نسبة الخصم (1 - 100)' : 'قيمة الخصم',
                  controller: controller.valueController,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: AppSpacing.md),
                _ExpiryField(controller: controller),
                const SizedBox(height: AppSpacing.md),
                _RecipientField(controller: controller),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('حملة مشهورة', style: AppTextStyles.body1.copyWith(color: c.textPrimary)),
                  subtitle: Text('تتبّع الاستردادات والمبيعات التقريبية', style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                  value: controller.isInfluencerCampaign,
                  onChanged: controller.setInfluencerCampaign,
                ),
                if (controller.isInfluencerCampaign) ...[
                  AppTextField(
                    label: 'اسم المشهورة (EN)',
                    controller: controller.influencerNameController,
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'اسم المشهورة (AR)',
                    controller: controller.influencerNameArController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('نافذة الإسناد (أيام)', style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                  const SizedBox(height: AppSpacing.xs),
                  SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 3, label: Text('3')),
                      ButtonSegment(value: 7, label: Text('7')),
                      ButtonSegment(value: 14, label: Text('14')),
                      ButtonSegment(value: 30, label: Text('30')),
                    ],
                    selected: {controller.attributionWindowDays},
                    onSelectionChanged: (s) => controller.setAttributionWindowDays(s.first),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(label: 'إلغاء', variant: AppButtonVariant.outlined, onPressed: () => Navigator.of(context).pop()),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(label: 'إنشاء وإرسال', icon: AppIcons.send, isLoading: controller.isSaving, onPressed: controller.save),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpiryField extends StatelessWidget {
  final CouponsController controller;

  const _ExpiryField({required this.controller});

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.expiresAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) controller.setExpiry(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final expiry = controller.expiresAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('تاريخ الانتهاء', style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.xs + 2),
        InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 6),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Icon(AppIcons.calendar, size: AppIconSize.md, color: c.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    expiry == null ? 'اختر التاريخ' : 'حتى نهاية يوم ${Formatters.date(expiry)}',
                    style: AppTextStyles.body1.copyWith(color: c.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecipientField extends StatelessWidget {
  final CouponsController controller;

  const _RecipientField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final recipient = controller.recipient;
    final items = <AppDropdownItem<String?>>[
      const AppDropdownItem(null, 'كل المستخدمين'),
      if (recipient != null && !controller.users.any((u) => u.uid == recipient.uid))
        AppDropdownItem(recipient.uid, '${recipient.name} • ${recipient.email}'),
      ...controller.users
          .where((u) => u.uid.isNotEmpty)
          .map((u) => AppDropdownItem<String?>(u.uid, u.email.isEmpty ? u.displayName : '${u.displayName} • ${u.email}')),
    ];
    return AppDropdown<String?>(
      label: 'المستفيد',
      value: recipient?.uid,
      items: items,
      onChanged: controller.setRecipient,
    );
  }
}
