import 'dart:async';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../orders/models/order_model.dart';
import '../../orders/repositories/orders_repository.dart';
import '../models/user_model.dart';
import '../repositories/users_repository.dart';

class UsersController extends GetxController {
  static const String listId = 'users_list';

  final UsersRepository _repository = UsersRepository();
  final OrdersRepository _ordersRepository = OrdersRepository();
  StreamSubscription<List<UserModel>>? _usersSubscription;
  StreamSubscription<List<OrderModel>>? _ordersSubscription;

  List<UserModel> users = [];
  bool isLoading = true;
  String? error;
  String query = '';

  /// Order count and spend per user, keyed by uid and by lowercase email (older orders have no uid).
  final Map<String, int> _orderCounts = {};
  final Map<String, num> _spent = {};

  List<UserModel> get filtered => users.where((u) => u.matches(query)).toList();

  int get withDeviceToken => users.where((u) => u.hasDeviceToken).length;

  int ordersOf(UserModel user) => (_orderCounts[user.uid] ?? 0) + (_orderCounts[_emailKey(user)] ?? 0);

  num spentBy(UserModel user) => (_spent[user.uid] ?? 0) + (_spent[_emailKey(user)] ?? 0);

  @override
  void onInit() {
    super.onInit();
    _usersSubscription = _repository.watchUsers().listen(
      (data) {
        users = data;
        isLoading = false;
        error = null;
        update();
      },
      onError: (Object e) {
        isLoading = false;
        error = '$e';
        update();
      },
    );
    _ordersSubscription = _ordersRepository.watchOrders().listen(_countOrders, onError: (_) {});
  }

  void search(String value) {
    query = value.trim();
    update([listId]);
  }

  /// Opens the composer with this user preselected as the only recipient.
  void notify(UserModel user) => Get.offAllNamed(
        AppRoutes.notifications,
        parameters: {'uid': user.uid, 'email': user.email, 'name': user.displayName},
      );

  /// Opens the coupon form with this user as the only recipient.
  void giftCoupon(UserModel user) => Get.offAllNamed(
        AppRoutes.coupons,
        parameters: {'uid': user.uid, 'email': user.email, 'name': user.displayName},
      );

  void _countOrders(List<OrderModel> orders) {
    _orderCounts.clear();
    _spent.clear();
    for (final order in orders) {
      final key = order.userUid.isNotEmpty ? order.userUid : order.userEmail.trim().toLowerCase();
      if (key.isEmpty) continue;
      _orderCounts[key] = (_orderCounts[key] ?? 0) + 1;
      if (order.status != OrderStatus.refused) _spent[key] = (_spent[key] ?? 0) + order.finalTotal;
    }
    update([listId]);
  }

  String _emailKey(UserModel user) => user.email.trim().toLowerCase();

  @override
  void onClose() {
    _usersSubscription?.cancel();
    _ordersSubscription?.cancel();
    super.onClose();
  }
}
