import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../controllers/branding_controller.dart';
import '../widgets/branding_form.dart';
import '../widgets/branding_preview.dart';

class BrandingPage extends StatelessWidget {
  const BrandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      route: AppRoutes.branding,
      title: 'الهوية البصرية',
      body: GetBuilder<BrandingController>(
        builder: (controller) {
          if (controller.isLoading) return const AppLoader();
          if (controller.error != null) return AppErrorState(message: controller.error!);
          return Breakpoints.isDesktop(context) ? _desktop() : _stacked();
        },
      ),
    );
  }

  Widget _desktop() => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageToolbar(
              title: 'الهوية البصرية',
              subtitle: 'شعار · ألوان · خطوط — تظهر فوراً في التطبيق',
              actions: [
                AppButton(
                  label: 'إعدادات المتجر',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => Get.offAllNamed(AppRoutes.storeSettings),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: AppCard(
                      expand: true,
                      child: SingleChildScrollView(child: BrandingForm()),
                    ),
                  ),
                  SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 4,
                    child: AppCard(
                      title: 'معاينة مباشرة',
                      child: BrandingPreview(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _stacked() => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageToolbar(
              title: 'الهوية البصرية',
              subtitle: 'شعار · ألوان · خطوط — تظهر فوراً في التطبيق',
              actions: [
                AppButton(
                  label: 'إعدادات المتجر',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => Get.offAllNamed(AppRoutes.storeSettings),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppCard(child: BrandingForm()),
            const SizedBox(height: AppSpacing.lg),
            const AppCard(title: 'معاينة مباشرة', child: BrandingPreview()),
          ],
        ),
      );
}
