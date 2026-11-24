import '../../categories/models/category_model.dart';
import '../../products/models/product_model.dart';
import '../models/import_row.dart';
import 'import_sanitizer.dart';

/// Checks rows against the store and fills derived values (category names, ids, group ids).
class ImportValidator {
  ImportValidator._();

  static void validate(
    List<ImportRow> rows, {
    required List<CategoryModel> categories,
    required Map<String, String> existing,
    required Set<String> availableImages,
  }) {
    _fillGroupIds(rows);
    final seenIds = <String, int>{};
    for (final row in rows) {
      seenIds[row.productId] = (seenIds[row.productId] ?? 0) + 1;
    }
    for (final row in rows) {
      row.errors.clear();
      row.warnings
        ..clear()
        ..addAll(row.stockErrors);

      // Hard error: missing name only. Images use placeholder with a warning.
      if (row.name.isEmpty && row.nameAr.isEmpty) {
        row.errors.add('اسم المنتج مطلوب');
      } else if (row.name.isEmpty || row.nameAr.isEmpty) {
        row.warnings.add('الاسم بلغة واحدة فقط، سيُستخدم للغتين');
      }

      final category = matchCategory(categories, row.category);
      if (category != null) {
        // Normalize to the store's canonical names so saves stay consistent.
        row.category = category.name;
        row.categoryName = category.name;
        row.categoryNameAr = category.nameAr;
      } else if (row.category.isNotEmpty) {
        row.categoryName = null;
        row.categoryNameAr = null;
        row.warnings.add('القسم "${row.category}" غير موجود — اختر قسماً من القائمة');
      } else {
        row.categoryName = null;
        row.categoryNameAr = null;
        row.warnings.add('اختر قسماً من القائمة');
      }

      if (row.price <= 0) row.warnings.add('السعر فارغ أو صفر');
      if (row.oldPrice != 0 && row.oldPrice <= row.price) {
        row.warnings.add('السعر قبل الخصم يجب أن يكون أكبر من السعر، أو 0');
      }
      if (row.totalStock <= 0) row.warnings.add('المخزون صفر، سيظهر "نفد المخزون"');
      if (row.resolvedSizes.isEmpty) row.warnings.add('لا توجد مقاسات');
      if (row.colorHex.isNotEmpty && !RegExp(r'^#[0-9A-F]{6}$').hasMatch(row.colorHex)) {
        row.warnings.add('كود اللون "${row.colorHex}" غير صحيح');
      }
      if (row.usedPlaceholderImage || row.images.isEmpty) {
        row.warnings.add('صورة افتراضية — أضف رابطاً أو ارفع ملفاً');
        if (row.images.isEmpty) {
          row.images = [ImportSanitizer.placeholderImage];
          row.usedPlaceholderImage = true;
        }
      }
      for (final name in row.pendingImageNames) {
        if (!availableImages.contains(imageKey(name))) {
          row.errors.add('ارفع الصورة "$name"');
        }
      }

      if ((seenIds[row.productId] ?? 0) > 1) row.errors.add('رقم المنتج "${row.productId}" مكرر في الملف');
      row.exists = existing.containsKey(row.productId);
      if (row.exists && row.action == ImportAction.create) row.action = ImportAction.skip;
      if (!row.exists && row.action == ImportAction.update) row.action = ImportAction.create;
      if (row.exists) row.warnings.add('المنتج موجود في المتجر: اختر تحديثه أو تخطيه');
    }
  }

  /// Matching key for image file names: lowercase, without folders and extension.
  static String imageKey(String name) {
    final base = name.split(RegExp(r'[\\/]')).last.toLowerCase().trim();
    final dot = base.lastIndexOf('.');
    return dot > 0 ? base.substring(0, dot) : base;
  }

