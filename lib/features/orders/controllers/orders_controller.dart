import 'dart:async';
import 'package:get/get.dart';
import '../../../shared/widgets/feedback/app_feedback.dart';
import '../models/order_model.dart';
import '../repositories/orders_repository.dart';

class OrdersController extends GetxController {
  static const String listId = 'orders_list';

  final OrdersRepository _repository = OrdersRepository();
  StreamSubscription<List<OrderModel>>? _subscription;

  List<OrderModel> orders = [];
  bool isLoading = true;
  String? error;
  String? statusFilter;
  String query = '';
  final Set<String> updating = {};

  List<OrderModel> get filtered => orders
      .where((o) => (statusFilter == null || o.status == statusFilter) && o.matches(query))
      .toList();

  int countFor(String? status) => status == null ? orders.length : orders.where((o) => o.status == status).length;

  num get deliveredRevenue => orders
      .where((o) => o.status == OrderStatus.delivered)
      .fold<num>(0, (sum, o) => sum + o.finalTotal);

  @override
  void onInit() {
    super.onInit();
    _subscription = _repository.watchOrders().listen(
      (data) {
        orders = data;
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
  }

  void setStatusFilter(String? status) {
    statusFilter = status;
    update();
  }

  void search(String value) {
    query = value.trim();
    update([listId]);
  }

  OrderModel? byDocId(String docId) => orders.firstWhereOrNull((o) => o.docId == docId);

  Future<void> changeStatus(OrderModel order, String status) async {
    if (order.status == status || updating.contains(order.docId)) return;
    if (status == OrderStatus.refused) {
      final confirmed = await AppConfirmDialog.show(
        title: 'رفض الطلب',
        message: 'سيتم رفض الطلب #${order.orderId} وإرجاع الكميات للمخزون'
            '${order.couponCode.isEmpty ? '' : ' وإرجاع الكوبون ${order.couponCode} للعميل'} وإشعاره.',
        confirmLabel: 'رفض الطلب',
        isDanger: true,
      );
      if (!confirmed) return;
    }
    updating.add(order.docId);
    update();
    try {
      await _repository.updateStatus(order, status);
      AppSnackbar.show('تم تحديث الطلب إلى "${OrderStatus.label(status)}" وإشعار العميل');
    } catch (e) {
      AppSnackbar.show('تعذر تحديث الطلب: $e', type: AppSnackbarType.error);
    } finally {
      updating.remove(order.docId);
      update();
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
