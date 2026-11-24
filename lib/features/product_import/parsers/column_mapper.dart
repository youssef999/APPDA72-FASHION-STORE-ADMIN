/// Canonical import columns; every parser and the AI extractor produce rows keyed by these.
class ImportColumns {
  ImportColumns._();

  static const String productId = 'productid';
  static const String groupId = 'groupId';
  static const String name = 'name';
  static const String nameAr = 'nameAr';
  static const String des = 'des';
  static const String desAr = 'desAr';
  static const String brand = 'brand';
  static const String category = 'category';
  static const String price = 'price';
  static const String oldPrice = 'oldPrice';
  static const String color = 'color';
  static const String colorAr = 'colorAr';
  static const String colorHex = 'colorHex';
  static const String stock = 'stock';
  static const String quantity = 'quant';
  static const String images = 'images';

  /// Column order of the downloadable template + mapping UI.
  static const List<String> template = [
    productId, groupId, name, nameAr, des, desAr, brand, category,
    price, oldPrice, color, colorAr, colorHex, stock, quantity, images,
  ];

  static const Map<String, String> labelsAr = {
    productId: 'رقم المنتج (productid)',
    groupId: 'رقم المجموعة (groupId)',
    name: 'الاسم بالإنجليزي',
    nameAr: 'الاسم بالعربي',
    des: 'الوصف بالإنجليزي',
    desAr: 'الوصف بالعربي',
    brand: 'الماركة',
    category: 'القسم',
    price: 'السعر',
    oldPrice: 'السعر قبل الخصم',
    color: 'اللون بالإنجليزي',
    colorAr: 'اللون بالعربي',
    colorHex: 'كود اللون',
    stock: 'المقاسات / المخزون',
    quantity: 'الكمية',
    images: 'الصور',
  };
}

/// Parsed spreadsheet kept for the manual column-mapping step.
class ParsedSheet {
  final List<String> headers;
  final List<List<String>> dataRows;
  final int headerIndex;
  final List<List<String>> rawTable;

  /// Canonical field → original header (null = skip / use default).
  final Map<String, String?> suggestedMapping;

  const ParsedSheet({
    required this.headers,
    required this.dataRows,
    required this.headerIndex,
    required this.rawTable,
    required this.suggestedMapping,
  });

  bool get isEmpty => dataRows.isEmpty;

  /// Applies [mapping] (field → header name) to produce canonical string maps.
  List<Map<String, String>> applyMapping(Map<String, String?> mapping) {
    final indexByHeader = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      final h = headers[i].trim();
      if (h.isNotEmpty) indexByHeader.putIfAbsent(h, () => i);
    }
    final rows = <Map<String, String>>[];
    for (final cells in dataRows) {
      final row = <String, String>{};
      for (final entry in mapping.entries) {
        final header = entry.value;
        if (header == null || header.isEmpty) continue;
        final col = indexByHeader[header];
        if (col == null || col >= cells.length) continue;
        final value = cells[col].trim();
        if (value.isNotEmpty) row[entry.key] = value;
      }
      if (row.isNotEmpty) rows.add(row);
    }
    return rows;
  }
}

/// Maps loosely written headers (English or Arabic, any case/spacing) to [ImportColumns].
class ColumnMapper {
  ColumnMapper._();

