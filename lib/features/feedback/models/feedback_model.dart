import '../../../core/utils/formatters.dart';

class FeedbackType {
  FeedbackType._();
  static const String complaint = 'complaint';
  static const String suggestion = 'suggestion';

  static String label(String type) => switch (type) {
        complaint => 'شكوى',
        _ => 'مقترح',
      };
}

class FeedbackStatus {
  FeedbackStatus._();
  static const String neu = 'new';
  static const String inProgress = 'in_progress';
  static const String resolved = 'resolved';
  static const String closed = 'closed';

  static const List<String> all = [neu, inProgress, resolved, closed];

  static String label(String status) => switch (status) {
        inProgress => 'قيد المتابعة',
        resolved => 'تم الحل',
        closed => 'مغلقة',
        _ => 'جديدة',
      };
}

class FeedbackModel {
  final String id;
  final String title;
  final String description;
  final String type;
  final String status;
  final String userUid;
  final String userEmail;
  final String userName;
  final String adminNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FeedbackModel({
    this.id = '',
    required this.title,
    required this.description,
    this.type = FeedbackType.suggestion,
    this.status = FeedbackStatus.neu,
    this.userUid = '',
    this.userEmail = '',
    this.userName = '',
    this.adminNote = '',
    this.createdAt,
    this.updatedAt,
  });

  factory FeedbackModel.fromMap(String id, Map<String, dynamic> map) {
    final type = '${map['type'] ?? FeedbackType.suggestion}';
    final status = '${map['status'] ?? FeedbackStatus.neu}';
    return FeedbackModel(
      id: id,
      title: '${map['title'] ?? ''}'.trim(),
      description: '${map['description'] ?? ''}'.trim(),
      type: type == FeedbackType.complaint ? FeedbackType.complaint : FeedbackType.suggestion,
      status: FeedbackStatus.all.contains(status) ? status : FeedbackStatus.neu,
      userUid: '${map['userUid'] ?? ''}',
      userEmail: '${map['userEmail'] ?? ''}',
      userName: '${map['userName'] ?? ''}',
      adminNote: '${map['adminNote'] ?? ''}'.trim(),
      createdAt: Formatters.toDate(map['createdAt']),
      updatedAt: Formatters.toDate(map['updatedAt']),
    );
  }

  String get displayUser => userName.isNotEmpty ? userName : (userEmail.isNotEmpty ? userEmail : '—');

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        userEmail.toLowerCase().contains(q) ||
        userName.toLowerCase().contains(q);
  }
}
