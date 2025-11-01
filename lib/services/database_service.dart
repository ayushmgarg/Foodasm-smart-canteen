import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/menu_item.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ==================== MENU ITEMS ====================

  // Add Menu Item (Admin)
  Future<void> addMenuItem(MenuItem item) async {
    try {
      await _firestore.collection('menuItems').add(item.toMap());
    } catch (e) {
      print('Add menu item error: $e');
      rethrow;
    }
  }

  // Update Menu Item (Admin)
  Future<void> updateMenuItem(MenuItem item) async {
    try {
      await _firestore.collection('menuItems').doc(item.id).update(item.toMap());
    } catch (e) {
      print('Update menu item error: $e');
      rethrow;
    }
  }

  // Delete Menu Item (Admin)
  Future<void> deleteMenuItem(String itemId) async {
    try {
      await _firestore.collection('menuItems').doc(itemId).delete();
    } catch (e) {
      print('Delete menu item error: $e');
      rethrow;
    }
  }

  // Get All Menu Items
  Stream<List<MenuItem>> getMenuItems() {
    return _firestore.collection('menuItems').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => MenuItem.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Get Menu Items by Category
  Stream<List<MenuItem>> getMenuItemsByCategory(String category) {
    return _firestore
        .collection('menuItems')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MenuItem.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Get Available Menu Items for Today
  Stream<List<MenuItem>> getTodayMenuItems() {
    String today = _getTodayDay();
    return _firestore
        .collection('menuItems')
        .where('availableDays', arrayContains: today)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MenuItem.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // ==================== ORDERS ====================

  // Place Order
  Future<String> placeOrder(OrderModel order) async {
    try {
      String orderId = _uuid.v4();
      OrderModel newOrder = order.copyWith(orderId: orderId);
      
      await _firestore.collection('orders').doc(orderId).set(newOrder.toMap());
      
      return orderId;
    } catch (e) {
      print('Place order error: $e');
      rethrow;
    }
  }

  // Update Order Status (Admin)
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
    int? counterNumber,
  }) async {
    try {
      Map<String, dynamic> updateData = {'status': status.name};
      if (counterNumber != null) {
        updateData['counterNumber'] = counterNumber;
      }
      
      await _firestore.collection('orders').doc(orderId).update(updateData);
    } catch (e) {
      print('Update order status error: $e');
      rethrow;
    }
  }

 // Get User Orders - NO INDEX NEEDED
Stream<List<OrderModel>> getUserOrders(String userId) {
  print('📱 Getting orders for user: $userId');
  
  return _firestore
      .collection('orders')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
    print('📦 Received ${snapshot.docs.length} orders');
    
    final orders = snapshot.docs.map((doc) {
      final data = doc.data();
      return OrderModel.fromMap(data);
    }).toList();

    // Sort in memory
    orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    
    return orders;
  });
}

// Get All Orders (Admin) - NO INDEX NEEDED
Stream<List<OrderModel>> getAllOrders() {
  return _firestore
      .collection('orders')
      .snapshots()
      .map((snapshot) {
    final orders = snapshot.docs.map((doc) {
      return OrderModel.fromMap(doc.data());
    }).toList();

    // Sort in memory
    orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    
    return orders;
  });
}

// Get Pending Orders (Admin) - NO INDEX NEEDED
Stream<List<OrderModel>> getPendingOrders() {
  return _firestore
      .collection('orders')
      .snapshots()
      .map((snapshot) {
    final orders = snapshot.docs
        .map((doc) => OrderModel.fromMap(doc.data()))
        .where((order) =>
            order.status == OrderStatus.pending ||
            order.status == OrderStatus.preparing ||
            order.status == OrderStatus.ready)
        .toList();

    // Sort in memory
    orders.sort((a, b) => a.orderDate.compareTo(b.orderDate));
    
    return orders;
  });
}

  // ==================== USER ====================

  // Get User Stream
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // ==================== HELPERS ====================

  String _getTodayDay() {
    List<String> days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return days[DateTime.now().weekday - 1];
  }

  // Initialize Database with 50 food items (Run once)
  Future<void> initializeMenuItems(List<Map<String, dynamic>> items) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (var itemData in items) {
        DocumentReference docRef = _firestore.collection('menuItems').doc();
        batch.set(docRef, itemData);
      }
      
      await batch.commit();
      print('Menu items initialized successfully!');
    } catch (e) {
      print('Initialize menu error: $e');
      rethrow;
    }
  }
}