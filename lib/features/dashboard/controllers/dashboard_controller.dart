import 'package:get/get.dart';
import '../repositories/dashboard_repository.dart';

/// Catalogue and customer counts; order figures come live from `OrdersController`.
class DashboardController extends GetxController {
  final DashboardRepository _repository = DashboardRepository();

  DashboardCounts? counts;
  bool isLoading = true;
  String? error;

  @override
  void onInit() {
    super.onInit();
    loadCounts();
  }

  Future<void> loadCounts() async {
    isLoading = true;
    error = null;
    update();
    try {
      counts = await _repository.loadCounts();
    } catch (e) {
      error = '$e';
    } finally {
      isLoading = false;
      update();
    }
  }
}
