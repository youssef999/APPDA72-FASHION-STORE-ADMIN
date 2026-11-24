import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../controllers/seasonal_controller.dart';

class SeasonalPage extends StatelessWidget {
  const SeasonalPage({super.key});

  static const _options = [
    _SeasonOption('none', 'بدون موسم', Icons.block_rounded, Color(0xFF6B7280)),
    _SeasonOption('ramadan', 'رمضان', Icons.nightlight_round, Color(0xFFC9A227)),
    _SeasonOption('eid', 'العيد', Icons.celebration_outlined, Color(0xFFB08D57)),
    _SeasonOption('national', 'اليوم الوطني', Icons.flag_outlined, Color(0xFF165A3F)),
    _SeasonOption('whiteFriday', 'الجمعة البيضاء', Icons.local_offer_outlined, Color(0xFF1C1B1F)),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AdminScaffold(
      route: AppRoutes.seasonal,
      title: 'الموسم',
      body: GetBuilder<SeasonalAdminController>(
        builder: (controller) {
          if (controller.isLoading) return const AppLoader();
          if (controller.error != null) return AppErrorState(message: controller.error!);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageToolbar(
                  title: 'تفعيل الموسم بضغطة',
                  subtitle: 'يظهر شريط ترحيب وإطار عروض في تطبيق المتجر فوراً عبر Firestore',
                ),
                const SizedBox(height: AppSpacing.lg),
                if (controller.success != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(controller.success!, style: AppTextStyles.body2.copyWith(color: c.success)),
                  ),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: _options.map((opt) {
                    final selected = controller.active == opt.key;
                    return InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      onTap: controller.isSaving ? null : () => controller.activate(opt.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 200,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: selected ? opt.color.withValues(alpha: 0.12) : c.card,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: selected ? opt.color : c.border,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(opt.icon, color: opt.color),
                            const SizedBox(height: AppSpacing.sm),
                            Text(opt.label, style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
                            const SizedBox(height: 4),
                            Text(
                              selected ? 'مفعّل الآن' : 'اضغط للتفعيل',
                              style: AppTextStyles.caption.copyWith(
                                color: selected ? opt.color : c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('نص الشريط (اختياري)', style: AppTextStyles.h5.copyWith(color: c.textPrimary)),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  initialValue: controller.bannerTitleAr,
                  onChanged: controller.setBannerAr,
                  decoration: const InputDecoration(
                    labelText: 'العنوان بالعربي',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  initialValue: controller.bannerTitleEn,
                  onChanged: controller.setBannerEn,
                  decoration: const InputDecoration(
                    labelText: 'Title in English',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: controller.isSaving ? null : controller.saveTitles,
                    child: controller.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('حفظ النصوص'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SeasonOption {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const _SeasonOption(this.key, this.label, this.icon, this.color);
}
