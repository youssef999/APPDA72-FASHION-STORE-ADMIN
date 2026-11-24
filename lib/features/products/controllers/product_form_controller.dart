import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../../categories/models/category_model.dart';
import '../../categories/repositories/categories_repository.dart';
import '../../media/controllers/image_editor_controller.dart';
import '../models/product_model.dart';
import '../models/shop_the_look_model.dart';
import '../models/size_guide_model.dart';
import '../repositories/products_repository.dart';
import '../services/stock_waitlist_notifier.dart';

class ColorDraft {
  final TextEditingController name;
  final TextEditingController nameAr;
  final TextEditingController hex;

  ColorDraft([ProductColorModel? color])
      : name = TextEditingController(text: color?.name ?? ''),
        nameAr = TextEditingController(text: color?.nameAr ?? ''),
        hex = TextEditingController(text: color?.hex ?? '#1C1B1F');

  void dispose() {
    name.dispose();
    nameAr.dispose();
    hex.dispose();
  }
}

class StockDraft {
  final TextEditingController size;
  final TextEditingController quantity;

  StockDraft([String size = '', num quantity = 0])
      : size = TextEditingController(text: size),
        quantity = TextEditingController(text: '$quantity');

  void dispose() {
    size.dispose();
    quantity.dispose();
  }
}

class SizeGuideRowDraft {
  final TextEditingController size;
  final TextEditingController width;
  final TextEditingController length;
  final TextEditingController minHeight;
  final TextEditingController maxHeight;
  final TextEditingController minWeight;
  final TextEditingController maxWeight;

  SizeGuideRowDraft([SizeGuideRowModel? row])
      : size = TextEditingController(text: row?.size ?? ''),
        width = TextEditingController(text: row == null ? '' : '${row.width}'),
        length = TextEditingController(text: row == null ? '' : '${row.length}'),
        minHeight = TextEditingController(text: row?.minHeight?.toString() ?? ''),
        maxHeight = TextEditingController(text: row?.maxHeight?.toString() ?? ''),
        minWeight = TextEditingController(text: row?.minWeight?.toString() ?? ''),
        maxWeight = TextEditingController(text: row?.maxWeight?.toString() ?? '');

  void dispose() {
    for (final c in [size, width, length, minHeight, maxHeight, minWeight, maxWeight]) {
      c.dispose();
    }
  }
}

class LookPinDraft {
  double x;
  double y;
  String productId;
  final TextEditingController role;
  final TextEditingController roleAr;
  final String id;

  LookPinDraft({
    required this.id,
    required this.x,
    required this.y,
    this.productId = '',
    String role = '',
    String roleAr = '',
  })  : role = TextEditingController(text: role),
        roleAr = TextEditingController(text: roleAr);

  factory LookPinDraft.fromModel(LookPinModel pin) => LookPinDraft(
        id: pin.id,
        x: pin.x,
        y: pin.y,
        productId: pin.productId,
        role: pin.role,
        roleAr: pin.roleAr,
      );

  void dispose() {
    role.dispose();
    roleAr.dispose();
  }
}

class ProductFormController extends GetxController {
  static const String colorsId = 'product_colors';
  static const String stockId = 'product_stock';
  static const String imagesId = 'product_images';
  static const String sizeGuideId = 'product_size_guide';
  static const String lookId = 'product_look';

  final ProductsRepository _repository = ProductsRepository();
  final CategoriesRepository _categoriesRepository = CategoriesRepository();
  final name = TextEditingController();
  final nameAr = TextEditingController();
  final des = TextEditingController();
  final desAr = TextEditingController();
  final price = TextEditingController();
  final oldPrice = TextEditingController(text: '0');
  final quant = TextEditingController(text: '0');
  final groupId = TextEditingController();
  final productId = TextEditingController();
  final fabricTag = TextEditingController();

  final List<ColorDraft> colors = [];
  final List<StockDraft> stock = [];
  final List<SizeGuideRowDraft> sizeGuideRows = [];
  final List<LookPinDraft> lookPins = [];
  List<CategoryModel> categories = [];
  List<ProductModel> productOptions = [];
  String? selectedCategory;

  ProductModel? original;
  bool isLoading = true;
  bool isSaving = false;
  bool isUploading = false;

  final List<String> imageUrls = [];
  final Map<String, String> _thumbnails = {};

