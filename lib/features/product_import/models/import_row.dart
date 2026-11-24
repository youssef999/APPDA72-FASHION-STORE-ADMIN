import '../../../core/utils/formatters.dart';
import '../parsers/column_mapper.dart';

enum ImportAction { create, update, skip }

enum ImportRowStatus { ready, warning, error }

/// One product (one color) from an imported file, validated against the store before saving.
class ImportRow {
  String productId;
  String groupId;
  String name;
  String nameAr;
  String des;
  String desAr;
  String brand;
  String category;
  num price;
  num oldPrice;
  String color;
  String colorAr;
  String colorHex;

  /// Size → quantity, in the order written in the file.
  Map<String, num> stock;

  /// Size labels when the file lists sizes without quantities (e.g. `S,M,L`).
  List<String> sizes;
  num quantity;

  /// URLs, or file names that are matched against uploaded images.
  List<String> images;

  /// Display order written to Firestore (`index + 1`).
  int order;

  /// True when the sanitizer injected the placeholder image URL.
  bool usedPlaceholderImage;

  ImportAction action = ImportAction.create;
  bool exists = false;
  String? categoryName;
  String? categoryNameAr;
  final List<String> errors = [];
  final List<String> warnings = [];
  final List<String> stockErrors = [];

  ImportRow({
    required this.productId,
    required this.groupId,
    required this.name,
    required this.nameAr,
    required this.des,
    required this.desAr,
    required this.brand,
    required this.category,
    required this.price,
    required this.oldPrice,
    required this.color,
    required this.colorAr,
    required this.colorHex,
    required this.stock,
    required this.quantity,
    required this.images,
    this.sizes = const [],
    this.order = 0,
    this.usedPlaceholderImage = false,
  });

  factory ImportRow.fromRaw(Map<String, String> raw) {
    String v(String key) {
      final value = raw[key];
      if (value == null) return '';
      return value.trim();
    }

    final row = ImportRow(
      productId: v(ImportColumns.productId),
      groupId: v(ImportColumns.groupId),
      name: v(ImportColumns.name),
      nameAr: v(ImportColumns.nameAr),
      des: v(ImportColumns.des),
      desAr: v(ImportColumns.desAr),
      brand: v(ImportColumns.brand),
      category: v(ImportColumns.category),
      price: _number(v(ImportColumns.price)),
      oldPrice: _number(v(ImportColumns.oldPrice)),
      color: v(ImportColumns.color),
      colorAr: v(ImportColumns.colorAr),
      colorHex: _hex(v(ImportColumns.colorHex)),
      stock: {},
      quantity: _number(v(ImportColumns.quantity)),
      images: v(ImportColumns.images)
          .split(RegExp(r'[|\n,;]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
    final stockText = v(ImportColumns.stock);
    if (stockText.isNotEmpty) row.setStockText(stockText);
    return row;
  }

  /// Parses `S:5|M:3|L:0` (also `S=5, M=3` or `S 5`); a size without a number gets quantity 0.
  void setStockText(String text) {
    stock = {};
    sizes = [];
    stockErrors.clear();
    for (final part in _westernDigits(text).split(RegExp(r'[|,;\n،]+'))) {
      final entry = part.trim();
      if (entry.isEmpty) continue;
      final match = RegExp(r'^(.+?)\s*[:=\s]\s*(-?[\d.]+)$').firstMatch(entry);
      final size = (match?.group(1) ?? entry).trim();
      final qty = match == null ? 0 : _number(match.group(2)!);
      if (stock.containsKey(size)) stockErrors.add('المقاس "$size" مكرر');
      if (qty < 0) stockErrors.add('كمية سالبة للمقاس "$size"');
      stock[size] = qty < 0 ? 0 : qty;
    }
  }

  String get stockText {
    if (stock.isNotEmpty) return stock.entries.map((e) => '${e.key}:${e.value}').join('|');
    return sizes.join('|');
  }

  num get totalStock => stock.isEmpty ? quantity : stock.values.fold<num>(0, (s, q) => s + q);

  List<String> get resolvedSizes => stock.isNotEmpty ? stock.keys.toList() : sizes;

  String get displayName => nameAr.isNotEmpty ? nameAr : name;

  String get displayDes => desAr.isNotEmpty ? desAr : des;

  bool get isValid => errors.isEmpty;

  ImportRowStatus get status {
    if (errors.isNotEmpty) return ImportRowStatus.error;
    if (warnings.isNotEmpty) return ImportRowStatus.warning;
    return ImportRowStatus.ready;
  }

  /// File names (not URLs) that still need a matching uploaded image.
  List<String> get pendingImageNames => images.where((e) => !e.startsWith('http')).toList();

  static num _number(String text) => Formatters.toNum(_westernDigits(text).replaceAll(RegExp(r'[^\d.\-]'), ''));

  static String _westernDigits(String text) =>
      text.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m.group(0)!.codeUnitAt(0) - 0x0660}');

  static String _hex(String text) {
    if (text.isEmpty) return '';
    final hex = text.replaceAll('#', '').trim();
    return RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex) ? '#${hex.toUpperCase()}' : text;
  }
}