  static ProductModel toProduct(ImportRow row, {required Map<String, String> imageUrls, required Map<String, String> thumbnails}) {
    final images = row.images.map((e) => e.startsWith('http') ? e : imageUrls[imageKey(e)] ?? '').where((e) => e.isNotEmpty).toList();
    final resolved = images.isNotEmpty ? images : [ImportSanitizer.placeholderImage];
    final primaryImage = resolved.first;
    final name = row.name.isNotEmpty ? row.name : row.nameAr;
    final nameAr = row.nameAr.isNotEmpty ? row.nameAr : row.name;
    final cat = (row.categoryName ?? row.category).trim().isEmpty
        ? ImportSanitizer.defaultCat
        : (row.categoryName ?? row.category);
    final catAr = (row.categoryNameAr ?? '').trim().isEmpty
        ? (cat == ImportSanitizer.defaultCat ? ImportSanitizer.defaultCatAr : cat)
        : row.categoryNameAr!;
    final brand = row.brand.isEmpty ? ImportSanitizer.defaultBrand : row.brand;
    return ProductModel(
      productId: row.productId,
      name: name,
      nameAr: nameAr,
      des: row.des.isNotEmpty ? row.des : row.desAr,
      desAr: row.desAr.isNotEmpty ? row.desAr : row.des,
      brand: brand,
      cat: cat,
      catAr: catAr,
      image: primaryImage,
      images: resolved,
      thumbnail: thumbnails[primaryImage] ?? '',
      price: row.price,
      oldPrice: row.oldPrice,
      rate: 0,
      quant: row.totalStock > 0 ? row.totalStock : ImportSanitizer.defaultQuant,
      stock: Map<String, num>.from(row.stock),
      sizes: row.resolvedSizes,
      colors: row.color.isEmpty && row.colorAr.isEmpty
          ? const []
          : [
              ProductColorModel(
                name: row.color.isNotEmpty ? row.color : row.colorAr,
                nameAr: row.colorAr.isNotEmpty ? row.colorAr : row.color,
                hex: row.colorHex.isNotEmpty ? row.colorHex : '#1E1E1E',
              ),
            ],
      groupId: row.groupId,
      order: row.order > 0 ? row.order : null,
    );
  }

  /// Matches a file/store label to a Firestore category by English or Arabic name.
  /// Tolerates diacritics, ة/ه, أ/ا, and partial contains either way.
  static CategoryModel? matchCategory(List<CategoryModel> categories, String value) {
    final v = _normLabel(value);
    if (v.isEmpty) return null;
    for (final c in categories) {
      final en = _normLabel(c.name);
      final ar = _normLabel(c.nameAr);
      if (en == v || ar == v) return c;
    }
    CategoryModel? partial;
    for (final c in categories) {
      final en = _normLabel(c.name);
      final ar = _normLabel(c.nameAr);
      final hit = (en.isNotEmpty && (v.contains(en) || en.contains(v))) ||
          (ar.isNotEmpty && (v.contains(ar) || ar.contains(v)));
      if (!hit) continue;
      // Prefer the longest label match to avoid "Bags" matching "Handbags" wrongly in reverse only.
      if (partial == null) {
        partial = c;
        continue;
      }
      final best = _normLabel(partial.nameAr).length > _normLabel(partial.name).length
          ? _normLabel(partial.nameAr).length
          : _normLabel(partial.name).length;
      final cur = ar.length > en.length ? ar.length : en.length;
      if (cur > best) partial = c;
    }
    return partial;
  }

  static String _normLabel(String value) {
    var s = value.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    s = s
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
    return s.replaceAll(RegExp(r'[\s_\-./]+'), '');
  }

  static void _fillGroupIds(List<ImportRow> rows) {
    final byName = <String, List<ImportRow>>{};
    for (final row in rows) {
      final key = (row.name.isNotEmpty ? row.name : row.nameAr).trim().toLowerCase();
      if (key.isNotEmpty) byName.putIfAbsent(key, () => []).add(row);
    }
    for (final entry in byName.entries) {
      if (entry.value.length < 2) continue;
      final slug = entry.key.replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), '_');
      for (final row in entry.value) {
        if (row.groupId.isEmpty) row.groupId = 'g_$slug';
      }
    }
  }
}
