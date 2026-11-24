import '../models/import_row.dart';
import '../parsers/column_mapper.dart';
import '../utils/color_name_hex.dart';
import '../../../core/utils/formatters.dart';

/// Normalizes raw spreadsheet maps into fault-tolerant [ImportRow]s.
class ImportSanitizer {
  ImportSanitizer._();

  static const String placeholderImage = 'https://placehold.co/600x800/png?text=No+Image';
  static const String defaultBrand = 'Demo Brand';
  static const String defaultCat = 'General';
  static const String defaultCatAr = 'عام';
  static const num defaultQuant = 50;

  /// Builds sanitized rows from canonical maps. [orderBase] seeds `order` as index+1.
  static List<ImportRow> fromMaps(List<Map<String, String>> raw, {int orderBase = 1}) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final rows = <ImportRow>[];
    for (var i = 0; i < raw.length; i++) {
      rows.add(sanitize(raw[i], index: i, stamp: stamp, order: orderBase + i));
    }
    return rows;
  }

  static ImportRow sanitize(Map<String, String> raw, {required int index, required int stamp, required int order}) {
    String v(String key) => (raw[key] ?? '').trim();

    var name = v(ImportColumns.name);
    var nameAr = v(ImportColumns.nameAr);
    if (name.isEmpty) name = nameAr;
    if (nameAr.isEmpty) nameAr = name;

    var des = v(ImportColumns.des);
    var desAr = v(ImportColumns.desAr);
    if (des.isEmpty) des = desAr;
    if (desAr.isEmpty) desAr = des;

    // Some exports put the title only in the description column.
    if (name.isEmpty && nameAr.isEmpty) {
      final fromDes = desAr.isNotEmpty ? desAr : des;
      if (fromDes.isNotEmpty) {
        final short = fromDes.length > 80 ? fromDes.substring(0, 80).trim() : fromDes.trim();
        nameAr = short;
        name = (des.isNotEmpty ? des : fromDes);
        if (name.length > 80) name = name.substring(0, 80).trim();
      }
    }

    // Keep a usable description in the review UI when the file omitted it.
    if (des.isEmpty && desAr.isEmpty && (name.isNotEmpty || nameAr.isNotEmpty)) {
      final label = nameAr.isNotEmpty ? nameAr : name;
      desAr = label;
      des = name.isNotEmpty ? name : label;
    }

    var category = v(ImportColumns.category);
    // category is a single field in the sheet; cat/catAr filled at validate/toProduct time

    var brand = v(ImportColumns.brand);
    if (brand.isEmpty) brand = defaultBrand;

    final price = _money(v(ImportColumns.price));
    final oldPrice = _money(v(ImportColumns.oldPrice));

    var color = v(ImportColumns.color);
    var colorAr = v(ImportColumns.colorAr);
    if (color.isEmpty) color = colorAr;
    if (colorAr.isEmpty) colorAr = color;

    var colorHex = _hex(v(ImportColumns.colorHex));
    if (colorHex.isEmpty && (color.isNotEmpty || colorAr.isNotEmpty)) {
      colorHex = ColorNameHex.hexFor(color.isNotEmpty ? color : colorAr);
    }

    final images = _images(v(ImportColumns.images));
    final usedPlaceholder = images.length == 1 && images.first == placeholderImage;

    var quantity = _money(v(ImportColumns.quantity));
    if (quantity <= 0) quantity = defaultQuant;

    final stockRaw = v(ImportColumns.stock);
    final row = ImportRow(
      productId: () {
        final id = v(ImportColumns.productId);
        return id.isEmpty ? 'prod_${stamp}_$index' : id;
      }(),
      groupId: v(ImportColumns.groupId),
      name: name,
      nameAr: nameAr,
      des: des,
      desAr: desAr,
      brand: brand,
      category: category,
      price: price,
      oldPrice: oldPrice,
      color: color,
      colorAr: colorAr,
      colorHex: colorHex,
      stock: {},
      quantity: quantity,
      images: images,
      order: order,
      usedPlaceholderImage: usedPlaceholder,
    );

    if (stockRaw.isNotEmpty) {
      if (_isPureQuantity(stockRaw)) {
        // e.g. "12" or "25" in a sizes/stock column → quantity, not a size named "12".
        row.quantity = _money(stockRaw);
      } else if (_looksLikeStockGrammar(stockRaw)) {
        row.setStockText(stockRaw);
      } else {
        row.sizes = _splitSizes(stockRaw);
      }
    }
    return row;
  }

  /// True when the whole cell is a single non-negative number (inventory qty).
  static bool _isPureQuantity(String text) {
    final western = text.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m.group(0)!.codeUnitAt(0) - 0x0660}');
    return RegExp(r'^\d+(\.\d+)?$').hasMatch(western.trim());
  }

  static bool _looksLikeStockGrammar(String text) =>
      RegExp(r'[:=]').hasMatch(text) || RegExp(r'\S+\s+-?\d+(\.\d+)?').hasMatch(text.split(RegExp(r'[|,;\n،]')).first.trim());

  static List<String> _splitSizes(String text) => text
      .split(RegExp(r'[,،\-/|]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  static List<String> _images(String text) {
    final parts = text
        .split(RegExp(r'[|\n,;]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return [placeholderImage];
    return parts;
  }

  static num _money(String text) {
    if (text.isEmpty) return 0;
    final western = text.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m.group(0)!.codeUnitAt(0) - 0x0660}');
    return Formatters.toNum(western.replaceAll(RegExp(r'[^\d.\-]'), ''));
  }

  static String _hex(String text) {
    if (text.isEmpty) return '';
    final hex = text.replaceAll('#', '').trim();
    return RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex) ? '#${hex.toUpperCase()}' : '';
  }
}
