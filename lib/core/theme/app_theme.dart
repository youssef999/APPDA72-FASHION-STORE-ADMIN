import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radius.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppPalette c, Brightness brightness) {
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: color, width: width),
        );

    final base = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.divider,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.secondary,
        brightness: brightness,
        primary: c.primary,
        onPrimary: c.onPrimary,
        secondary: c.secondary,
        surface: c.surface,
        onSurface: c.textPrimary,
        error: c.error,
      ),
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme)
          .apply(bodyColor: c.textPrimary, displayColor: c.textPrimary),
      iconTheme: IconThemeData(color: c.textPrimary),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: c.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: c.textDisabled),
        border: border(c.border),
        enabledBorder: border(c.border),
        focusedBorder: border(c.secondary, 1.4),
        errorBorder: border(c.error),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.secondary),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.secondary : null,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        side: BorderSide(color: c.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
      ),
    );
  }
}
