import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../orders/models/order_model.dart';
import '../../orders/repositories/orders_repository.dart';
import '../../products/models/product_model.dart';
import '../../products/repositories/products_repository.dart';
import '../../users/models/user_model.dart';
import '../../users/repositories/users_repository.dart';
import '../models/analytics_report.dart';
import '../services/analytics_service.dart';

enum AnalyticsRange { week, month, quarter, year, custom }

class AnalyticsController extends GetxController {
  final List<StreamSubscription> _subscriptions = [];

  List<OrderModel> orders = [];
  List<ProductModel> products = [];
  List<UserModel> users = [];
  final Set<String> _loaded = {};
  String? error;

  AnalyticsRange range = AnalyticsRange.month;
  DateTimeRange customRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 29)),
    end: DateTime.now(),
  );
  AnalyticsReport? report;

  bool get isLoading => _loaded.length < 3 && error == null;

  DateTimeRange get activeRange {
    final now = DateTime.now();
    int days(int n) => n - 1;
    return switch (range) {
      AnalyticsRange.week => DateTimeRange(start: now.subtract(Duration(days: days(7))), end: now),
      AnalyticsRange.month => DateTimeRange(start: now.subtract(Duration(days: days(30))), end: now),
      AnalyticsRange.quarter => DateTimeRange(start: now.subtract(Duration(days: days(90))), end: now),
      AnalyticsRange.year => DateTimeRange(start: now.subtract(Duration(days: days(365))), end: now),
      AnalyticsRange.custom => customRange,
    };
  }

  @override
  void onInit() {
    super.onInit();
    _listen('orders', OrdersRepository().watchOrders(), (List<OrderModel> data) => orders = data);
    _listen('products', ProductsRepository().watchProducts(), (List<ProductModel> data) => products = data);
    _listen('users', UsersRepository().watchUsers(), (List<UserModel> data) => users = data);
  }

  void _listen<T>(String key, Stream<T> stream, void Function(T) assign) {
    _subscriptions.add(stream.listen(
      (data) {
        assign(data);
        _loaded.add(key);
        _rebuild();
      },
      onError: (Object e) {
        error = '$e';
        update();
      },
    ));
  }

  void setRange(AnalyticsRange value) {
    range = value;
    _rebuild();
  }

  void setCustomRange(DateTimeRange value) {
    customRange = value;
    range = AnalyticsRange.custom;
    _rebuild();
  }

  void _rebuild() {
    if (_loaded.length < 3) {
      update();
      return;
    }
    final r = activeRange;
    report = AnalyticsService.build(orders: orders, products: products, users: users, from: r.start, to: r.end);
    update();
  }

  @override
  void onClose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.onClose();
  }
}
