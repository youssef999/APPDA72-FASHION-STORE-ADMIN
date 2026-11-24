import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static const String currency = 'S.A';

  static num toNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse('${value ?? ''}'.trim()) ?? 0;
  }

  static String money(num value) {
    final formatted = NumberFormat('#,##0.##', 'en').format(value);
    return '$formatted $currency';
  }

  static DateTime? toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static String date(DateTime value) => DateFormat('yyyy/MM/dd', 'en').format(value);

  static String dateTime(DateTime? value) =>
      value == null ? '—' : DateFormat('yyyy/MM/dd – HH:mm', 'en').format(value);
}
