import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';

class CartItem {
  final MenuItem item;
  int quantity;

  CartItem({required this.item, this.quantity = 1});

  double get totalPrice => item.price * quantity;
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items =>_items;

  int get itemCount => _items.length;

  int get totalQuantity {
    return _items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  bool get isEmpty => _items.isEmpty;

  // Add item to cart
  void addItem(MenuItem item) {
    if (_items.containsKey(item.id)) {
      _items[item.id]!.quantity++;
    } else {
      _items[item.id] = CartItem(item: item, quantity: 1);
    }
    notifyListeners();
  }

  // Remove item from cart
  void removeItem(String itemId) {
    _items.remove(itemId);
    notifyListeners();
  }

  // Increase quantity
  void increaseQuantity(String itemId) {
    if (_items.containsKey(itemId)) {
      _items[itemId]!.quantity++;
      notifyListeners();
    }
  }

  // Decrease quantity
  void decreaseQuantity(String itemId) {
    if (_items.containsKey(itemId)) {
      if (_items[itemId]!.quantity > 1) {
        _items[itemId]!.quantity--;
      } else {
        _items.remove(itemId);
      }
      notifyListeners();
    }
  }

  // Clear cart
  void clear() {
    _items.clear();
    notifyListeners();
  }

  // Get cart items as list
  List<CartItem> getCartItems() {
    return _items.values.toList();
  }
}