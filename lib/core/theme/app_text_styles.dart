import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale; colors come from the theme so styles work in light and dark.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get h1 => GoogleFonts.cairo(fontSize: 30, fontWeight: FontWeight.w800, height: 1.2);
  static TextStyle get h2 => GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w800, height: 1.25);
  static TextStyle get h3 => GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3);
  static TextStyle get h4 => GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w700, height: 1.35);
  static TextStyle get h5 => GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w700, height: 1.4);
  static TextStyle get h6 => GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700, height: 1.4);
  static TextStyle get body1 => GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w500, height: 1.5);
  static TextStyle get body2 => GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w500, height: 1.5);
  static TextStyle get caption => GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4);
  static TextStyle get button => GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w700);
  static TextStyle get overline =>
      GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2);
}