  bool sizeGuideEnabled = false;
  String fitType = ProductModel.fitRegular;
  String sizeGuideImage = 'assets/images/size_guide_dresses.jpg';

  bool lookEnabled = false;
  int lookImageIndex = 0;

  bool isBestSeller = false;
  num soldCount = 0;

  /// Merchant-friendly: size guide + shop-the-look stay behind this toggle.
  bool showAdvanced = false;

  bool get isEditing => original != null;

  void toggleAdvanced(bool value) {
    showAdvanced = value;
    update();
  }

  num get totalStock => stock.isEmpty
      ? Formatters.toNum(quant.text)
      : stock.fold<num>(0, (sum, row) => sum + Formatters.toNum(row.quantity.text));

  @override
  void onInit() {
    super.onInit();
    _load(Get.parameters['id']);
  }

  Future<void> _load(String? docId) async {
    try {
      categories = await _categoriesRepository.watchCategories().first;
      productOptions = await _repository.watchProducts().first;
      if (docId != null && docId.isNotEmpty) {
        final product = await _repository.getById(docId);
        if (product != null) _fill(product);
      }
      if (original == null) {
        productId.text = 'p_${DateTime.now().millisecondsSinceEpoch}';
        colors.add(ColorDraft());
        stock.addAll(['S', 'M', 'L'].map((s) => StockDraft(s)));
      }
    } catch (e) {
      AppSnackbar.show('تعذر تحميل البيانات: $e', type: AppSnackbarType.error);
    }
    isLoading = false;
    update();
  }

  void _fill(ProductModel p) {
    original = p;
    name.text = p.name;
    nameAr.text = p.nameAr;
    des.text = p.des;
    desAr.text = p.desAr;
    price.text = '${p.price}';
    oldPrice.text = '${p.oldPrice}';
    quant.text = '${p.quant}';
    imageUrls.addAll({if (p.image.isNotEmpty) p.image, ...p.images.where((e) => e.isNotEmpty)});
    if (p.thumbnail.isNotEmpty && p.image.isNotEmpty) _thumbnails[p.image] = p.thumbnail;
    groupId.text = p.groupId;
    productId.text = p.productId;
    fabricTag.text = p.fabricTag;
    isBestSeller = p.isBestSeller;
    soldCount = p.soldCount;
    selectedCategory = p.cat;
    colors.addAll(p.colors.map(ColorDraft.new));
    final sizes = p.sizes.isNotEmpty ? p.sizes : p.stock.keys.toList();
    stock.addAll(sizes.map((s) => StockDraft(s, p.stock[s] ?? 0)));
    fitType = p.fitType;
    final guide = p.sizeGuide;
    sizeGuideEnabled = guide != null;
    if (guide != null) {
      sizeGuideImage = guide.image.isNotEmpty ? guide.image : sizeGuideImage;
      sizeGuideRows.addAll(guide.rows.map(SizeGuideRowDraft.new));
    }
    final look = p.shopTheLook;
    lookEnabled = look != null;
    if (look != null) {
      lookImageIndex = look.imageIndex;
      lookPins.addAll(look.pins.map(LookPinDraft.fromModel));
    }
  }

  void selectCategory(String? value) {
    selectedCategory = value;
    update();
  }

  void addColor() {
    colors.add(ColorDraft());
    update([colorsId]);
  }

  void removeColor(int index) {
    colors.removeAt(index).dispose();
    update([colorsId]);
  }

  void refreshColors() => update([colorsId]);

  void addSize() {
    stock.add(StockDraft());
    update([stockId]);
  }

  void removeSize(int index) {
    stock.removeAt(index).dispose();
    update([stockId]);
  }

  void refreshStock() => update([stockId]);
  void refreshImages() => update([imagesId]);

  void toggleSizeGuide() {
    sizeGuideEnabled = !sizeGuideEnabled;
    if (sizeGuideEnabled && sizeGuideRows.isEmpty) {
      for (final row in stock.where((r) => r.size.text.trim().isNotEmpty)) {
        sizeGuideRows.add(SizeGuideRowDraft(SizeGuideRowModel(size: row.size.text.trim(), width: 0, length: 0)));
      }
      if (sizeGuideRows.isEmpty) sizeGuideRows.add(SizeGuideRowDraft());
    }
    update([sizeGuideId]);
  }

