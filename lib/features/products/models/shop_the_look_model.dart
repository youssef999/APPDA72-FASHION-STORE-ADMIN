class LookPinModel {
  final String id;
  final double x;
  final double y;
  final String productId;
  final String role;
  final String roleAr;

  const LookPinModel({
    required this.id,
    required this.x,
    required this.y,
    required this.productId,
    this.role = '',
    this.roleAr = '',
  });

  factory LookPinModel.fromMap(Map<String, dynamic> map) => LookPinModel(
        id: '${map['id'] ?? ''}',
        x: (map['x'] is num ? map['x'] as num : num.tryParse('${map['x']}') ?? 0.5).toDouble().clamp(0, 1),
        y: (map['y'] is num ? map['y'] as num : num.tryParse('${map['y']}') ?? 0.5).toDouble().clamp(0, 1),
        productId: '${map['productId'] ?? ''}',
        role: '${map['role'] ?? ''}',
        roleAr: '${map['roleAr'] ?? ''}',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'x': x,
        'y': y,
        'productId': productId,
        'role': role,
        'roleAr': roleAr,
      };
}

class ShopTheLookModel {
  final int imageIndex;
  final String title;
  final String titleAr;
  final List<LookPinModel> pins;

  const ShopTheLookModel({
    this.imageIndex = 0,
    this.title = 'Shop the look',
    this.titleAr = 'تسوق الإطلالة',
    this.pins = const [],
  });

  static ShopTheLookModel? fromMap(dynamic map) {
    if (map is! Map) return null;
    final data = Map<String, dynamic>.from(map);
    final pins = data['pins'] is List
        ? (data['pins'] as List)
            .whereType<Map>()
            .map((e) => LookPinModel.fromMap(Map<String, dynamic>.from(e)))
            .where((p) => p.productId.isNotEmpty)
            .toList()
        : <LookPinModel>[];
    if (pins.isEmpty) return null;
    return ShopTheLookModel(
      imageIndex: data['imageIndex'] is int ? data['imageIndex'] as int : int.tryParse('${data['imageIndex']}') ?? 0,
      title: '${data['title'] ?? 'Shop the look'}',
      titleAr: '${data['titleAr'] ?? 'تسوق الإطلالة'}',
      pins: pins,
    );
  }

  Map<String, dynamic> toMap() => {
        'imageIndex': imageIndex,
        'title': title,
        'titleAr': titleAr,
        'pins': pins.map((p) => p.toMap()).toList(),
      };
}
