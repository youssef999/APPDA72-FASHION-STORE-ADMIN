import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/formatters.dart';

enum CouponStatus { active, expired, used, disabled }

/// `coupons/{CODE}`; every coupon expires and each customer can redeem it once.
class CouponModel {
  static const String targetAll = 'all';
  static const String percent = 'percent';
  static const String fixed = 'fixed';
  static const String campaignInfluencer = 'influencer';

  final String code;
  final String type;
  final num value;
  final DateTime expiresAt;
  final String target;
  final String targetEmail;
  final String targetName;
  final bool active;
  final List<String> usedBy;
  final DateTime? createdAt;
  final String campaignType;
  final String influencerName;
  final String influencerNameAr;
  final int attributionWindowDays;

  const CouponModel({
    required this.code,
    required this.type,
    required this.value,
    required this.expiresAt,
    this.target = targetAll,
    this.targetEmail = '',
    this.targetName = '',
    this.active = true,
    this.usedBy = const [],
    this.createdAt,
    this.campaignType = '',
    this.influencerName = '',
    this.influencerNameAr = '',
    this.attributionWindowDays = 7,
  });

  bool get isPublic => target == targetAll;
  bool get isPercent => type == percent;
  bool get isInfluencer => campaignType == campaignInfluencer;
  int get usedCount => usedBy.length;

  /// A personal coupon is finished after its single use; a public one stays open for other customers.
  CouponStatus statusAt(DateTime now) {
    if (!active) return CouponStatus.disabled;
    if (!isPublic && usedBy.isNotEmpty) return CouponStatus.used;
    if (!expiresAt.isAfter(now)) return CouponStatus.expired;
    return CouponStatus.active;
  }

  CouponStatus get status => statusAt(DateTime.now());

  bool usedByUser(String uid) => usedBy.contains(uid);

  /// Never more than the subtotal; delivery is not discounted.
  num discountFor(num subtotal) {
    if (subtotal <= 0) return 0;
    final num raw = isPercent ? subtotal * value / 100 : value;
    final num capped = raw > subtotal ? subtotal : raw;
    return (capped * 100).round() / 100;
  }

  String get valueLabel => isPercent ? '${Formatters.toNum(value)}%' : Formatters.money(value);

  String get influencerDisplay => influencerNameAr.isNotEmpty ? influencerNameAr : influencerName;

  factory CouponModel.fromMap(String id, Map<String, dynamic> map) => CouponModel(
        code: '${map['code'] ?? id}',
        type: map['type'] == fixed ? fixed : percent,
        value: Formatters.toNum(map['value']),
        expiresAt: Formatters.toDate(map['expiresAt']) ?? DateTime(2000),
        target: '${map['target'] ?? targetAll}',
        targetEmail: '${map['targetEmail'] ?? ''}',
        targetName: '${map['targetName'] ?? ''}',
        active: map['active'] != false,
        usedBy: map['usedBy'] is List ? (map['usedBy'] as List).map((e) => '$e').toList() : const [],
        createdAt: Formatters.toDate(map['createdAt']),
        campaignType: '${map['campaignType'] ?? ''}',
        influencerName: '${map['influencerName'] ?? ''}',
        influencerNameAr: '${map['influencerNameAr'] ?? ''}',
        attributionWindowDays: Formatters.toNum(map['attributionWindowDays'] ?? 7).toInt().clamp(1, 90),
      );

  Map<String, dynamic> toMap() => {
        'code': code,
        'type': type,
        'value': value,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'target': target,
        'targetEmail': targetEmail,
        'targetName': targetName,
        'active': active,
        'usedBy': usedBy,
        'usedCount': usedCount,
        'createdAt': FieldValue.serverTimestamp(),
        'campaignType': campaignType,
        'influencerName': influencerName,
        'influencerNameAr': influencerNameAr,
        'attributionWindowDays': attributionWindowDays,
      };

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return code.toLowerCase().contains(q) ||
        targetEmail.toLowerCase().contains(q) ||
        targetName.toLowerCase().contains(q) ||
        influencerName.toLowerCase().contains(q) ||
        influencerNameAr.contains(query);
  }
}