  void setFitType(String? value) {
    if (value == null) return;
    fitType = value;
    update([sizeGuideId]);
  }

  void toggleBestSeller(bool? value) {
    isBestSeller = value ?? false;
    update();
  }

  void setSizeGuideImage(String value) {
    sizeGuideImage = value;
    update([sizeGuideId]);
  }

  void addSizeGuideRow() {
    sizeGuideRows.add(SizeGuideRowDraft());
    update([sizeGuideId]);
  }

  void removeSizeGuideRow(int index) {
    sizeGuideRows.removeAt(index).dispose();
    update([sizeGuideId]);
  }

  void toggleLook() {
    lookEnabled = !lookEnabled;
    update([lookId]);
  }

  void setLookImageIndex(int index) {
    lookImageIndex = index;
    update([lookId]);
  }

  void addLookPin(double x, double y) {
    lookPins.add(LookPinDraft(
      id: 'pin_${DateTime.now().microsecondsSinceEpoch}',
      x: x,
      y: y,
    ));
    update([lookId]);
  }

  void setLookPinProduct(int index, String productId) {
    lookPins[index].productId = productId;
    update([lookId]);
  }

  void removeLookPin(int index) {
    lookPins.removeAt(index).dispose();
    update([lookId]);
  }

  Future<void> uploadImages() async {
    if (isUploading) return;
    isUploading = true;
    update([imagesId]);
    try {
      final uploaded = await ImageEditorController.pickEditUpload(
        kind: ImageKind.product,
        ownerId: productId.text.trim(),
        multiple: true,
      );
      for (final image in uploaded) {
        imageUrls.add(image.url);
        _thumbnails[image.url] = image.thumbnailUrl;
      }
    } catch (e) {
      AppSnackbar.show('تعذر رفع الصور: $e', type: AppSnackbarType.error);
    } finally {
      isUploading = false;
      update([imagesId, lookId]);
    }
  }

  void addImageUrl(String url) {
    if (!imageUrls.contains(url)) imageUrls.add(url);
    update([imagesId, lookId]);
  }

  void reorderImages(int oldIndex, int newIndex) {
    imageUrls.insert(newIndex, imageUrls.removeAt(oldIndex));
    update([imagesId, lookId]);
  }

  void removeImage(String url) {
    imageUrls.remove(url);
    update([imagesId, lookId]);
  }

  SizeGuideModel? _buildSizeGuide() {
    if (!sizeGuideEnabled) return null;
    final rows = sizeGuideRows
        .where((r) => r.size.text.trim().isNotEmpty)
        .map(
          (r) => SizeGuideRowModel(
            size: r.size.text.trim(),
            width: Formatters.toNum(r.width.text),
            length: Formatters.toNum(r.length.text),
            minHeight: r.minHeight.text.trim().isEmpty ? null : Formatters.toNum(r.minHeight.text),
            maxHeight: r.maxHeight.text.trim().isEmpty ? null : Formatters.toNum(r.maxHeight.text),
            minWeight: r.minWeight.text.trim().isEmpty ? null : Formatters.toNum(r.minWeight.text),
            maxWeight: r.maxWeight.text.trim().isEmpty ? null : Formatters.toNum(r.maxWeight.text),
          ),
        )
        .toList();
    if (rows.isEmpty) return null;
    return SizeGuideModel(image: sizeGuideImage, rows: rows);
  }

  ShopTheLookModel? _buildLook() {
    if (!lookEnabled) return null;
    final pins = lookPins
        .where((p) => p.productId.isNotEmpty)
        .map(
          (p) => LookPinModel(
            id: p.id,
            x: p.x,
            y: p.y,
            productId: p.productId,
            role: p.role.text.trim(),
            roleAr: p.roleAr.text.trim(),
          ),
        )
        .toList();
    if (pins.isEmpty) return null;
    return ShopTheLookModel(
      imageIndex: imageUrls.isEmpty ? 0 : lookImageIndex.clamp(0, imageUrls.length - 1),
      pins: pins,
    );
  }

