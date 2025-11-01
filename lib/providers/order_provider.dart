import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/database_service.dart';

class OrderProvider with ChangeNotifier {
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  // Get user orders
  void loadUserOrders(String userId) {
    _isLoading = true;
    notifyListeners();

    DatabaseService().getUserOrders(userId).listen((orders) {
      _orders = orders;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Get active order (if any)
  OrderModel? get activeOrder {
    try {
      return _orders.firstWhere(
        (order) =>
            order.status == OrderStatus.pending ||
            order.status == OrderStatus.preparing ||
            order.status == OrderStatus.ready,
      );
    } catch (e) {
      return null;
    }
  }
}