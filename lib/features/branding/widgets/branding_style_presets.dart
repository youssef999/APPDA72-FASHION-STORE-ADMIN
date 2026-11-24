import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/branding_controller.dart';
import '../models/branding_presets.dart';

/// One-tap fashion looks for APPDA 72 merchants.
class BrandingStylePresets extends StatelessWidget {
  const BrandingStylePresets({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GetBuilder<BrandingController>(
      id: BrandingController.formId,
      builder: (ctrl) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ستايلات فاشون جاهزة', style: AppTextStyles.h5.copyWith(color: c.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '٣ هويات بصرية مصممة لمتاجر الموضة — اضغط لتطبيقها فوراً ثم احفظ',
              style: AppTextStyles.caption.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                final cards = [
                  for (final preset in BrandingStylePreset.fashion)
                    _StyleCard(
                      preset: preset,
                      selected: ctrl.activePresetId == preset.id,
                      onApply: () => ctrl.applyPreset(preset),
                    ),
                ];
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.md),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.md),
                      cards[i],
                    ],
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _StyleCard extends StatelessWidget {
  final BrandingStylePreset preset;
  final bool selected;
  final VoidCallback onApply;

  const _StyleCard({
    required this.preset,
    required this.selected,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = preset.style;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onApply,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? c.secondary : c.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  height: 72,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: s.backgroundColor),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                s.primaryColor,
                                Color.lerp(s.primaryColor, s.accentColor, 0.4) ?? s.primaryColor,
                              ],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            preset.titleEn.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: s.bannerTextColor,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: s.buttonColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'SHOP',
                            style: AppTextStyles.caption.copyWith(
                              color: s.buttonTextColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Row(
                          children: [
                            _Swatch(s.primaryColor),
                            const SizedBox(width: 4),
                            _Swatch(s.accentColor),
                            const SizedBox(width: 4),
                            _Swatch(s.backgroundColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              Text(preset.titleAr, style: AppTextStyles.h6.copyWith(color: c.textPrimary)),
              const SizedBox(height: 4),
              Text(preset.subtitleAr, style: AppTextStyles.caption.copyWith(color: c.textSecondary)),
              const SizedBox(height: 6),
              Text(preset.bestForAr, style: AppTextStyles.caption.copyWith(color: c.secondary, height: 1.35)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                selected ? 'مُطبَّق — احفظ لتفعيل التطبيق' : 'تطبيق الستايل',
                style: AppTextStyles.caption.copyWith(
                  color: selected ? c.success : c.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  const _Swatch(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black26, width: 0.8),
      ),
    );
  }
}
