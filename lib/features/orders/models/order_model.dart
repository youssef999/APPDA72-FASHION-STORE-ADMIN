import 'package:intl/intl.dart';
import '../../../core/utils/formatters.dart';

/// Status values written by the store app; `del` means delivered.
class OrderStatus {
  OrderStatus._();

  static const String waiting = 'waiting';
  static const String approved = 'approved';
  static const String delivered = 'del';
  static const String refused = 'refuse';

  static const List<String> all = [waiting, approved, delivered, refused];

  static String label(String status) => switch (status) {
        approved => 'جاري التجهيز',
        delivered => 'تم التوصيل',
        refused => 'مرفوض',
        _ => 'قيد المراجعة',
      };
}

class OrderItemModel {
  final String productId;
  final String name;
  final String nameAr;
  final String image;
  final String brand;
  final String color;
  final String colorAr;
  final String size;
  final num price;
  final num quantity;

  const OrderItemModel({
    required this.productId,
    required this.name,
    required this.nameAr,
    required this.image,
    required this.brand,
    required this.color,
    required this.colorAr,
    required this.size,
    required this.price,
    required this.quantity,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) => OrderItemModel(
        productId: '${map['productid'] ?? ''}',
        name: '${map['name'] ?? ''}',
        nameAr: '${map['nameAr'] ?? ''}',
        image: '${map['image'] ?? ''}',
        brand: '${map['brand'] ?? ''}',
        color: '${map['color'] ?? ''}',
        colorAr: '${map['colorAr'] ?? ''}',
        size: '${map['size'] ?? ''}',
        price: Formatters.toNum(map['price']),
        quantity: Formatters.toNum(map['quant']),
      );

  String get displayName => nameAr.isNotEmpty ? nameAr : name;
  num get lineTotal => price * quantity;
}

class OrderModel {
  final String docId;
  final String orderId;
  final String status;
  final String userUid;
  final String userName;
  final String userEmail;
  final String customerName;
  final String phone;
  final String address;
  final String area;
  final String building;
  final String floor;
  final String home;
  final String platform;
  final num subtotal;
  final num deliveryFee;
  final num finalTotal;
  final String couponCode;
  final num discount;
  final String paymentMethod;
  final String paymentStatus;
  final String paymentGateway;
  final String orderNote;
  final double? lat;
  final double? lng;
  final DateTime? createdAt;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.docId,
    required this.orderId,
    required this.status,
    required this.userUid,
    required this.userName,
    required this.userEmail,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.area,
    required this.building,
    required this.floor,
    required this.home,
    required this.platform,
    required this.subtotal,
    required this.deliveryFee,
    required this.finalTotal,
    this.couponCode = '',
    this.discount = 0,
    this.paymentMethod = '',
    this.paymentStatus = '',
    this.paymentGateway = '',
    this.orderNote = '',
    this.lat,
    this.lng,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromMap(String docId, Map<String, dynamic> map) {
    final rawItems = map['order'] is List ? map['order'] as List : const [];
    final num subtotal = Formatters.toNum(map['total']);
    final num fee = Formatters.toNum(map['del']);
    final num finalTotal = Formatters.toNum(map['finalTotal']);
    final num discount = Formatters.toNum(map['discount']);
    return OrderModel(
      docId: docId,
      orderId: '${map['order_id'] ?? docId}',
      status: '${map['status'] ?? OrderStatus.waiting}',
      userUid: '${map['user_uid'] ?? ''}',
      userName: '${map['user_name'] ?? ''}',
      userEmail: '${map['user_email'] ?? ''}',
      customerName: '${map['name'] ?? map['user_name'] ?? ''}',
      phone: '${map['phone'] ?? ''}',
      address: '${map['address'] ?? ''}',
      area: '${map['area'] ?? ''}',
      building: '${map['buildingNum'] ?? ''}',
      floor: '${map['floor'] ?? ''}',
      home: '${map['home'] ?? ''}',
      platform: '${map['platform'] ?? ''}',
      subtotal: subtotal,
      deliveryFee: fee,
      finalTotal: finalTotal > 0 ? finalTotal : subtotal + fee - discount,
      couponCode: '${map['couponCode'] ?? ''}',
      discount: discount,
      paymentMethod: '${map['paymentMethod'] ?? ''}'.trim().toLowerCase(),
      paymentStatus: '${map['paymentStatus'] ?? ''}'.trim().toLowerCase(),
      paymentGateway: '${map['paymentGateway'] ?? ''}'.trim().toLowerCase(),
      orderNote: '${map['orderNote'] ?? ''}'.trim(),
      lat: _toCoord(map['lat']),
      lng: _toCoord(map['lng']),
      createdAt: Formatters.toDate(map['createdAt']) ?? _parseLegacyDate(map['date'], map['time']),
      items: rawItems.whereType<Map>().map((e) => OrderItemModel.fromMap(Map<String, dynamic>.from(e))).toList(),
    );
  }

