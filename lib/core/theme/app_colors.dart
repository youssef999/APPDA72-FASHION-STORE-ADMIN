import 'package:flutter/material.dart';

/// One palette per brightness; widgets read it through `context.colors`.
@immutable
class AppPalette {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color card;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color border;
  final Color divider;
  final Color shadow;
  final Color sidebar;
  final Color onSidebar;
  final Color onPrimary;

  const AppPalette({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.card,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.border,
    required this.divider,
    required this.shadow,
    required this.sidebar,
    required this.onSidebar,
    required this.onPrimary,
  });
}

/// Same identity as the store app: ink black, champagne gold and warm cream.
class AppColors {
  AppColors._();

  static const AppPalette light = AppPalette(
    primary: Color(0xFF1C1B1F),
    primaryLight: Color(0xFF3A3A3C),
    primaryDark: Color(0xFF0E0E10),
    secondary: Color(0xFFB08D57),
    background: Color(0xFFFAF7F2),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    success: Color(0xFF2E8B57),
    warning: Color(0xFFD9822B),
    error: Color(0xFFB4233C),
    info: Color(0xFF4A6FA5),
    textPrimary: Color(0xFF1C1B1F),
    textSecondary: Color(0xFF6B655E),
    textDisabled: Color(0xFFADA69D),
    border: Color(0xFFE8E1D7),
    divider: Color(0xFFEFEAE3),
    shadow: Color(0x14000000),
    sidebar: Color(0xFF1C1B1F),
    onSidebar: Color(0xFFF3EDE4),
    onPrimary: Color(0xFFFFFFFF),
  );

  static const AppPalette dark = AppPalette(
    primary: Color(0xFFD4B483),
    primaryLight: Color(0xFFE3CBA4),
    primaryDark: Color(0xFFB08D57),
    secondary: Color(0xFFD4B483),
    background: Color(0xFF121212),
    surface: Color(0xFF1A1A1A),
    card: Color(0xFF1E1E1E),
    success: Color(0xFF6FBF8E),
    warning: Color(0xFFE3AE57),
    error: Color(0xFFE5677A),
    info: Color(0xFF8AA9D6),
    textPrimary: Color(0xFFF3EDE4),
    textSecondary: Color(0xFFA39A90),
    textDisabled: Color(0xFF6B655E),
    border: Color(0xFF2C2C2C),
    divider: Color(0xFF262626),
    shadow: Color(0x33000000),
    sidebar: Color(0xFF0E0E10),
    onSidebar: Color(0xFFF3EDE4),
    onPrimary: Color(0xFF1C1B1F),
  );
}

/// Series colors for charts, ordered so neighbouring slices stay distinguishable.
class AppChartColors {
  AppChartColors._();

  static const List<Color> palette = [
    Color(0xFFB08D57),
    Color(0xFF1C1B1F),
    Color(0xFF4A6FA5),
    Color(0xFF2E8B57),
    Color(0xFFB4233C),
    Color(0xFFD9822B),
    Color(0xFF7A5C99),
    Color(0xFF6B655E),
  ];

  static const List<Color> paletteDark = [
    Color(0xFFD4B483),
    Color(0xFFF3EDE4),
    Color(0xFF8AA9D6),
    Color(0xFF6FBF8E),
    Color(0xFFE5677A),
    Color(0xFFE3AE57),
    Color(0xFFB39DDB),
    Color(0xFFA39A90),
  ];

  static Color at(BuildContext context, int index) {
    final list = Theme.of(context).brightness == Brightness.dark ? paletteDark : palette;
    return list[index % list.length];
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get colors =>
      Theme.of(this).brightness == Brightness.dark ? AppColors.dark : AppColors.light;
}
