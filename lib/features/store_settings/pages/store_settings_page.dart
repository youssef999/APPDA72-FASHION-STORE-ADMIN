import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../controllers/store_settings_controller.dart';

/// Merchant store ops — plain Arabic, no Firestore jargon.
class StoreSettingsPage extends StatelessWidget {
  const StoreSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AdminScaffold(
      route: AppRoutes.storeSettings,
      title: 'إعدادات المتجر',
      body: GetBuilder<StoreSettingsController>(
        builder: (ctrl) {
          if (ctrl.isLoading) return const AppLoader();
          if (ctrl.error != null) return AppErrorState(message: ctrl.error!);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageToolbar(
                  title: 'إعدادات المتجر',
                  subtitle: 'الشحن · المكافآت · رقم واتساب الطلبات — بالريال السعودي',
                  actions: [
                    AppButton(
                      label: 'حفظ الإعدادات',
                      isLoading: ctrl.isSaving,
                      onPressed: ctrl.save,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  title: 'الشحن والتوصيل',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'يظهر مباشرة في سلة التطبيق عند إتمام الطلب.',
                        style: AppTextStyles.caption.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'رسوم التوصيل (ر.س)',
                        controller: ctrl.deliveryFeeCtrl,
                        hint: '25',
                        icon: AppIcons.location,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textDirection: TextDirection.ltr,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'حد الشحن المجاني (ر.س)',
                        controller: ctrl.freeShippingCtrl,
                        hint: '300',
                        icon: AppIcons.revenue,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  title: 'مكافأة VIP',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'حافز يظهر للعميل في السلة؛ بعد عدد طلبات معيّن يصبح VIP.',
                        style: AppTextStyles.caption.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'حد هدية VIP في السلة (ر.س)',
                        controller: ctrl.vipGiftCtrl,
                        hint: '420',
                        icon: AppIcons.bestSeller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textDirection: TextDirection.ltr,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'عدد الطلبات ليصبح العميل VIP',
                        controller: ctrl.vipOrdersCtrl,
                        hint: '2',
                        icon: AppIcons.users,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  title: 'واتساب الطلبات',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'رقم يستقبله التطبيق لطلبات واتساب السريعة. غيّره لرقم العميل عند التسليم.',
                        style: AppTextStyles.caption.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'رقم الواتساب (دولي)',
                        controller: ctrl.whatsappCtrl,
                        hint: '+9665xxxxxxx',
                        icon: AppIcons.phone,
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                      ),
                    ],
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
