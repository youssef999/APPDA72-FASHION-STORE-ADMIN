/// Measurement chart stored on `products.sizeGuide`.
class SizeGuideRowModel {
  final String size;
  final num width;
  final num length;
  final num? minHeight;
  final num? maxHeight;
  final num? minWeight;
  final num? maxWeight;

  const SizeGuideRowModel({
    required this.size,
    required this.width,
    required this.length,
    this.minHeight,
    this.maxHeight,
    this.minWeight,
    this.maxWeight,
  });

  factory SizeGuideRowModel.fromMap(Map<String, dynamic> map) => SizeGuideRowModel(
        size: '${map['size'] ?? ''}',
        width: map['width'] is num ? map['width'] as num : num.tryParse('${map['width']}') ?? 0,
        length: map['length'] is num ? map['length'] as num : num.tryParse('${map['length']}') ?? 0,
        minHeight: _optionalNum(map['minHeight']),
        maxHeight: _optionalNum(map['maxHeight']),
        minWeight: _optionalNum(map['minWeight']),
        maxWeight: _optionalNum(map['maxWeight']),
      );

  Map<String, dynamic> toMap() => {
        'size': size,
        'width': width,
        'length': length,
        if (minHeight != null) 'minHeight': minHeight,
        if (maxHeight != null) 'maxHeight': maxHeight,
        if (minWeight != null) 'minWeight': minWeight,
        if (maxWeight != null) 'maxWeight': maxWeight,
      };

  static num? _optionalNum(dynamic value) {
    if (value == null || '$value'.trim().isEmpty) return null;
    if (value is num) return value;
    return num.tryParse('$value');
  }
}

class SizeGuideModel {
  final String image;
  final String unit;
  final String widthLabel;
  final String lengthLabel;
  final List<SizeGuideRowModel> rows;

  const SizeGuideModel({
    this.image = 'assets/images/size_guide_dresses.jpg',
    this.unit = 'cm',
    this.widthLabel = 'chestWidth',
    this.lengthLabel = 'garmentLength',
    this.rows = const [],
  });

  static SizeGuideModel? fromMap(dynamic map) {
    if (map is! Map) return null;
    final data = Map<String, dynamic>.from(map);
    final rows = data['rows'] is List
        ? (data['rows'] as List)
            .whereType<Map>()
            .map((e) => SizeGuideRowModel.fromMap(Map<String, dynamic>.from(e)))
            .where((r) => r.size.isNotEmpty)
            .toList()
        : <SizeGuideRowModel>[];
    if (rows.isEmpty) return null;
    return SizeGuideModel(
      image: '${data['image'] ?? 'assets/images/size_guide_dresses.jpg'}',
      unit: '${data['unit'] ?? 'cm'}',
      widthLabel: '${data['widthLabel'] ?? 'chestWidth'}',
      lengthLabel: '${data['lengthLabel'] ?? 'garmentLength'}',
      rows: rows,
    );
  }

  Map<String, dynamic> toMap() => {
        'image': image,
        'unit': unit,
        'widthLabel': widthLabel,
        'lengthLabel': lengthLabel,
        'rows': rows.map((r) => r.toMap()).toList(),
      };
}
