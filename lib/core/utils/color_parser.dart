import 'package:flutter/painting.dart';

/// Product colors are stored as `#RRGGBB` strings in Firestore.
Color? parseHexColor(String value) {
  final hex = value.trim().replaceFirst('#', '');
  if (hex.length != 6) return null;
  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? null : Color(0xFF000000 | parsed);
}
