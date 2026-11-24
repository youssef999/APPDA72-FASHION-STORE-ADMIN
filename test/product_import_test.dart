import 'package:flutter_test/flutter_test.dart';
import 'package:thehatch_admin/features/categories/models/category_model.dart';
import 'package:thehatch_admin/features/product_import/models/import_row.dart';
import 'package:thehatch_admin/features/product_import/parsers/column_mapper.dart';
import 'package:thehatch_admin/features/product_import/parsers/import_template.dart';
import 'package:thehatch_admin/features/product_import/parsers/spreadsheet_parser.dart';
import 'package:thehatch_admin/features/product_import/repositories/product_import_repository.dart';
import 'package:thehatch_admin/features/product_import/services/import_sanitizer.dart';
import 'package:thehatch_admin/features/product_import/services/import_validator.dart';
import 'package:thehatch_admin/features/product_import/utils/color_name_hex.dart';

void main() {
  const categories = [CategoryModel(docId: 'c1', name: 'Dresses', nameAr: 'فساتين', image: '')];

  group('ColumnMapper', () {
    test('maps English, Arabic and loosely written headers', () {
      final rows = ColumnMapper.mapTable([
        ['Product Name', 'الاسم', 'القسم', 'السعر', 'Old_Price', 'المقاسات', 'الصور'],
        ['Linen Dress', 'فستان كتان', 'فساتين', '450', '600', 'S:5|M:3', 'a.jpg|b.jpg'],
      ]);
      expect(rows.single, {
        'name': 'Linen Dress',
        'nameAr': 'فستان كتان',
        'category': 'فساتين',
        'price': '450',
        'oldPrice': '600',
        'stock': 'S:5|M:3',
        'images': 'a.jpg|b.jpg',
      });
    });

    test('maps Shopify-like headers', () {
      final sheet = ColumnMapper.parseSheet([
        ['Handle', 'Title', 'Variant SKU', 'Variant Price', 'Variant Compare At Price', 'Variant Inventory Qty', 'Option1 Value', 'Image Src'],
        ['linen-midi', 'Linen Midi', 'sku_1', '450', '600', '12', 'Beige', 'https://cdn.shopify.com/a.jpg'],
      ]);
      expect(sheet, isNotNull);
      final rows = sheet!.applyMapping(sheet.suggestedMapping);
      expect(rows.single['name'], 'Linen Midi');
      expect(rows.single['productid'], 'sku_1');
      expect(rows.single['price'], '450');
      expect(rows.single['oldPrice'], '600');
      expect(rows.single['quant'], '12');
      expect(rows.single['color'], 'Beige');
      expect(rows.single['images'], 'https://cdn.shopify.com/a.jpg');
      expect(rows.single['groupId'], 'linen-midi');
    });

    test('maps Salla/Zid-like Arabic headers', () {
      final rows = ColumnMapper.mapTable([
        ['اسم المنتج', 'السعر', 'السعر الأصلي', 'الكمية المتوفرة', 'المقاس', 'رابط الصورة'],
        ['فستان', '199', '250', '40', 'M', 'https://cdn.salla.sa/x.jpg'],
      ]);
      expect(rows.single['nameAr'], 'فستان');
      expect(rows.single['price'], '199');
      expect(rows.single['oldPrice'], '250');
      expect(rows.single['quant'], '40');
      expect(rows.single['stock'], 'M');
      expect(rows.single['images'], 'https://cdn.salla.sa/x.jpg');
    });

    test('manual remapping overrides auto suggestions', () {
      final sheet = ColumnMapper.parseSheet([
        ['ColA', 'ColB', 'ColC'],
        ['Top', '120', 'https://x/a.jpg'],
      ])!;
      final mapped = sheet.applyMapping({
        ImportColumns.name: 'ColA',
        ImportColumns.price: 'ColB',
        ImportColumns.images: 'ColC',
      });
      expect(mapped.single, {'name': 'Top', 'price': '120', 'images': 'https://x/a.jpg'});
    });

    test('skips title rows above the header', () {
      final rows = ColumnMapper.mapTable([
        ['Summer catalogue 2026'],
        ['name', 'price'],
        ['Top', '120'],
      ]);
      expect(rows.single['name'], 'Top');
    });
  });

  group('ColorNameHex', () {
    test('maps Arabic and English fashion colors', () {
      expect(ColorNameHex.hexFor('أسود'), '#000000');
      expect(ColorNameHex.hexFor('Black'), '#000000');
      expect(ColorNameHex.hexFor('بيج'), '#F5F5DC');
      expect(ColorNameHex.hexFor('Navy'), '#000080');
      expect(ColorNameHex.hexFor('UnknownTone'), ColorNameHex.fallback);
    });
  });

  group('ImportSanitizer', () {
    test('cross-fills languages, default quant 50, placeholder image, color hex', () {
      final rows = ImportSanitizer.fromMaps([
        {
          'nameAr': 'فستان',
          'price': 'SAR 1,250',
          'color': 'Black',
          'stock': 'S, M, L',
        },
      ]);
      final row = rows.single;
      expect(row.name, 'فستان');
      expect(row.nameAr, 'فستان');
      expect(row.price, 1250);
      expect(row.quantity, ImportSanitizer.defaultQuant);
      expect(row.images, [ImportSanitizer.placeholderImage]);
      expect(row.usedPlaceholderImage, isTrue);
      expect(row.colorHex, '#000000');
      expect(row.sizes, ['S', 'M', 'L']);
      expect(row.stock, isEmpty);
      expect(row.order, 1);
      expect(row.brand, ImportSanitizer.defaultBrand);
    });

    test('keeps stock grammar when quantities are present', () {
      final row = ImportSanitizer.fromMaps([
        {'name': 'Top', 'stock': 'S:5|M:3', 'images': 'https://x/a.jpg'},
      ]).single;
      expect(row.stock, {'S': 5, 'M': 3});
      expect(row.usedPlaceholderImage, isFalse);
    });

    test('treats a pure number in stock as quantity, not a size named "12"', () {
      final row = ImportSanitizer.fromMaps([
        {'name': 'Bag', 'stock': '12', 'images': 'https://x/a.jpg'},
      ]).single;
      expect(row.sizes, isEmpty);
      expect(row.stock, isEmpty);
      expect(row.quantity, 12);
      expect(row.totalStock, 12);
    });

    test('fills empty description from the product name', () {
      final row = ImportSanitizer.fromMaps([
        {'nameAr': 'شنطة زرقاء', 'price': '100', 'images': 'https://x/a.jpg'},
      ]).single;
      expect(row.desAr, 'شنطة زرقاء');
      expect(row.des, 'شنطة زرقاء');
    });
  });

  group('ImportRow', () {
    test('parses stock formats, Arabic digits and hex colors', () {
      final row = ImportRow.fromRaw({'stock': 'S:5, M=٣ ،L 0', 'price': '1,250', 'colorHex': 'd8c3a5'});
      expect(row.stock, {'S': 5, 'M': 3, 'L': 0});
      expect(row.totalStock, 8);
      expect(row.price, 1250);
      expect(row.colorHex, '#D8C3A5');
    });

    test('flags duplicate sizes', () {
      final row = ImportRow.fromRaw({'stock': 'S:1|S:2'});
      expect(row.stockErrors, isNotEmpty);
    });
  });

  test('CSV with BOM is parsed', () {
    final rows = SpreadsheetParser.parseCsv('\uFEFFname,price,category\nTop,120,Dresses\n');
    expect(rows.single, {'name': 'Top', 'price': '120', 'category': 'Dresses'});
  });

  test('template round-trips through the xlsx parser', () {
    final rows = SpreadsheetParser.parseXlsx(ImportTemplate.build(categoryNames: ['Dresses']));
    expect(rows, hasLength(2));
    expect(rows.first['stock'], 'S:5|M:8|L:3');
    expect(rows.first['groupId'], 'g_linen_midi');
  });

  test('Firestore batch size is 450', () {
    expect(ProductImportRepository.batchSize, 450);
  });

  group('ImportValidator', () {
    ImportRow row(Map<String, String> raw) => ImportSanitizer.fromMaps([
          {
            'productid': 'p1',
            'name': 'Top',
            'nameAr': 'توب',
            'category': 'فساتين',
            'price': '100',
            'stock': 'S:2|M:3',
            'images': 'https://x/a.jpg',
            ...raw,
          },
        ]).single;

    test('valid row resolves the category by its Arabic name', () {
      final r = row({});
      ImportValidator.validate([r], categories: categories, existing: {}, availableImages: {});
      expect(r.errors, isEmpty);
      expect(r.categoryName, 'Dresses');
      expect(r.status, ImportRowStatus.ready);
    });

    test('matches categories with Arabic spelling variants and partial labels', () {
      expect(ImportValidator.matchCategory(categories, '  فساتين  ')?.name, 'Dresses');
      expect(ImportValidator.matchCategory(categories, 'dresses')?.name, 'Dresses');
      expect(ImportValidator.matchCategory(categories, 'Dress')?.name, 'Dresses');
    });

    test('uses description as name when title columns are empty', () {
      final r = ImportSanitizer.fromMaps([
        {'desAr': 'فستان كتان صيفي أنيق', 'price': '200', 'images': 'https://x/a.jpg'},
      ]).single;
      expect(r.nameAr, 'فستان كتان صيفي أنيق');
      expect(r.name.isNotEmpty, isTrue);
    });

    test('only missing name is a hard error; price/category/image are warnings', () {
      final r = row({'price': '0', 'category': 'Shoes', 'images': ''});
      // sanitizer already injects placeholder when images empty — rebuild without images key
      final bare = ImportSanitizer.fromMaps([
        {'productid': 'p2', 'name': 'Top', 'price': '0', 'category': 'Shoes'},
      ]).single;
      ImportValidator.validate([bare], categories: categories, existing: {}, availableImages: {});
      expect(bare.errors, isEmpty);
      expect(bare.warnings.join(' '), allOf(contains('السعر'), contains('Shoes'), contains('صورة')));
      expect(bare.warnings.join(' '), contains('اختر قسماً'));
      expect(bare.status, ImportRowStatus.warning);

      final nameless = ImportSanitizer.fromMaps([
        {'productid': 'p3', 'images': 'https://x/a.jpg'},
      ]).single;
      ImportValidator.validate([nameless], categories: categories, existing: {}, availableImages: {});
      expect(nameless.errors, contains('اسم المنتج مطلوب'));
      expect(nameless.status, ImportRowStatus.error);
    });

    test('matches uploaded image files by name without extension', () {
      final r = row({'images': 'Photos/Front.JPG'});
      ImportValidator.validate([r], categories: categories, existing: {}, availableImages: {'front'});
      expect(r.errors, isEmpty);
    });

    test('existing products are skipped by default and colors of one model get a shared groupId', () {
      final a = row({'productid': 'p1', 'color': 'Black'});
      final b = ImportSanitizer.fromMaps([
        {'productid': 'p2', 'name': 'Top', 'category': 'فساتين', 'price': '100', 'images': 'https://x/a.jpg', 'color': 'Beige'},
      ]).single;
      ImportValidator.validate([a, b], categories: categories, existing: {'p1': 'doc1'}, availableImages: {});
      expect(a.action, ImportAction.skip);
      expect(b.action, ImportAction.create);
      expect(a.groupId, isNotEmpty);
      expect(a.groupId, b.groupId);
    });

    test('duplicate product ids inside the file are errors', () {
      final a = row({});
      final b = row({});
      ImportValidator.validate([a, b], categories: categories, existing: {}, availableImages: {});
      expect(a.errors.last, contains('مكرر'));
    });

    test('toProduct fills the missing language, sizes, order and sums the stock', () {
      final r = row({'nameAr': '', 'stock': 'S:2|M:3', 'colorAr': 'أسود'});
      ImportValidator.validate([r], categories: categories, existing: {}, availableImages: {});
      final p = ImportValidator.toProduct(r, imageUrls: {}, thumbnails: {});
      expect(p.nameAr, 'Top');
      expect(p.quant, 5);
      expect(p.sizes, ['S', 'M']);
      expect(p.cat, 'Dresses');
      expect(p.catAr, 'فساتين');
      expect(p.colors.single.nameAr, 'أسود');
      expect(p.order, 1);
      expect(p.rate, 0);
    });
  });
}
