import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/formatters.dart';

enum DropStatus { draft, scheduled, live, ended }

class DropModel {
  final String id;
  final String title;
  final String titleAr;
  final String subtitle;
  final String subtitleAr;
  final String coverImage;
  final DateTime launchAt;
  final DateTime webUnlockAt;
  final List<String> productIds;
  final DropStatus status;
  final DateTime? pushSentAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DropModel({
    this.id = '',
    required this.title,
    required this.titleAr,
    this.subtitle = 'App exclusive · 2h early',
    this.subtitleAr = 'حصري للتطبيق · قبل الموقع بساعتين',
    this.coverImage = '',
    required this.launchAt,
    required this.webUnlockAt,
    this.productIds = const [],
    this.status = DropStatus.draft,
    this.pushSentAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isUnlocked => !DateTime.now().toUtc().isBefore(launchAt.toUtc());

  String get displayTitle => titleAr.isNotEmpty ? titleAr : title;

  static DropStatus statusFrom(String raw) {
    switch (raw) {
      case 'scheduled':
        return DropStatus.scheduled;
      case 'live':
        return DropStatus.live;
      case 'ended':
        return DropStatus.ended;
      default:
        return DropStatus.draft;
    }
  }

  static String statusTo(DropStatus status) {
    switch (status) {
      case DropStatus.scheduled:
        return 'scheduled';
      case DropStatus.live:
        return 'live';
      case DropStatus.ended:
        return 'ended';
      case DropStatus.draft:
        return 'draft';
    }
  }

  static String statusLabel(DropStatus status) {
    switch (status) {
      case DropStatus.draft:
        return 'مسودة';
      case DropStatus.scheduled:
        return 'مجدول';
      case DropStatus.live:
        return 'مباشر';
      case DropStatus.ended:
        return 'منتهٍ';
    }
  }

  factory DropModel.fromMap(String id, Map<String, dynamic> map) => DropModel(
        id: id,
        title: '${map['title'] ?? ''}',
        titleAr: '${map['titleAr'] ?? ''}',
        subtitle: '${map['subtitle'] ?? 'App exclusive · 2h early'}',
        subtitleAr: '${map['subtitleAr'] ?? 'حصري للتطبيق · قبل الموقع بساعتين'}',
        coverImage: '${map['coverImage'] ?? ''}',
        launchAt: Formatters.toDate(map['launchAt']) ?? DateTime.now(),
        webUnlockAt: Formatters.toDate(map['webUnlockAt']) ??
            (Formatters.toDate(map['launchAt']) ?? DateTime.now()).add(const Duration(hours: 2)),
        productIds: map['productIds'] is List ? (map['productIds'] as List).map((e) => '$e').toList() : const [],
        status: statusFrom('${map['status'] ?? 'draft'}'),
        pushSentAt: Formatters.toDate(map['pushSentAt']),
        createdAt: Formatters.toDate(map['createdAt']),
        updatedAt: Formatters.toDate(map['updatedAt']),
      );

  Map<String, dynamic> toMap({bool isNew = false}) => {
        'title': title,
        'titleAr': titleAr,
        'subtitle': subtitle,
        'subtitleAr': subtitleAr,
        'coverImage': coverImage,
        'launchAt': Timestamp.fromDate(launchAt.toUtc()),
        'webUnlockAt': Timestamp.fromDate(webUnlockAt.toUtc()),
        'productIds': productIds,
        'status': statusTo(status),
        if (pushSentAt != null) 'pushSentAt': Timestamp.fromDate(pushSentAt!.toUtc()),
        'updatedAt': FieldValue.serverTimestamp(),
        if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      };

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) || titleAr.contains(q) || id.toLowerCase().contains(q);
  }
}
