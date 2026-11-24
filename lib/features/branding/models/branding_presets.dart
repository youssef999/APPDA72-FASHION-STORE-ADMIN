import 'branding_model.dart';

/// Curated fashion looks for APPDA 72 white-label stores (GCC + international).
class BrandingStylePreset {
  final String id;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String bestForAr;
  final BrandingModel style;

  const BrandingStylePreset({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.bestForAr,
    required this.style,
  });

  /// Three distinct directions: mauve · deep fashion blue · Gulf Ramadan beige.
  static const List<BrandingStylePreset> fashion = [
    /// Soft dark mauve — feminine ready-to-wear.
    BrandingStylePreset(
      id: 'mauve_atelier',
      titleAr: 'Mauve Atelier',
      titleEn: 'Mauve Atelier',
      subtitleAr: 'موف غامق ناعم + ذهب وردي على باودر حريري',
      bestForAr: 'أفضل لـ: ملابس حريمي · أتيليه · إطلالات ناعمة وأنيقة',
      style: BrandingModel(
        brandName: BrandingModel.defaultBrandName,
        logoUrl: '',
        primaryHex: '#5A3558',
        accentHex: '#D4A5B0',
        backgroundHex: '#F7EFF3',
        buttonHex: '#5A3558',
        buttonTextHex: '#FFFFFF',
        iconHex: '#D4A5B0',
        bannerTextHex: '#FFFFFF',
        bodyFont: 'cairo',
        displayFont: 'playfairDisplay',
      ),
    ),

    /// Deep navy — editorial fashion / international brand.
    BrandingStylePreset(
      id: 'navy_editorial',
      titleAr: 'Navy Editorial',
      titleEn: 'Navy Editorial',
      subtitleAr: 'أزرق كحلي غامق + فضي دافئ على عاجي بارد',
      bestForAr: 'أفضل لـ: فاشون عالمي · Lookbook · Ready-to-wear راقٍ',
      style: BrandingModel(
        brandName: BrandingModel.defaultBrandName,
        logoUrl: '',
        primaryHex: '#1B2A4A',
        accentHex: '#C5B8A5',
        backgroundHex: '#F4F5F7',
        buttonHex: '#1B2A4A',
        buttonTextHex: '#FFFFFF',
        iconHex: '#C5B8A5',
        bannerTextHex: '#FFFFFF',
        bodyFont: 'tajawal',
        displayFont: 'ibmPlexSansArabic',
      ),
    ),

    /// Warm beige / sand — abayas, Ramadan, Gulf hospitality.
    BrandingStylePreset(
      id: 'gulf_beige',
      titleAr: 'Gulf Beige',
      titleEn: 'Gulf Beige',
      subtitleAr: 'بيج رملي دافئ + نحاس ذهبي على كريمي رمضاني',
      bestForAr: 'أفضل لـ: عبايات · جو رمضان / العيد · ستايل الخليج',
      style: BrandingModel(
        brandName: BrandingModel.defaultBrandName,
        logoUrl: '',
        primaryHex: '#8A6A4B',
        accentHex: '#D4B483',
        backgroundHex: '#F7F1E8',
        buttonHex: '#6E533A',
        buttonTextHex: '#FFFFFF',
        iconHex: '#D4B483',
        bannerTextHex: '#FFF8EF',
        bodyFont: 'almarai',
        displayFont: 'playfairDisplay',
      ),
    ),
  ];
}