  num get itemCount => items.fold<num>(0, (sum, item) => sum + item.quantity);

  bool get hasCoordinates =>
      lat != null && lng != null && lat!.abs() <= 90 && lng!.abs() <= 180 && (lat != 0 || lng != 0);

  String get coordinatesLabel => hasCoordinates ? '${lat!.toStringAsFixed(6)}, ${lng!.toStringAsFixed(6)}' : '';

  /// Google Maps pin link for delivery coords.
  String get googleMapsUrl =>
      hasCoordinates ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng' : '';

  /// Shareable plain maps link (same destination).
  String get mapsShareLink =>
      hasCoordinates ? 'https://maps.google.com/?q=$lat,$lng' : '';

  /// Arabic label for how the customer paid (كاش / فيزا / آبل باي…).
  String get paymentMethodLabel {
    final key = paymentMethod.isNotEmpty ? paymentMethod : paymentGateway;
    return switch (key) {
      'cod' || 'cash' => 'كاش عند الاستلام',
      'visa' => 'فيزا',
      'mastercard' || 'master' => 'ماستركارد',
      'mada' => 'مدى',
      'amex' => 'أمريكان إكسبريس',
      'apple_pay' || 'applepay' => 'آبل باي',
      'stc_pay' || 'stcpay' => 'STC Pay',
      'moyasar' => 'بطاقة (ميسر)',
      'tap' => 'بطاقة (Tap)',
      '' => 'غير محدد',
      _ => key,
    };
  }

  String get paymentStatusLabel => switch (paymentStatus) {
        'paid' || 'captured' || 'authorized' => 'مدفوع',
        'pending' => 'قيد الدفع',
        'failed' => 'فشل الدفع',
        'cancelled' => 'ملغي',
        '' => paymentMethod == 'cod' || paymentGateway == 'cod' ? 'عند الاستلام' : 'غير محدد',
        _ => paymentStatus,
      };

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return orderId.toLowerCase().contains(q) ||
        customerName.toLowerCase().contains(q) ||
        userEmail.toLowerCase().contains(q) ||
        phone.contains(q) ||
        paymentMethodLabel.contains(query) ||
        paymentMethod.contains(q);
  }

  static DateTime? _parseLegacyDate(dynamic date, dynamic time) {
    final text = '${date ?? ''} ${time ?? ''}'.trim();
    if (text.isEmpty) return null;
    for (final pattern in ['yyyy-MM-dd hh:mm a', 'yyyy-MM-dd HH:mm', 'yyyy-MM-dd', 'dd/MM/yyyy hh:mm a']) {
      try {
        return DateFormat(pattern, 'en').parseLoose(text);
      } catch (_) {}
    }
    return null;
  }

  static double? _toCoord(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final text = '$value'.trim();
    if (text.isEmpty || text == 'x' || text == 'null') return null;
    return double.tryParse(text);
  }
}
