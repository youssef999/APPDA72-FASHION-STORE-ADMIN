import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../controllers/branding_controller.dart';
import '../models/branding_model.dart';

class BrandingPreview extends StatelessWidget {
  const BrandingPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BrandingController>(
      id: BrandingController.previewId,
      builder: (ctrl) {
        final brand = ctrl.draft;
        return Container(
          decoration: BoxDecoration(
            color: brand.backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      brand.primaryColor,
                      Color.lerp(brand.primaryColor, brand.accentColor, 0.35) ?? brand.primaryColor,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (brand.hasLogo)
                      AppNetworkImage(url: brand.logoUrl, width: 120, height: 48, radius: AppRadius.sm)
                    else
                      Text(
                        brand.brandName.toUpperCase(),
                        style: _display(brand.displayFont, 22, FontWeight.w700, brand.bannerTextColor, 3),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'نص البانر داخل التطبيق',
                      style: _body(brand.bodyFont, 13, FontWeight.w600, brand.bannerTextColor),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Icon(Icons.favorite_rounded, color: brand.iconColor, size: 22),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'عنوان العرض',
                      style: _display(brand.displayFont, 20, FontWeight.w700, brand.primaryColor, 0.5),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'نص الجسم بالعربية — تجربة تسوق أنيقة وواضحة.',
                      style: _body(brand.bodyFont, 14, FontWeight.w500, brand.primaryColor.withValues(alpha: 0.85)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
                        decoration: BoxDecoration(
                          color: brand.buttonColor,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          'زر أساسي',
                          style: _body(brand.bodyFont, 13, FontWeight.w700, brand.buttonTextColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Body: ${_label(brand.bodyFont)}  •  Display: ${_label(brand.displayFont)}',
                      style: AppTextStyles.caption.copyWith(color: context.colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _label(String key) =>
      BrandingModel.fontCatalog.firstWhere((item) => item.key == key, orElse: () => (key: key, label: key)).label;

  TextStyle _display(String key, double size, FontWeight weight, Color color, double letterSpacing) {
    final base = TextStyle(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing);
    return switch (key) {
      'cairo' => GoogleFonts.cairo(textStyle: base),
      'tajawal' => GoogleFonts.tajawal(textStyle: base),
      'almarai' => GoogleFonts.almarai(textStyle: base),
      'ibmPlexSansArabic' => GoogleFonts.ibmPlexSansArabic(textStyle: base),
      _ => GoogleFonts.playfairDisplay(textStyle: base),
    };
  }

  TextStyle _body(String key, double size, FontWeight weight, Color color) {
    final base = TextStyle(fontSize: size, fontWeight: weight, color: color, height: 1.45);
    return switch (key) {
      'tajawal' => GoogleFonts.tajawal(textStyle: base),
      'almarai' => GoogleFonts.almarai(textStyle: base),
      'ibmPlexSansArabic' => GoogleFonts.ibmPlexSansArabic(textStyle: base),
      'playfairDisplay' => GoogleFonts.playfairDisplay(textStyle: base),
      _ => GoogleFonts.cairo(textStyle: base),
    };
  }
}
