import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/formatters.dart';

class NotificationModel {
  static const String targetAll = 'all';

  final String id;
  final String title;
  final String titleAr;
  final String body;
  final String bodyAr;

  /// `all`, or the receiving user's uid.
  final String target;
  final String targetEmail;
  final String type;
  final String orderId;
  final String productId;
  final String size;
  final DateTime? createdAt;

  const NotificationModel({
    this.id = '',
    required this.title,
    required this.titleAr,
    required this.body,
    required this.bodyAr,
    this.target = targetAll,
    this.targetEmail = '',
    this.type = 'broadcast',
    this.orderId = '',
    this.productId = '',
    this.size = '',
    this.createdAt,
  });

  bool get isBroadcast => target == targetAll && targetEmail.isEmpty;

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) => NotificationModel(
        id: id,
        title: '${map['title'] ?? ''}',
        titleAr: '${map['titleAr'] ?? ''}',
        body: '${map['body'] ?? ''}',
        bodyAr: '${map['bodyAr'] ?? ''}',
        target: '${map['target'] ?? targetAll}',
        targetEmail: '${map['targetEmail'] ?? ''}',
        type: '${map['type'] ?? 'broadcast'}',
        orderId: '${map['orderId'] ?? ''}',
        productId: '${map['productId'] ?? ''}',
        size: '${map['size'] ?? ''}',
        createdAt: Formatters.toDate(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'titleAr': titleAr,
        'body': body,
        'bodyAr': bodyAr,
        'target': target,
        'targetEmail': targetEmail,
        'type': type,
        if (orderId.isNotEmpty) 'orderId': orderId,
        if (productId.isNotEmpty) 'productId': productId,
        if (size.isNotEmpty) 'size': size,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
