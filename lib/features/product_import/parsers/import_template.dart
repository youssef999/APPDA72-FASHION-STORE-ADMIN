import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'column_mapper.dart';

/// Builds the downloadable Excel template: a products sheet with two example rows and an instructions sheet.
class ImportTemplate {
  ImportTemplate._();

  static const String fileName = 'the_hatch_products_template.xlsx';

  static Uint8List build({List<String> categoryNames = const []}) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'Products');
    final products = excel['Products'];
    products.appendRow(ImportColumns.template.map((c) => TextCellValue(c)).toList());
    final category = categoryNames.isNotEmpty ? categoryNames.first : 'Dresses';
    for (final example in [
      ['', 'g_linen_midi', 'Linen Midi Dress', 'فستان ميدي كتان', 'Breathable linen midi dress', 'فستان ميدي من الكتان',
        'Demo Brand', category, '450', '600', 'Beige', 'بيج', '#D8C3A5', 'S:5|M:8|L:3', '16', 'linen_beige_1.jpg|linen_beige_2.jpg'],
      ['', 'g_linen_midi', 'Linen Midi Dress', 'فستان ميدي كتان', 'Breathable linen midi dress', 'فستان ميدي من الكتان',
        'Demo Brand', category, '450', '0', 'Black', 'أسود', '#1C1B1F', 'S:2|M:4|L:0', '6', 'https://example.com/linen_black.jpg'],
    ]) {
      products.appendRow(example.map((v) => TextCellValue(v)).toList());
    }

    final help = excel['Instructions'];
    for (final line in [
      ['العمود', 'الشرح'],
      ['productid', 'اختياري. يُولّد تلقائياً إن تُرك فارغاً. إن كان موجوداً تختار تحديثه أو تخطيه'],
      ['groupId', 'نفس القيمة لكل ألوان نفس الموديل (كل لون = صف مستقل)'],
      ['name / nameAr', 'الاسم بالإنجليزي والعربي (واحد منهما على الأقل)'],
      ['category', 'اسم القسم كما هو في اللوحة (عربي أو إنجليزي): ${categoryNames.join('، ')}'],
      ['price / oldPrice', 'السعر الحالي، والسعر قبل الخصم (0 = بدون خصم، ويجب أن يكون أكبر من السعر)'],
      ['color / colorAr / colorHex', 'اسم اللون وكوده مثل #1C1B1F'],
      ['stock', 'المقاسات والكمية مثل S:5|M:8|L:3 ، أو اتركه فارغاً واستخدم عمود quant'],
      ['images', 'روابط أو أسماء ملفات مفصولة بـ | . أسماء الملفات تُطابق مع الصور التي ترفعها في صفحة الاستيراد'],
    ]) {
      help.appendRow(line.map((v) => TextCellValue(v)).toList());
    }
    excel.setDefaultSheet('Products');
    return Uint8List.fromList(excel.encode()!);
  }
}
