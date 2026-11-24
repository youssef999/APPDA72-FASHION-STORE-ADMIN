/// Collection names shared with the store app; keep in sync with the mobile code.
class FirestoreCollections {
  FirestoreCollections._();

  static const String products = 'products';
  static const String categories = 'cat';
  static const String orders = 'orders';
  static const String users = 'Users';
  static const String notifications = 'notifications';
  static const String admins = 'admins';
  static const String coupons = 'coupons';
  static const String drops = 'drops';
  static const String productReviews = 'product_reviews';
  static const String feedback = 'feedback';
  static const String config = 'config';
  static const String delivery = 'del';
  static const String stockWaitlist = 'stockWaitlist';

  /// Docs under [config].
  static const String configCommerce = 'commerce';
  static const String configApp = 'app';

  /// Canonical delivery-fee document under [delivery] (`del` field = fee amount).
  static const String deliveryMainDoc = 'main';
}