  Future<void> save() async {
    final error = _validate();
    if (error != null) {
      AppSnackbar.show(error, type: AppSnackbarType.error);
      return;
    }
    final category = categories.firstWhereOrNull((c) => c.name == selectedCategory);
    final id = productId.text.trim();
    isSaving = true;
    update();
    try {
      if (!isEditing && await _repository.productIdExists(id)) {
        throw 'رقم المنتج "$id" مستخدم بالفعل';
      }
      final rows = stock.where((row) => row.size.text.trim().isNotEmpty).toList();
      final mainImage = imageUrls.first;
      final guide = _buildSizeGuide();
      final look = _buildLook();
      final nextStock = <String, num>{
        for (final row in rows) row.size.text.trim(): Formatters.toNum(row.quantity.text),
      };
      final previousStock = Map<String, num>.from(original?.stock ?? const {});
      await _repository.save(ProductModel(
        docId: original?.docId ?? '',
        productId: id,
        name: name.text.trim(),
        nameAr: nameAr.text.trim(),
        des: des.text.trim(),
        desAr: desAr.text.trim(),
        brand: original?.brand ?? '',
        cat: category?.name ?? selectedCategory ?? '',
        catAr: category?.nameAr ?? original?.catAr ?? '',
        image: mainImage,
        images: List<String>.from(imageUrls),
        thumbnail: _thumbnails[mainImage] ?? '',
        price: Formatters.toNum(price.text),
        oldPrice: Formatters.toNum(oldPrice.text),
        rate: original?.rate ?? 0,
        quant: totalStock,
        stock: nextStock,
        sizes: rows.map((row) => row.size.text.trim()).toList(),
        colors: colors
            .where((c) => c.name.text.trim().isNotEmpty)
            .map((c) => ProductColorModel(name: c.name.text.trim(), nameAr: c.nameAr.text.trim(), hex: c.hex.text.trim()))
            .toList(),
        groupId: groupId.text.trim(),
        sizeGuide: guide,
        fitType: fitType,
        fabricTag: fabricTag.text.trim().toLowerCase(),
        isBestSeller: isBestSeller,
        soldCount: original?.soldCount ?? soldCount,
        order: original?.order,
        shopTheLook: look,
        dropId: original?.dropId ?? '',
        visibleFrom: original?.visibleFrom,
        clearSizeGuide: !sizeGuideEnabled || guide == null,
        clearShopTheLook: !lookEnabled || look == null,
      ));
      if (isEditing) {
        await StockWaitlistNotifier.notifyRestocked(
          productId: id,
          productName: name.text.trim(),
          productNameAr: nameAr.text.trim(),
          previousStock: previousStock,
          nextStock: nextStock,
        );
      }
      AppSnackbar.show(isEditing ? 'تم تحديث المنتج' : 'تمت إضافة المنتج');
      Get.offNamed(AppRoutes.products);
    } catch (e) {
      AppSnackbar.show('تعذر حفظ المنتج: $e', type: AppSnackbarType.error);
    } finally {
      isSaving = false;
      update();
    }
  }

  String? _validate() {
    if (name.text.trim().isEmpty || nameAr.text.trim().isEmpty) return 'اكتب اسم المنتج بالعربي والإنجليزي';
    if (selectedCategory == null) return 'اختر القسم';
    if (productId.text.trim().isEmpty) return 'رقم المنتج مطلوب';
    final p = Formatters.toNum(price.text);
    if (p <= 0) return 'السعر يجب أن يكون أكبر من صفر';
    final old = Formatters.toNum(oldPrice.text);
    if (old != 0 && old <= p) return 'السعر قبل الخصم يجب أن يكون أكبر من السعر الحالي، أو 0 بدون خصم';
    final sizes = stock.map((r) => r.size.text.trim()).where((s) => s.isNotEmpty).toList();
    if (sizes.toSet().length != sizes.length) return 'يوجد مقاس مكرر';
    if (isUploading) return 'انتظر حتى يكتمل رفع الصور';
    if (imageUrls.isEmpty) return 'أضف صورة واحدة على الأقل من جهازك أو برابط';
    if (lookEnabled && lookPins.any((p) => p.productId.isEmpty)) return 'اربط كل نقاط الإطلالة بمنتج';
    return null;
  }

  @override
  void onClose() {
    for (final c in [name, nameAr, des, desAr, price, oldPrice, quant, groupId, productId, fabricTag]) {
      c.dispose();
    }
    for (final c in colors) {
      c.dispose();
    }
    for (final s in stock) {
      s.dispose();
    }
    for (final r in sizeGuideRows) {
      r.dispose();
    }
    for (final p in lookPins) {
      p.dispose();
    }
    super.onClose();
  }
}
