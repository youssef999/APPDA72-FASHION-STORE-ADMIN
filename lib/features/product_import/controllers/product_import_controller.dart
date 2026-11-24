import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../core/services/background_removal_service.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/utils/web_download.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../categories/models/category_model.dart';
import '../models/import_row.dart';
import '../parsers/column_mapper.dart';
import '../parsers/docx_parser.dart';
import '../parsers/import_template.dart';
import '../parsers/spreadsheet_parser.dart';
import '../repositories/product_import_repository.dart';
import '../services/gemini_product_extractor.dart';
import '../services/import_sanitizer.dart';
import '../services/import_validator.dart';
import '../widgets/import_row_dialog.dart';

enum ImportPhase { upload, mapping, preview, saving, done }

enum PreviewFilter { all, ready, warning, error }

class ProductImportController extends GetxController {
  static const String listId = 'import_list';
  static const String progressId = 'import_progress';
  static const String mappingId = 'import_mapping';

  final ProductImportRepository _repository = ProductImportRepository();
  final TextEditingController sheetLink = TextEditingController();

  ImportPhase phase = ImportPhase.upload;
  bool isLoadingContext = true;
  bool isParsing = false;
  String? status;
  String sourceName = '';

  List<CategoryModel> categories = [];
  Map<String, String> _existing = {};
  List<ImportRow> rows = [];

  ParsedSheet? parsedSheet;
  Map<String, String?> columnMapping = {};

  PreviewFilter previewFilter = PreviewFilter.all;

  final Map<String, PickedImage> images = {};
  bool removeBackground = false;

  int progressDone = 0;
  int progressTotal = 0;
  String progressLabel = '';
  int savedCount = 0;

  int get readyCount => rows.where((r) => r.status == ImportRowStatus.ready && r.action != ImportAction.skip).length;
  int get warningCount => rows.where((r) => r.status == ImportRowStatus.warning && r.action != ImportAction.skip).length;
  int get errorCount => rows.where((r) => r.status == ImportRowStatus.error && r.action != ImportAction.skip).length;
  int get saveReadyCount => rows.where((r) => r.isValid && r.action != ImportAction.skip).length;
  int get updateCount => rows.where((r) => r.isValid && r.action == ImportAction.update).length;
  int get existingCount => rows.where((r) => r.exists).length;
  int get matchedImages => rows.expand((r) => r.pendingImageNames).where((n) => images.containsKey(ImportValidator.imageKey(n))).length;
  int get neededImages => rows.expand((r) => r.pendingImageNames).length;
  List<String> get categoryNames => categories.map((c) => c.nameAr.isNotEmpty ? c.nameAr : c.name).toList();

  List<String> get fileHeaders =>
      (parsedSheet?.headers ?? const []).where((h) => h.trim().isNotEmpty).toSet().toList();

