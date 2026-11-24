/// Maps common Arabic & English fashion color names to standard hex codes.
class ColorNameHex {
  ColorNameHex._();

  static const String fallback = '#1E1E1E';

  static const Map<String, String> _map = {
    // black
    'black': '#000000', 'أسود': '#000000', 'اسود': '#000000',
    // white
    'white': '#FFFFFF', 'أبيض': '#FFFFFF', 'ابيض': '#FFFFFF',
    // beige
    'beige': '#F5F5DC', 'بيج': '#F5F5DC',
    // navy
    'navy': '#000080', 'كحلي': '#000080', 'navyblue': '#000080',
    // red
    'red': '#FF0000', 'أحمر': '#FF0000', 'احمر': '#FF0000',
    // green
    'green': '#008000', 'أخضر': '#008000', 'اخضر': '#008000',
    // pink
    'pink': '#FFC0CB', 'وردي': '#FFC0CB',
    // grey / gray
    'grey': '#808080', 'gray': '#808080', 'رمادي': '#808080',
    // brown
    'brown': '#8B4513', 'بني': '#8B4513',
    // yellow
    'yellow': '#FFFF00', 'أصفر': '#FFFF00', 'اصفر': '#FFFF00',
    // blue
    'blue': '#0000FF', 'أزرق': '#0000FF', 'ازرق': '#0000FF',
    // purple
    'purple': '#800080', 'بنفسجي': '#800080', 'موف': '#800080',
    // extras common in fashion
    'cream': '#FFFDD0', 'كريمي': '#FFFDD0', 'كريمة': '#FFFDD0',
    'gold': '#FFD700', 'ذهبي': '#FFD700',
    'silver': '#C0C0C0', 'فضي': '#C0C0C0',
    'orange': '#FFA500', 'برتقالي': '#FFA500',
    'maroon': '#800000', 'عنابي': '#800000',
    'olive': '#808000', 'زيتوني': '#808000',
    'khaki': '#F0E68C', 'كاكي': '#F0E68C',
  };

  /// Returns a `#RRGGBB` hex for [name], or [fallback] when unknown.
  static String hexFor(String name) {
    final key = name.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');
    if (key.isEmpty) return fallback;
    return _map[key] ?? _map[name.trim()] ?? fallback;
  }

  /// True when [name] is a known dictionary color.
  static bool isKnown(String name) {
    final key = name.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');
    return _map.containsKey(key) || _map.containsKey(name.trim());
  }
}
