import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../../shared/widgets/layout/admin_scaffold.dart';
import '../../../shared/widgets/layout/page_toolbar.dart';
import '../controllers/payments_controller.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AdminScaffold(
      route: AppRoutes.payments,
      title: 'المدفوعات',
      body: GetBuilder<PaymentsController>(
        builder: (ctrl) {
          if (ctrl.isLoading) return const AppLoader();
          if (ctrl.error != null) return AppErrorState(message: ctrl.error!);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageToolbar(
                  title: 'بوابات الدفع',
                  subtitle:
                      'ميسر للتطبيق مباشرة بمفتاح Publishable — Tap عبر goSell + Cloud Functions. الأسرار في private_settings فقط.',
                  actions: [
                    AppButton(
                      label: 'حفظ',
                      isLoading: ctrl.isSaving,
                      onPressed: ctrl.save,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  title: 'الوضع المشترك',
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text('وضع التجربة (Sandbox / Test)', style: AppTextStyles.body1.copyWith(color: c.textPrimary)),
                    subtitle: Text(
                      'عند الإيقاف تُستخدم مفاتيح Live لكلا البوابتين',
                      style: AppTextStyles.caption.copyWith(color: c.textSecondary),
                    ),
                    value: ctrl.config.isSandboxMode,
                    onChanged: (v) => ctrl.patchConfig(ctrl.config.copyWith(isSandboxMode: v)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  title: 'ميسر (Moyasar) — مُفضّل للتجربة',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text('تفعيل ميسر في التطبيق', style: AppTextStyles.body1.copyWith(color: c.textPrimary)),
                        subtitle: Text(
                          'من dashboard.moyasar.com — مفتاح Publishable فقط في التطبيق',
                          style: AppTextStyles.caption.copyWith(color: c.textSecondary),
                        ),
                        value: ctrl.config.isMoyasarEnabled,
                        onChanged: (v) => ctrl.patchConfig(ctrl.config.copyWith(isMoyasarEnabled: v)),
                      ),
                      _field(
                        label: 'Moyasar Publishable Key (Test / pk_test_...)',
                        value: ctrl.config.moyasarPublishableKeyTest,
                        onChanged: (v) =>
                            ctrl.patchConfig(ctrl.config.copyWith(moyasarPublishableKeyTest: v)),
                      ),
                      _field(
                        label: 'Moyasar Publishable Key (Live / pk_live_...)',
                        value: ctrl.config.moyasarPublishableKeyLive,
                        onChanged: (v) =>
                            ctrl.patchConfig(ctrl.config.copyWith(moyasarPublishableKeyLive: v)),
                      ),
                      _field(
                        label: 'Moyasar Apple Pay Merchant ID (اختياري)',
                        value: ctrl.config.moyasarApplePayMerchantId,
                        onChanged: (v) =>
                            ctrl.patchConfig(ctrl.config.copyWith(moyasarApplePayMerchantId: v)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Secret Keys (تحقق من الدفع عبر Cloud Function فقط)',
                        style: AppTextStyles.h6.copyWith(color: c.textPrimary),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _field(
                        label: 'Moyasar Secret Key Test (sk_test_...)',
                        value: ctrl.secrets.moyasarSecretKeyTest,
                        obscure: true,
                        onChanged: (v) =>
                            ctrl.patchSecrets(ctrl.secrets.copyWith(moyasarSecretKeyTest: v)),
                      ),
                      _field(
                        label: 'Moyasar Secret Key Live (sk_live_...)',
                        value: ctrl.secrets.moyasarSecretKeyLive,
                        obscure: true,
                        onChanged: (v) =>
                            ctrl.patchSecrets(ctrl.secrets.copyWith(moyasarSecretKeyLive: v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  title: 'العملة والإعدادات العامة',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              label: 'Currency',
                              value: ctrl.config.currency,
                              onChanged: (v) =>
                                  ctrl.patchConfig(ctrl.config.copyWith(currency: v.toUpperCase())),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _field(
                              label: 'Country Code',
                              value: ctrl.config.countryCode,
                              onChanged: (v) =>
                                  ctrl.patchConfig(ctrl.config.copyWith(countryCode: v.toUpperCase())),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: c.error.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: c.error.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    'Tap / goSell (خطأ 2104):\n'
                    'مفاتيح لوحة Tap غالباً لا تعمل وحدها على الموبايل. سجّل Package عند دعم Tap:\n'
                    'Android: ${ctrl.config.androidBundleId.isEmpty ? 'com.multiTest.app24' : ctrl.config.androidBundleId}\n'
                    'iOS: ${ctrl.config.iosBundleId.isEmpty ? 'com.thehatch-store.app' : ctrl.config.iosBundleId}',
                    style: AppTextStyles.body2.copyWith(color: c.textPrimary, height: 1.45),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  title: 'Tap Payments',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text('تفعيل Tap في التطبيق', style: AppTextStyles.body1.copyWith(color: c.textPrimary)),
                        value: ctrl.config.isTapEnabled,
                        onChanged: (v) => ctrl.patchConfig(ctrl.config.copyWith(isTapEnabled: v)),
                      ),
                      _field(
                        label: 'Publishable Key (Test)',
                        value: ctrl.config.publishableKeyTest,
                        onChanged: (v) => ctrl.patchConfig(ctrl.config.copyWith(publishableKeyTest: v)),
                      ),
                      _field(
                        label: 'Publishable Key (Live)',
                        value: ctrl.config.publishableKeyLive,
                        onChanged: (v) => ctrl.patchConfig(ctrl.config.copyWith(publishableKeyLive: v)),
                      ),
                      _field(
                        label: 'Merchant ID (مطلوب — من لوحة Tap)',
                        value: ctrl.config.merchantId,
                        onChanged: (v) => ctrl.patchConfig(ctrl.config.copyWith(merchantId: v)),
                      ),
                      _field(
                        label: 'Apple Pay Merchant ID',
                        value: ctrl.config.applePayMerchantId,
                        onChanged: (v) => ctrl.patchConfig(ctrl.config.copyWith(applePayMerchantId: v)),
                      ),
                      _field(
                        label: 'Android Bundle / Application ID',
                        value: ctrl.config.androidBundleId,
                        onChanged: (v) => ctrl.patchConfig(ctrl.config.copyWith(androidBundleId: v)),
                      ),
                      _field(
                        label: 'iOS Bundle ID',
                        value: ctrl.config.iosBundleId,
                        onChanged: (v) => ctrl.patchConfig(ctrl.config.copyWith(iosBundleId: v)),
                      ),
                      _field(
                        label: 'Webhook URL (tapWebhook Cloud Function)',
                        value: ctrl.config.webhookUrl,
                        onChanged: (v) => ctrl.patchConfig(ctrl.config.copyWith(webhookUrl: v)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('وسائل الدفع المدعومة (Tap)', style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: PaymentsController.methodOptions.map((m) {
                          final selected = ctrl.config.supportedMethods.contains(m);
                          return FilterChip(
                            label: Text(m),
                            selected: selected,
                            onSelected: (_) => ctrl.toggleMethod(m),
                            selectedColor: c.primary.withValues(alpha: 0.15),
                            side: BorderSide(color: selected ? c.primary : c.border),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('مفاتيح Tap السرية', style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
                      const SizedBox(height: AppSpacing.sm),
                      _field(
                        label: 'Secret Key Test (مشترك / sk_test_...)',
                        value: ctrl.secrets.secretKeyTest,
                        obscure: true,
                        onChanged: (v) => ctrl.patchSecrets(ctrl.secrets.copyWith(secretKeyTest: v)),
                      ),
                      _field(
                        label: 'Secret Key Live (مشترك / sk_live_...)',
                        value: ctrl.secrets.secretKeyLive,
                        obscure: true,
                        onChanged: (v) => ctrl.patchSecrets(ctrl.secrets.copyWith(secretKeyLive: v)),
                      ),
                      _field(
                        label: 'Secret Key Test Android (من دعم Tap)',
                        value: ctrl.secrets.secretKeyTestAndroid,
                        obscure: true,
                        onChanged: (v) =>
                            ctrl.patchSecrets(ctrl.secrets.copyWith(secretKeyTestAndroid: v)),
                      ),
                      _field(
                        label: 'Secret Key Live Android',
                        value: ctrl.secrets.secretKeyLiveAndroid,
                        obscure: true,
                        onChanged: (v) =>
                            ctrl.patchSecrets(ctrl.secrets.copyWith(secretKeyLiveAndroid: v)),
                      ),
                      _field(
                        label: 'Secret Key Test iOS (من دعم Tap)',
                        value: ctrl.secrets.secretKeyTestIos,
                        obscure: true,
                        onChanged: (v) => ctrl.patchSecrets(ctrl.secrets.copyWith(secretKeyTestIos: v)),
                      ),
                      _field(
                        label: 'Secret Key Live iOS',
                        value: ctrl.secrets.secretKeyLiveIos,
                        obscure: true,
                        onChanged: (v) => ctrl.patchSecrets(ctrl.secrets.copyWith(secretKeyLiveIos: v)),
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

  Widget _field({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        initialValue: value,
        obscureText: obscure,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
