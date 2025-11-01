import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../models/order_model.dart';
import '../../services/database_service.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/order_card.dart';
import '../../widgets/loading_widget.dart';
import 'order_tracking_screen.dart';
import '../auth/login_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

        // Check if user is loading
        if (userProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (user == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_off, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Please login to view orders'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          );
        }

        // Check if admin
        if (user.isAdmin) {
          return _buildAdminOrdersContent();
        } else {
          return _buildStudentOrdersContent(user.uid);
        }
      },
    );
  }
 Widget _buildAdminOrdersContent() {
  return Column(
    children: [
      // Filter Tabs
      Container(
        height: 60,
        padding: const EdgeInsets.all(8),
        color: Colors.white,
        child: Row(
          children: [
            _buildFilterChip('All'),
            _buildFilterChip('Active'),
            _buildFilterChip('Completed'),
          ],
        ),
      ),

      const Divider(height: 1),

      // ALL Orders List (Admin sees all student orders)
      Expanded(
        child: StreamBuilder<List<OrderModel>>(
          stream: _selectedFilter == 'Active'
              ? DatabaseService().getPendingOrders()
              : DatabaseService().getAllOrders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget(message: 'Loading orders...');
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyOrders();
            }

            // Filter orders
            List<OrderModel> orders = snapshot.data!;

            if (_selectedFilter == 'Completed') {
              orders = orders
                  .where((order) =>
                      order.status == OrderStatus.completed ||
                      order.status == OrderStatus.cancelled)
                  .toList();
            }

            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_list_off, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No $_selectedFilter orders',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildAdminOrderCard(order);
              },
            );
          },
        ),
      ),
    ],
  );
}

Widget _buildStudentOrdersContent(String userId) {
  return Column(
    children: [
      // Filter Tabs
      Container(
        height: 60,
        padding: const EdgeInsets.all(8),
        color: Colors.white,
        child: Row(
          children: [
            _buildFilterChip('All'),
            _buildFilterChip('Active'),
            _buildFilterChip('Completed'),
          ],
        ),
      ),

      const Divider(height: 1),

      // Orders List
      Expanded(
        child: StreamBuilder<List<OrderModel>>(
          stream: DatabaseService().getUserOrders(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget(message: 'Loading orders...');
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyOrders();
            }

            // Filter orders
            List<OrderModel> orders = snapshot.data!;

            if (_selectedFilter == 'Active') {
              orders = orders
                  .where((order) =>
                      order.status == OrderStatus.pending ||
                      order.status == OrderStatus.preparing ||
                      order.status == OrderStatus.ready)
                  .toList();
            } else if (_selectedFilter == 'Completed') {
              orders = orders
                  .where((order) =>
                      order.status == OrderStatus.completed ||
                      order.status == OrderStatus.cancelled)
                  .toList();
            }

            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_list_off, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No $_selectedFilter orders',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderCard(
                  order: order,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderTrackingScreen(order: order),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    ],
  );
}

Widget _buildAdminOrderCard(OrderModel order) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getStatusColor(order.status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getStatusIcon(order.status),
          color: _getStatusColor(order.status),
        ),
      ),
      title: Text(
        'Order #${order.orderId.substring(0, 8)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('Customer: ${order.userName}'),
          Text('Amount: ₹${order.totalAmount.toStringAsFixed(0)}'),
        ],
      ),
      trailing: _buildStatusChip(order.status),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(order: order),
          ),
        );
      },
    ),
  );
}

Widget _buildStatusChip(OrderStatus status) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _getStatusColor(status).withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      status.name.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: _getStatusColor(status),
      ),
    ),
  );
}

Color _getStatusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return AppColors.pending;
    case OrderStatus.preparing:
      return AppColors.preparing;
    case OrderStatus.ready:
      return AppColors.ready;
    case OrderStatus.completed:
      return AppColors.completed;
    case OrderStatus.cancelled:
      return AppColors.cancelled;
  }
}

IconData _getStatusIcon(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Icons.schedule;
    case OrderStatus.preparing:
      return Icons.restaurant;
    case OrderStatus.ready:
      return Icons.check_circle;
    case OrderStatus.completed:
      return Icons.done_all;
    case OrderStatus.cancelled:
      return Icons.cancel;
  }
}

Widget _buildFilterChip(String label) {
  final isSelected = _selectedFilter == label;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() => _selectedFilter = label);
          },
          selectedColor: AppColors.primary,
          backgroundColor: Colors.grey[200],
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyOrders() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          const Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your order history will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}