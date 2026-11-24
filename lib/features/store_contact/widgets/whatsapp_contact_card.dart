import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../controllers/store_contact_controller.dart';

/// Admin control for Firestore `config/app.whatsappPhone`.
class WhatsAppContactCard extends StatelessWidget {
  const WhatsAppContactCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GetBuilder<StoreContactController>(
      id: StoreContactController.formId,
      builder: (ctrl) {
        if (ctrl.isLoading) {
          return const AppCard(
            title: 'واتساب المتجر',
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: AppLoader()),
            ),
          );
        }
        if (ctrl.error != null) {
          return AppCard(
            title: 'واتساب المتجر',
            child: AppErrorState(message: ctrl.error!),
          );
        }
        return AppCard(
          title: 'واتساب المتجر',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'رقم الطلب السريع في التطبيق (Firestore: config/app.whatsappPhone). '
                'عند تسليم العميل رقمه استبدله هنا فقط — بدون تحديث التطبيق.',
                style: AppTextStyles.caption.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'رقم الواتساب (دولي)',
                controller: ctrl.phoneCtrl,
                hint: '+9665xxxxxxx',
                icon: AppIcons.phone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppButton(
                  label: 'حفظ الرقم',
                  isLoading: ctrl.isSaving,
                  onPressed: ctrl.save,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
