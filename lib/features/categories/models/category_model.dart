import '../../../core/utils/formatters.dart';

class CategoryModel {
  final String docId;
  final String name;
  final String nameAr;
  final String image;

  /// Display order in the app; categories without it are shown last.
  final int? order;

  const CategoryModel({
    this.docId = '',
    required this.name,
    required this.nameAr,
    required this.image,
    this.order,
  });

  factory CategoryModel.fromMap(String docId, Map<String, dynamic> map) => CategoryModel(
        docId: docId,
        name: '${map['name'] ?? ''}',
        nameAr: '${map['nameAr'] ?? ''}',
        image: '${map['image'] ?? ''}',
        order: map['order'] == null ? null : Formatters.toNum(map['order']).toInt(),
      );

  Map<String, dynamic> toMap(String id) => {
        'id': id,
        'name': name,
        'nameAr': nameAr,
        'image': image,
        if (order != null) 'order': order,
      };

  String get displayName => nameAr.isNotEmpty ? '$nameAr · $name' : name;
}