  static final Map<String, String> _aliases = {
    for (final c in ImportColumns.template) _normalize(c): c,
    // ids / sku
    'id': ImportColumns.productId, 'sku': ImportColumns.productId, 'code': ImportColumns.productId,
    'productcode': ImportColumns.productId, 'productsku': ImportColumns.productId,
    'variantsku': ImportColumns.productId, 'رقمالمنتج': ImportColumns.productId, 'الكود': ImportColumns.productId,
    'رمزالمنتج': ImportColumns.productId, 'handle': ImportColumns.groupId,
    'group': ImportColumns.groupId, 'model': ImportColumns.groupId, 'المجموعة': ImportColumns.groupId,
    'الموديل': ImportColumns.groupId,
    // names
    'title': ImportColumns.name, 'productname': ImportColumns.name, 'nameen': ImportColumns.name,
    'englishname': ImportColumns.name, 'الاسمبالانجليزي': ImportColumns.name, 'الاسمبالإنجليزي': ImportColumns.name,
    'producttitle': ImportColumns.name,
    'الاسم': ImportColumns.nameAr, 'اسمالمنتج': ImportColumns.nameAr, 'الاسمبالعربي': ImportColumns.nameAr,
    'arabicname': ImportColumns.nameAr, 'عنوانالمنتج': ImportColumns.nameAr,
    'المنتج': ImportColumns.nameAr, 'اسم': ImportColumns.nameAr, 'العنوان': ImportColumns.nameAr,
    'اسمالصنف': ImportColumns.nameAr, 'اسمالسلعة': ImportColumns.nameAr, 'itemname': ImportColumns.nameAr,
    'product': ImportColumns.name, 'item': ImportColumns.name, 'itemtitle': ImportColumns.name,
    // descriptions
    'description': ImportColumns.des, 'desc': ImportColumns.des, 'descriptionen': ImportColumns.des,
    'bodyhtml': ImportColumns.des, 'body': ImportColumns.des,
    'الوصف': ImportColumns.desAr, 'الوصفبالعربي': ImportColumns.desAr, 'الوصفبالانجليزي': ImportColumns.des,
    'تفاصيلالمنتج': ImportColumns.desAr,
    // brand / category
    'vendor': ImportColumns.brand, 'الماركة': ImportColumns.brand, 'البراند': ImportColumns.brand,
    'cat': ImportColumns.category, 'categoryname': ImportColumns.category, 'producttype': ImportColumns.category,
    'type': ImportColumns.category, 'القسم': ImportColumns.category, 'الفئة': ImportColumns.category,
    'التصنيف': ImportColumns.category, 'التصنيفات': ImportColumns.category,
    // prices (Shopify / Salla / Zid)
    'السعر': ImportColumns.price, 'saleprice': ImportColumns.price, 'سعرالبيع': ImportColumns.price,
    'variantprice': ImportColumns.price, 'priceegp': ImportColumns.price, 'السعرالحالي': ImportColumns.price,
    'السعرالمخفف': ImportColumns.price, 'السعرالمخفوض': ImportColumns.price, 'سعرالتخفيض': ImportColumns.price,
    'compareatprice': ImportColumns.oldPrice, 'originalprice': ImportColumns.oldPrice,
    'variantcompareatprice': ImportColumns.oldPrice, 'السعرقبلالخصم': ImportColumns.oldPrice,
    'السعرالقديم': ImportColumns.oldPrice, 'السعرالأصلي': ImportColumns.oldPrice, 'السعرالاساسي': ImportColumns.oldPrice,
    // colors / options
    'colour': ImportColumns.color, 'colorname': ImportColumns.color, 'option1value': ImportColumns.color,
    'option1name': ImportColumns.color, 'اللونبالانجليزي': ImportColumns.color,
    'اللون': ImportColumns.colorAr, 'لونالمنتج': ImportColumns.colorAr,
    'hex': ImportColumns.colorHex, 'colorcode': ImportColumns.colorHex, 'كوداللون': ImportColumns.colorHex,
    // sizes / stock / qty
    'sizes': ImportColumns.stock, 'sizestock': ImportColumns.stock, 'المقاسات': ImportColumns.stock,
    'المخزون': ImportColumns.stock, 'المقاساتوالكمية': ImportColumns.stock, 'option2value': ImportColumns.stock,
    'size': ImportColumns.stock, 'المقاس': ImportColumns.stock,
    'quantity': ImportColumns.quantity, 'qty': ImportColumns.quantity, 'الكمية': ImportColumns.quantity,
    'variantinventoryqty': ImportColumns.quantity, 'inventory': ImportColumns.quantity,
    'الكميةالمتوفرة': ImportColumns.quantity, 'المخزونالمتاح': ImportColumns.quantity, 'stockqty': ImportColumns.quantity,
    // images
    'image': ImportColumns.images, 'photos': ImportColumns.images, 'pictures': ImportColumns.images,
    'imagesrc': ImportColumns.images, 'imageurls': ImportColumns.images, 'imageurl': ImportColumns.images,
    'الصور': ImportColumns.images, 'الصورة': ImportColumns.images, 'رابطالصورة': ImportColumns.images,
    'صورالمنتج': ImportColumns.images,
  };

  static String _normalize(String header) =>
      header.toLowerCase().replaceAll(RegExp(r'[\s_\-.:()/]+'), '').replaceAll('ـ', '');

  static String? canonical(String header) => _aliases[_normalize(header)];

  /// Detects the header row and returns a [ParsedSheet] for manual remapping.
  static ParsedSheet? parseSheet(List<List<String>> table) {
    for (var h = 0; h < table.length && h < 15; h++) {
      final headerCells = table[h].map((e) => e.trim()).toList();
      final keys = headerCells.map(canonical).toList();
      final known = keys.whereType<String>().length;
      // Prefer a real header row; also accept any non-empty first row as headers for manual mapping.
      final nonEmpty = headerCells.where((e) => e.isNotEmpty).length;
      if (known < 2 && !(h == 0 && nonEmpty >= 2)) continue;

      final suggested = <String, String?>{for (final f in ImportColumns.template) f: null};
      final usedFields = <String>{};
      for (var i = 0; i < headerCells.length; i++) {
        final header = headerCells[i];
        if (header.isEmpty) continue;
        final field = keys[i];
        if (field != null && usedFields.add(field)) {
          suggested[field] = header;
        }
      }

      return ParsedSheet(
        headers: headerCells,
        dataRows: _alignDataRows(table.skip(h + 1).toList(), headerCells),
        headerIndex: h,
        rawTable: table,
        suggestedMapping: suggested,
      );
    }
    return null;
  }

  static List<List<String>> _alignDataRows(List<List<String>> rows, List<String> headerCells) {
    final width = headerCells.length;
    final out = <List<String>>[];
    for (final r in rows) {
      final aligned = [for (var i = 0; i < width; i++) i < r.length ? r[i].trim() : ''];
      if (aligned.any((c) => c.isNotEmpty)) out.add(aligned);
    }
    return out;
  }

  /// Finds the header row and maps every row after it (auto-map only).
  static List<Map<String, String>> mapTable(List<List<String>> table) {
    final sheet = parseSheet(table);
    if (sheet == null) return const [];
    return sheet.applyMapping(sheet.suggestedMapping);
  }
}
