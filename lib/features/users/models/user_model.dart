import '../../../core/utils/formatters.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String photoUrl;
  final String provider;
  final String platform;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final int deviceCount;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.photoUrl,
    required this.provider,
    required this.platform,
    required this.createdAt,
    required this.lastLoginAt,
    required this.deviceCount,
  });

  factory UserModel.fromMap(String docId, Map<String, dynamic> map) {
    final tokens = map['fcmTokens'] is List ? (map['fcmTokens'] as List).length : 0;
    final hasSingleToken = '${map['fcmToken'] ?? map['token'] ?? ''}'.isNotEmpty;
    return UserModel(
      uid: '${map['uid'] ?? docId}',
      email: '${map['email'] ?? ''}',
      name: '${map['name'] ?? ''}',
      photoUrl: '${map['photoUrl'] ?? ''}',
      provider: '${map['provider'] ?? ''}',
      platform: '${map['platform'] ?? ''}',
      createdAt: Formatters.toDate(map['createdAt']),
      lastLoginAt: Formatters.toDate(map['lastLoginAt']),
      deviceCount: tokens > 0 ? tokens : (hasSingleToken ? 1 : 0),
    );
  }

  bool get hasDeviceToken => deviceCount > 0;

  String get displayName => name.isNotEmpty ? name : (email.isNotEmpty ? email.split('@').first : 'زائر');

  String get providerLabel => switch (provider) {
        'google' => 'Google',
        'password' => 'بريد إلكتروني',
        'guest' => 'زائر',
        _ => provider.isEmpty ? '—' : provider,
      };

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) || email.toLowerCase().contains(q) || uid.toLowerCase().contains(q);
  }
}
