import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/formatters.dart';
import 'shop_the_look_model.dart';
import 'size_guide_model.dart';

class ProductColorModel {
  final String name;
  final String nameAr;
  final String hex;

  const ProductColorModel({required this.name, required this.nameAr, required this.hex});

  factory ProductColorModel.fromMap(Map<String, dynamic> map) => ProductColorModel(
        name: '${map['name'] ?? ''}',
        nameAr: '${map['nameAr'] ?? ''}',
        hex: '${map['hex'] ?? ''}',
      );

  Map<String, dynamic> toMap() => {'name': name, 'nameAr': nameAr, 'hex': hex};
}

/// Mirrors a `products` document including size guide, fit type and shop-the-look metadata.
class ProductModel {
  static const String fitSlim = 'slim';
  static const String fitRegular = 'regular';
  static const String fitOversized = 'oversized';

  final String docId;
  final String productId;
  final String name;
  final String nameAr;
  final String des;
  final String desAr;
  final String brand;
  final String cat;
  final String catAr;
  final String image;
  final List<String> images;
  final String thumbnail;
  final num price;
  final num oldPrice;
  final num rate;
  final num quant;
  final Map<String, num> stock;
  final List<String> sizes;
  final List<ProductColorModel> colors;
  final String groupId;
  final SizeGuideModel? sizeGuide;
  final String fitType;
  final String fabricTag;
  final bool isBestSeller;
  final num soldCount;
  /// Lower = earlier on home and inside the category.
  final int? order;
  final ShopTheLookModel? shopTheLook;
  final String dropId;
  final DateTime? visibleFrom;

  /// When true, clearing empty guides writes FieldValue.delete() so merge does not keep stale data.
  final bool clearSizeGuide;
  final bool clearShopTheLook;

  const ProductModel({
    this.docId = '',
    required this.productId,
    required this.name,
    required this.nameAr,
    required this.des,
    required this.desAr,
    required this.brand,
    required this.cat,
    required this.catAr,
    required this.image,
    required this.images,
    this.thumbnail = '',
    required this.price,
    required this.oldPrice,
    required this.rate,
    required this.quant,
    required this.stock,
    required this.sizes,
    required this.colors,
    required this.groupId,
    this.sizeGuide,
    this.fitType = fitRegular,
    this.fabricTag = '',
    this.isBestSeller = false,
    this.soldCount = 0,
    this.order,
    this.shopTheLook,
    this.dropId = '',
    this.visibleFrom,
    this.clearSizeGuide = false,
    this.clearShopTheLook = false,
  });

  bool get hasSizeGuide => sizeGuide != null;

  factory ProductModel.fromMap(String docId, Map<String, dynamic> map) {
    final rawStock = map['stock'] is Map ? Map<String, dynamic>.from(map['stock'] as Map) : <String, dynamic>{};
    final fit = '${map['fitType'] ?? fitRegular}';
    return ProductModel(
      docId: docId,
      productId: '${map['productid'] ?? docId}',
      name: '${map['name'] ?? ''}',
      nameAr: '${map['nameAr'] ?? ''}',
      des: '${map['des'] ?? ''}',
      desAr: '${map['desAr'] ?? ''}',
      brand: '${map['brand'] ?? ''}',
      cat: '${map['cat'] ?? ''}',
      catAr: '${map['catAr'] ?? ''}',
      image: '${map['image'] ?? ''}',
      images: map['images'] is List ? (map['images'] as List).map((e) => '$e').toList() : const [],
      thumbnail: '${map['thumbnail'] ?? ''}',
      price: Formatters.toNum(map['price']),
      oldPrice: Formatters.toNum(map['oldPrice']),
      rate: Formatters.toNum(map['rate']),
      quant: Formatters.toNum(map['quant']),
      stock: rawStock.map((key, value) => MapEntry(key, Formatters.toNum(value))),
      sizes: map['sizes'] is List ? (map['sizes'] as List).map((e) => '$e').toList() : const [],
      colors: map['colors'] is List
          ? (map['colors'] as List).whereType<Map>().map((e) => ProductColorModel.fromMap(Map<String, dynamic>.from(e))).toList()
          : const [],
      groupId: '${map['groupId'] ?? ''}',
      sizeGuide: SizeGuideModel.fromMap(map['sizeGuide']),
      fitType: fit == fitSlim || fit == fitOversized ? fit : fitRegular,
      fabricTag: '${map['fabricTag'] ?? ''}',
      isBestSeller: map['isBestSeller'] == true,
      soldCount: Formatters.toNum(map['soldCount']),
      order: map['order'] == null ? null : Formatters.toNum(map['order']).toInt(),
      shopTheLook: ShopTheLookModel.fromMap(map['shopTheLook']),
      dropId: '${map['dropId'] ?? ''}',
      visibleFrom: Formatters.toDate(map['visibleFrom']),
    );
  }

  Map<String, dynamic> toMap() => {
        'productid': productId,
        'name': name,
        'nameAr': nameAr,
        'des': des,
        'desAr': desAr,
        'brand': brand,
        'cat': cat,
        'catAr': catAr,
        'image': image,
        'images': images,
        'thumbnail': thumbnail,
        'price': price,
        'oldPrice': oldPrice,
        'quant': quant,
        'stock': stock,
        'sizes': sizes,
        'colors': colors.map((c) => c.toMap()).toList(),
        'groupId': groupId,
        'fitType': fitType,
        'fabricTag': fabricTag,
        'isBestSeller': isBestSeller,
        // soldCount is owned by order/restock increments — never overwrite from the form.
        if (order != null) 'order': order,
        'dropId': dropId,
        if (sizeGuide != null)
          'sizeGuide': sizeGuide!.toMap()
        else if (clearSizeGuide)
          'sizeGuide': FieldValue.delete(),
        if (shopTheLook != null)
          'shopTheLook': shopTheLook!.toMap()
        else if (clearShopTheLook)
          'shopTheLook': FieldValue.delete(),
        if (visibleFrom != null) 'visibleFrom': Timestamp.fromDate(visibleFrom!.toUtc()) else 'visibleFrom': FieldValue.delete(),
      };

  bool get onSale => oldPrice > price && price > 0;
  int get discountPercent => onSale ? ((oldPrice - price) / oldPrice * 100).floor() : 0;
  String get displayName => nameAr.isNotEmpty ? nameAr : name;

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) ||
        nameAr.contains(q) ||
        brand.toLowerCase().contains(q) ||
        productId.toLowerCase().contains(q);
  }

  ProductModel copyWith({int? order, bool clearOrder = false}) => ProductModel(
        docId: docId,
        productId: productId,
        name: name,
        nameAr: nameAr,
        des: des,
        desAr: desAr,
        brand: brand,
        cat: cat,
        catAr: catAr,
        image: image,
        images: images,
        thumbnail: thumbnail,
        price: price,
        oldPrice: oldPrice,
        rate: rate,
        quant: quant,
        stock: stock,
        sizes: sizes,
        colors: colors,
        groupId: groupId,
        sizeGuide: sizeGuide,
        fitType: fitType,
        fabricTag: fabricTag,
        isBestSeller: isBestSeller,
        soldCount: soldCount,
        order: clearOrder ? null : (order ?? this.order),
        shopTheLook: shopTheLook,
        dropId: dropId,
        visibleFrom: visibleFrom,
      );
}
