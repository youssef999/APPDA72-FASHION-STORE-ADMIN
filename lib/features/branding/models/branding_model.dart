import 'package:flutter/material.dart';
import '../../../core/utils/color_parser.dart';

/// Shared with the store app: Firestore `config/branding`.
class BrandingModel {
  static const String collection = 'config';
  static const String docId = 'branding';

  static const String defaultBrandName = 'APPDA 72';
  static const String defaultPrimary = '#1C1B1F';
  static const String defaultAccent = '#B08D57';
  static const String defaultBackground = '#FAF7F2';
  static const String defaultButton = '#1C1B1F';
  static const String defaultButtonText = '#FFFFFF';
  static const String defaultIcon = '#B08D57';
  static const String defaultBannerText = '#FFFFFF';
  static const String defaultBodyFont = 'cairo';
  static const String defaultDisplayFont = 'playfairDisplay';

  static const List<({String key, String label})> fontCatalog = [
    (key: 'cairo', label: 'Cairo'),
    (key: 'tajawal', label: 'Tajawal'),
    (key: 'almarai', label: 'Almarai'),
    (key: 'ibmPlexSansArabic', label: 'IBM Plex Sans Arabic'),
    (key: 'playfairDisplay', label: 'Playfair Display'),
  ];

  final String brandName;
  final String logoUrl;
  final String primaryHex;
  final String accentHex;
  final String backgroundHex;
  final String buttonHex;
  final String buttonTextHex;
  final String iconHex;
  final String bannerTextHex;
  final String bodyFont;
  final String displayFont;

  const BrandingModel({
    required this.brandName,
    required this.logoUrl,
    required this.primaryHex,
    required this.accentHex,
    required this.backgroundHex,
    required this.buttonHex,
    required this.buttonTextHex,
    required this.iconHex,
    required this.bannerTextHex,
    required this.bodyFont,
    required this.displayFont,
  });

  factory BrandingModel.defaults() => const BrandingModel(
        brandName: defaultBrandName,
        logoUrl: '',
        primaryHex: defaultPrimary,
        accentHex: defaultAccent,
        backgroundHex: defaultBackground,
        buttonHex: defaultButton,
        buttonTextHex: defaultButtonText,
        iconHex: defaultIcon,
        bannerTextHex: defaultBannerText,
        bodyFont: defaultBodyFont,
        displayFont: defaultDisplayFont,
      );

  factory BrandingModel.fromMap(Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    final primary = _normalizeHex(_string(map['primary'], defaultPrimary), defaultPrimary);
    final accent = _normalizeHex(_string(map['accent'], defaultAccent), defaultAccent);
    return BrandingModel(
      brandName: _string(map['brandName'], defaultBrandName),
      logoUrl: _string(map['logoUrl'], ''),
      primaryHex: primary,
      accentHex: accent,
      backgroundHex: _normalizeHex(_string(map['background'], defaultBackground), defaultBackground),
      buttonHex: _normalizeHex(_string(map['button'], primary), primary),
      buttonTextHex: _normalizeHex(_string(map['buttonText'], defaultButtonText), defaultButtonText),
      iconHex: _normalizeHex(_string(map['icon'], accent), accent),
      bannerTextHex: _normalizeHex(_string(map['bannerText'], defaultBannerText), defaultBannerText),
      bodyFont: _font(_string(map['bodyFont'], defaultBodyFont), defaultBodyFont),
      displayFont: _font(_string(map['displayFont'], defaultDisplayFont), defaultDisplayFont),
    );
  }

  Map<String, dynamic> toMap() => {
        'brandName': brandName,
        'logoUrl': logoUrl,
        'primary': primaryHex,
        'accent': accentHex,
        'background': backgroundHex,
        'button': buttonHex,
        'buttonText': buttonTextHex,
        'icon': iconHex,
        'bannerText': bannerTextHex,
        'bodyFont': bodyFont,
        'displayFont': displayFont,
      };

  Color get primaryColor => parseHexColor(primaryHex) ?? const Color(0xFF1C1B1F);
  Color get accentColor => parseHexColor(accentHex) ?? const Color(0xFFB08D57);
  Color get backgroundColor => parseHexColor(backgroundHex) ?? const Color(0xFFFAF7F2);
  Color get buttonColor => parseHexColor(buttonHex) ?? const Color(0xFF1C1B1F);
  Color get buttonTextColor => parseHexColor(buttonTextHex) ?? Colors.white;
  Color get iconColor => parseHexColor(iconHex) ?? const Color(0xFFB08D57);
  Color get bannerTextColor => parseHexColor(bannerTextHex) ?? Colors.white;

  bool get hasLogo => logoUrl.trim().isNotEmpty;

  BrandingModel copyWith({
    String? brandName,
    String? logoUrl,
    String? primaryHex,
    String? accentHex,
    String? backgroundHex,
    String? buttonHex,
    String? buttonTextHex,
    String? iconHex,
    String? bannerTextHex,
    String? bodyFont,
    String? displayFont,
  }) {
    return BrandingModel(
      brandName: brandName ?? this.brandName,
      logoUrl: logoUrl ?? this.logoUrl,
      primaryHex: primaryHex ?? this.primaryHex,
      accentHex: accentHex ?? this.accentHex,
      backgroundHex: backgroundHex ?? this.backgroundHex,
      buttonHex: buttonHex ?? this.buttonHex,
      buttonTextHex: buttonTextHex ?? this.buttonTextHex,
      iconHex: iconHex ?? this.iconHex,
      bannerTextHex: bannerTextHex ?? this.bannerTextHex,
      bodyFont: bodyFont ?? this.bodyFont,
      displayFont: displayFont ?? this.displayFont,
    );
  }

  static String colorToHex(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  static String _string(dynamic value, String fallback) {
    final text = '$value'.trim();
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  static String _normalizeHex(String value, String fallback) {
    final hex = value.trim().replaceFirst('#', '');
    if (hex.length != 6 || int.tryParse(hex, radix: 16) == null) return fallback;
    return '#${hex.toUpperCase()}';
  }

  static String _font(String key, String fallback) {
    return fontCatalog.any((item) => item.key == key) ? key : fallback;
  }
}