  List<ImportRow> get filteredRows {
    switch (previewFilter) {
      case PreviewFilter.ready:
        return rows.where((r) => r.status == ImportRowStatus.ready).toList();
      case PreviewFilter.warning:
        return rows.where((r) => r.status == ImportRowStatus.warning).toList();
      case PreviewFilter.error:
        return rows.where((r) => r.status == ImportRowStatus.error).toList();
      case PreviewFilter.all:
        return rows;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadContext();
  }

  Future<void> _loadContext() async {
    try {
      final context = await _repository.loadContext();
      categories = context.categories;
      _existing = context.existing;
    } catch (e) {
      AppSnackbar.show('تعذر تحميل الأقسام والمنتجات: $e', type: AppSnackbarType.error);
    }
    isLoadingContext = false;
    update();
  }

  void downloadTemplate() => downloadBytes(
        ImportTemplate.build(categoryNames: categories.map((c) => c.name).toList()),
        ImportTemplate.fileName,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

  void downloadCsvTemplate() {
    final cats = categories.map((c) => c.name).toList();
    final category = cats.isNotEmpty ? cats.first : 'Dresses';
    final header = ImportColumns.template.join(',');
    final example =
        ',,Linen Midi Dress,فستان ميدي كتان,Breathable linen,فستان كتان,Demo Brand,$category,450,600,Beige,بيج,#D8C3A5,S:5|M:8|L:3,50,https://placehold.co/600x800/png?text=Sample';
    final bytes = utf8.encode('\uFEFF$header\n$example\n');
    downloadBytes(Uint8List.fromList(bytes), 'products_import_template.csv', 'text/csv;charset=utf-8');
  }

  Future<void> pickFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'csv', 'docx', 'pdf', 'txt'],
    );
    if (file == null) return;
    late final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e, st) {
      debugPrint('file readAsBytes failed: $e\n$st');
      AppSnackbar.show('تعذر قراءة الملف: $e', type: AppSnackbarType.error);
      return;
    }
    if (bytes.isEmpty) {
      AppSnackbar.show('الملف فارغ', type: AppSnackbarType.error);
      return;
    }
    final ext = (file.extension ?? '').toLowerCase();
    await _openSource(file.name, () async {
      switch (ext) {
        case 'xlsx':
          final sheet = SpreadsheetParser.parseXlsxSheet(bytes);
          if (sheet != null && !sheet.isEmpty) return _SheetResult.sheet(sheet);
          debugPrint('xlsx mapped 0 rows; falling back to AI (${bytes.length} bytes)');
          return _SheetResult.maps(await _askAi(SpreadsheetParser.parseXlsxAsText(bytes)));
        case 'csv':
          final sheet = SpreadsheetParser.parseCsvBytesSheet(bytes);
          if (sheet != null && !sheet.isEmpty) return _SheetResult.sheet(sheet);
          return _SheetResult.maps(await _askAi(utf8.decode(bytes, allowMalformed: true)));
        case 'docx':
          final content = DocxParser.parse(bytes);
          if (content.tableRows.isNotEmpty) return _SheetResult.maps(content.tableRows);
          return _SheetResult.maps(await _askAi(content.text));
        case 'pdf':
          _setStatus('الذكاء الاصطناعي يقرأ ملف PDF...');
          return _SheetResult.maps(await GeminiProductExtractor.fromPdf(bytes, categoryNames));
        case 'txt':
          return _SheetResult.maps(await _askAi(utf8.decode(bytes, allowMalformed: true)));
        default:
          throw 'صيغة غير مدعومة. استخدم xlsx أو csv أو docx أو pdf';
      }
    });
  }

  Future<void> importSheet() async {
    final link = sheetLink.text.trim();
    if (link.isEmpty) return;
    await _openSource('Google Sheets', () async {
      final sheet = await SpreadsheetParser.fetchGoogleSheetParsed(link);
      if (sheet != null && !sheet.isEmpty) return _SheetResult.sheet(sheet);
      throw 'لم يتم العثور على صفوف في الشيت';
    });
  }

  Future<List<Map<String, String>>> _askAi(String text) {
    if (text.trim().isEmpty) throw 'الملف لا يحتوي على نص يمكن قراءته';
    _setStatus('الذكاء الاصطناعي يستخرج المنتجات...');
    return GeminiProductExtractor.fromText(
      text,
      categoryNames,
      onChunk: (done, total) => _setStatus('الذكاء الاصطناعي يستخرج المنتجات... الجزء $done من $total'),
    );
  }

  Future<void> _openSource(String name, Future<_SheetResult> Function() task) async {
    if (isParsing) return;
    isParsing = true;
    sourceName = name;
    _setStatus('جاري قراءة الملف...');
    try {
      final result = await task();
      if (result.sheet != null) {
        parsedSheet = result.sheet;
        columnMapping = Map<String, String?>.from(result.sheet!.suggestedMapping);
        phase = ImportPhase.mapping;
        AppSnackbar.show('تم اكتشاف ${result.sheet!.dataRows.length} صف — راجع ربط الأعمدة');
      } else {
        parsedSheet = null;
        columnMapping = {};
        _buildRowsFromMaps(result.maps!);
        phase = ImportPhase.preview;
        AppSnackbar.show('تمت قراءة ${rows.length} منتج');
      }
    } catch (e, st) {
      debugPrint('product import open failed: $e\n$st');
      AppSnackbar.show('$e', type: AppSnackbarType.error);
    } finally {
      isParsing = false;
      status = null;
      update();
    }
  }

  void setColumnMapping(String field, String? header) {
    columnMapping[field] = header;
    update();
  }

  void confirmMapping() {
    final sheet = parsedSheet;
    if (sheet == null) {
      AppSnackbar.show('لا توجد بيانات لربطها', type: AppSnackbarType.error);
      return;
    }
    try {
      final maps = sheet.applyMapping(columnMapping);
      if (maps.isEmpty) throw 'لم ينتج أي صف من الربط الحالي — اختر أعمدة الاسم على الأقل';
      _buildRowsFromMaps(maps);
      phase = ImportPhase.preview;
      AppSnackbar.show('جاهز للمراجعة: ${rows.length} منتج');
      update();
    } catch (e, st) {
      debugPrint('confirmMapping failed: $e\n$st');
      AppSnackbar.show('$e', type: AppSnackbarType.error);
    }
  }

  void backToMapping() {
    if (parsedSheet == null) {
      phase = ImportPhase.upload;
    } else {
      phase = ImportPhase.mapping;
    }
    update();
  }

  void backToUpload() {
    parsedSheet = null;
    columnMapping = {};
    rows = [];
    phase = ImportPhase.upload;
    update();
  }

  void _buildRowsFromMaps(List<Map<String, String>> maps) {
    rows = ImportSanitizer.fromMaps(maps);
    _validate();
  }

  void _setStatus(String value) {
    status = value;
    update();
  }

  void _validate() => ImportValidator.validate(
        rows,
        categories: categories,
        existing: _existing,
        availableImages: images.keys.toSet(),
      );

  void _revalidate() {
    _validate();
    update([listId]);
    update();
  }

  void setPreviewFilter(PreviewFilter filter) {
    previewFilter = filter;
    update([listId]);
  }

  Future<void> pickImages() async {
    try {
      final picked = await ImageUploadService.pick(multiple: true);
      for (final image in picked) {
        images[ImportValidator.imageKey(image.name)] = image;
      }
      _revalidate();
    } catch (e) {
      AppSnackbar.show('$e', type: AppSnackbarType.error);
    }
  }

  void toggleRemoveBackground(bool value) {
    removeBackground = value;
    update();
  }

  void setAction(int index, ImportAction action) {
    rows[index].action = action;
    update([listId]);
  }

  void setExistingAction(ImportAction action) {
    for (final row in rows.where((r) => r.exists)) {
      row.action = action;
    }
    update([listId]);
    update();
  }

  void removeRow(int index) {
    rows.removeAt(index);
    _revalidate();
  }

  void updateRowField(int index, String field, String value) {
    if (index < 0 || index >= rows.length) return;
    final row = rows[index];
    switch (field) {
      case 'name':
        row.name = value;
      case 'nameAr':
        row.nameAr = value;
      case 'des':
        row.des = value;
      case 'desAr':
        row.desAr = value;
      case 'price':
        row.price = num.tryParse(value.replaceAll(RegExp(r'[^\d.\-]'), '')) ?? 0;
      case 'images':
        row.images = value.split(RegExp(r'[\n|,;]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        row.usedPlaceholderImage = row.images.isEmpty ||
            (row.images.length == 1 && row.images.first == ImportSanitizer.placeholderImage);
      case 'category':
        row.category = value;
      case 'quantity':
      case 'quant':
        row.quantity = num.tryParse(value.replaceAll(RegExp(r'[^\d.\-]'), '')) ?? 0;
      case 'stock':
        final trimmed = value.trim();
        if (RegExp(r'^\d+(\.\d+)?$').hasMatch(trimmed.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m.group(0)!.codeUnitAt(0) - 0x0660}'))) {
          row.quantity = num.tryParse(trimmed.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m.group(0)!.codeUnitAt(0) - 0x0660}')) ?? row.quantity;
          row.sizes = [];
          row.stock = {};
        } else if (trimmed.contains(':') || trimmed.contains('=')) {
          row.setStockText(trimmed);
        } else {
          row.sizes = trimmed.split(RegExp(r'[,،\-/|]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          row.stock = {};
        }
    }
    _validate();
    update([listId]);
  }

  /// Assigns a store category (by English [name]) to a preview row and revalidates.
  void setRowCategory(int index, String? categoryName) {
    if (index < 0 || index >= rows.length || categoryName == null || categoryName.isEmpty) return;
    rows[index].category = categoryName;
    _validate();
    update([listId]);
  }

  /// Applies one store category to every row that still has no matched category.
  void applyCategoryToUnmatched(String? categoryName) {
    if (categoryName == null || categoryName.isEmpty) return;
    var changed = 0;
    for (final row in rows) {
      if (ImportValidator.matchCategory(categories, row.category) != null) continue;
      row.category = categoryName;
      changed++;
    }
    if (changed == 0) return;
    _validate();
    update([listId]);
    update();
    AppSnackbar.show('تم تعيين القسم لـ $changed منتج');
  }

  // ---- Row editing dialog ------------------------------------------------

  ImportRow? editing;
  final Map<String, TextEditingController> fields = {};
  String? editingCategory;

  void editRow(int index) {
    final row = rows[index];
    editing = row;
    editingCategory = row.categoryName ?? row.category;
    final values = {
      'nameAr': row.nameAr, 'name': row.name, 'desAr': row.desAr, 'des': row.des,
      'price': '${row.price}', 'oldPrice': '${row.oldPrice}', 'colorAr': row.colorAr, 'color': row.color,
      'colorHex': row.colorHex, 'stock': row.stockText, 'quant': '${row.quantity}', 'images': row.images.join('\n'),
      'groupId': row.groupId,
    };
    for (final e in values.entries) {
      (fields[e.key] ??= TextEditingController()).text = e.value;
    }
    Get.dialog(const ImportRowDialog());
  }

  void setEditingCategory(String? value) {
    editingCategory = value;
    update([ImportRowDialog.id]);
  }

  void saveEdit() {
    final row = editing;
    if (row == null) return;
    String f(String key) => fields[key]!.text.trim();
    row
      ..nameAr = f('nameAr')
      ..name = f('name')
      ..desAr = f('desAr')
      ..des = f('des')
      ..price = num.tryParse(f('price')) ?? 0
      ..oldPrice = num.tryParse(f('oldPrice')) ?? 0
      ..colorAr = f('colorAr')
      ..color = f('color')
      ..colorHex = f('colorHex').toUpperCase()
      ..quantity = num.tryParse(f('quant')) ?? ImportSanitizer.defaultQuant
      ..groupId = f('groupId')
      ..images = f('images').split(RegExp(r'[\n|]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
      ..usedPlaceholderImage = false;
    final stock = f('stock');
    final stockWestern = stock.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m.group(0)!.codeUnitAt(0) - 0x0660}');
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(stockWestern)) {
      row.quantity = num.tryParse(stockWestern) ?? row.quantity;
      row.sizes = [];
      row.stock = {};
    } else if (stock.contains(':') || stock.contains('=')) {
      row.setStockText(stock);
    } else {
      row.sizes = stock.split(RegExp(r'[,،\-/|]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      row.stock = {};
    }
    if (editingCategory != null) row.category = editingCategory!;
    Get.back();
    _revalidate();
  }

  // ---- Saving ------------------------------------------------------------

  Future<void> commit() async {
    _validate();
    final toSave = rows.where((r) => r.isValid && r.action != ImportAction.skip).toList();
    if (toSave.isEmpty) {
      AppSnackbar.show('لا توجد منتجات جاهزة للحفظ', type: AppSnackbarType.error);
      update();
      return;
    }
    final confirmed = await AppConfirmDialog.show(
      title: 'حفظ المنتجات',
      message: 'سيتم حفظ ${toSave.length} منتج'
          '${updateCount > 0 ? ' (منها $updateCount تحديث لمنتجات موجودة)' : ''}'
          '${errorCount > 0 ? '، وتجاهل $errorCount صف به أخطاء' : ''}.',
      confirmLabel: 'حفظ',
    );
    if (!confirmed) return;

    phase = ImportPhase.saving;
    update();
    try {
      final urls = <String, String>{};
      final thumbs = <String, String>{};
      final needed = toSave.expand((r) => r.pendingImageNames).map(ImportValidator.imageKey).toSet().toList();
      _progress('رفع وضغط الصور', 0, needed.length);
      for (var i = 0; i < needed.length; i++) {
        final file = images[needed[i]]!;
        var bytes = file.bytes;
        if (removeBackground) {
          bytes = await BackgroundRemovalService.whiteBackground(
            await ImageUploadService.prepareForEditing(bytes),
            onProgress: (p) => _progress('تحميل نموذج تفريغ الخلفية $p%', i, needed.length),
          );
        }
        final owner = toSave.firstWhere((r) => r.pendingImageNames.map(ImportValidator.imageKey).contains(needed[i])).productId;
        final uploaded = await ImageUploadService.uploadProductImage(bytes, owner);
        urls[needed[i]] = uploaded.url;
        thumbs[uploaded.url] = uploaded.thumbnailUrl;
        _progress('رفع وضغط الصور', i + 1, needed.length);
      }

      final products = toSave.map((r) => ImportValidator.toProduct(r, imageUrls: urls, thumbnails: thumbs)).toList();
      _progress('جاري رفع المنتجات…', 0, products.length);
      await _repository.save(products, _existing, onProgress: (done) => _progress('جاري رفع المنتجات… $done / ${products.length}', done, products.length));
      savedCount = products.length;
      phase = ImportPhase.done;
    } catch (e, st) {
      debugPrint('import commit failed: $e\n$st');
      phase = ImportPhase.preview;
      AppSnackbar.show('توقف الحفظ: $e', type: AppSnackbarType.error);
    }
    update();
  }

  void _progress(String label, int done, int total) {
    progressLabel = label;
    progressDone = done;
    progressTotal = total;
    update([progressId]);
  }

  void reset() {
    rows = [];
    images.clear();
    sheetLink.clear();
    parsedSheet = null;
    columnMapping = {};
    previewFilter = PreviewFilter.all;
    savedCount = 0;
    phase = ImportPhase.upload;
    _loadContext();
  }

  @override
  void onClose() {
    sheetLink.dispose();
    for (final c in fields.values) {
      c.dispose();
    }
    super.onClose();
  }
}

class _SheetResult {
  final ParsedSheet? sheet;
  final List<Map<String, String>>? maps;

  _SheetResult.sheet(ParsedSheet this.sheet) : maps = null;
  _SheetResult.maps(List<Map<String, String>> this.maps) : sheet = null;
}
