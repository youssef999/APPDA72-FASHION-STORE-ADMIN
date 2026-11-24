import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/constants/firestore_collections.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/cards/app_card.dart';

/// First-run checklist so a non-engineer merchant knows what to do next.
class MerchantSetupChecklist extends StatefulWidget {
  const MerchantSetupChecklist({super.key});

  @override
  State<MerchantSetupChecklist> createState() => _MerchantSetupChecklistState();
}

class _MerchantSetupChecklistState extends State<MerchantSetupChecklist> {
  static const _dismissKey = 'merchant_setup_dismissed_v1';

  bool _loading = true;
  bool _dismissed = false;
  bool _hasCategories = false;
  bool _hasProducts = false;
  bool _hasWhatsApp = false;
  bool _hasBranding = false;

  @override
  void initState() {
    super.initState();
    _dismissed = GetStorage().read(_dismissKey) == true;
    if (!_dismissed) _load();
  }

  Future<void> _load() async {
    try {
      final db = FirebaseFirestore.instance;
      final cats = await db.collection(FirestoreCollections.categories).limit(1).get();
      final products = await db.collection(FirestoreCollections.products).limit(1).get();
      final appSnap =
          await db.collection(FirestoreCollections.config).doc(FirestoreCollections.configApp).get();
      final brandingSnap = await db.collection(FirestoreCollections.config).doc('branding').get();
      final app = appSnap.data() ?? {};
      final branding = brandingSnap.data() ?? {};
      if (!mounted) return;
      setState(() {
        _hasCategories = cats.docs.isNotEmpty;
        _hasProducts = products.docs.isNotEmpty;
        _hasWhatsApp = '${app['whatsappPhone'] ?? ''}'.trim().isNotEmpty;
        _hasBranding = '${branding['logoUrl'] ?? ''}'.trim().isNotEmpty ||
            '${branding['brandName'] ?? ''}'.trim().isNotEmpty;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _dismiss() {
    GetStorage().write(_dismissKey, true);
    setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    if (_loading) return const SizedBox.shrink();

    final steps = <_Step>[
      _Step('أنشئ قسمًا', 'مثل عبايات أو فساتين', _hasCategories, AppRoutes.categories),
      _Step('أضف أول منتج', 'أو استخدم الاستيراد الجماعي من المنتجات', _hasProducts, AppRoutes.products),
      _Step('اضبط إعدادات المتجر', 'شحن · واتساب الطلبات', _hasWhatsApp, AppRoutes.storeSettings),
      _Step('ارفع شعار الهوية', 'من الهوية البصرية', _hasBranding, AppRoutes.branding),
    ];
    final pending = steps.where((s) => !s.done).toList();
    if (pending.isEmpty) return const SizedBox.shrink();

    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        title: 'ابدأ متجرك في 4 خطوات',
        trailing: AppButton(
          label: 'إخفاء',
          variant: AppButtonVariant.ghost,
          onPressed: _dismiss,
        ),
        child: Column(
          children: [
            for (final step in steps)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  step.done ? Icons.check_circle_rounded : AppIcons.pending,
                  color: step.done ? c.success : c.textSecondary,
                ),
                title: Text(step.title, style: AppTextStyles.body1.copyWith(color: c.textPrimary)),
                subtitle: Text(step.subtitle, style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
                trailing: step.done
                    ? null
                    : TextButton(
                        onPressed: () => Get.offAllNamed(step.route),
                        child: const Text('ابدأ'),
                      ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.light.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'متبقي ${pending.length} من ${steps.length} — اللوحة جاهزة لما تخلّص الخطوات دي',
                style: AppTextStyles.caption.copyWith(color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step {
  final String title;
  final String subtitle;
  final bool done;
  final String route;

  const _Step(this.title, this.subtitle, this.done, this.route);
}
