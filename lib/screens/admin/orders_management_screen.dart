import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/order_model.dart';
import '../../services/database_service.dart';
import '../../widgets/loading_widget.dart';

class OrdersManagementScreen extends StatefulWidget {
  const OrdersManagementScreen({Key? key}) : super(key: key);

  @override
  State<OrdersManagementScreen> createState() => _OrdersManagementScreenState();
}

class _OrdersManagementScreenState extends State<OrdersManagementScreen> {
  String _selectedFilter = 'Active';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            height: 60,
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterChip('Active'),
                _buildFilterChip('All'),
                _buildFilterChip('Completed'),
              ],
            ),
          ),

          const Divider(height: 1),

          // Orders List
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
                        const Icon(Icons.error_outline,
                            size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'No orders found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
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
                        Icon(Icons.filter_list_off,
                            size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No $_selectedFilter orders',
                          style:
                              const TextStyle(fontSize: 18, color: Colors.grey),
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
                    return _buildOrderCard(order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
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

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
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
            Text(order.userName),
            Text(
              '₹${order.totalAmount.toStringAsFixed(0)} • ${order.items.length} items',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        trailing: _buildStatusChip(order.status),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Items
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.quantity}x ${item.itemName}'),
                          Text('₹${(item.price * item.quantity).toStringAsFixed(0)}'),
                        ],
                      ),
                    )),

                const SizedBox(height: 16),

                // Special Instructions
                if (order.specialInstructions != null &&
                    order.specialInstructions!.isNotEmpty) ...[
                  const Text(
                    'Special Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(order.specialInstructions!),
                  const SizedBox(height: 16),
                ],

                // Counter Number (if assigned)
                if (order.counterNumber != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.countertops,
                            color: AppColors.success),
                        const SizedBox(width: 8),
                        Text(
                          'Counter: ${order.counterNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                if (order.status != OrderStatus.completed &&
                    order.status != OrderStatus.cancelled)
                  _buildActionButtons(order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    return Column(
      children: [
        if (order.status == OrderStatus.pending) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(
                order,
                OrderStatus.preparing,
              ),
              icon: const Icon(Icons.restaurant),
              label: const Text('Start Preparing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.preparing,
              ),
            ),
          ),
        ],
        if (order.status == OrderStatus.preparing) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _markAsReady(order),
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Ready'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ready,
              ),
            ),
          ),
        ],
        if (order.status == OrderStatus.ready) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(
                order,
                OrderStatus.completed,
              ),
              icon: const Icon(Icons.done_all),
              label: const Text('Mark as Completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _cancelOrder(order),
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Order'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
          ),
        ),
      ],
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

  Future<void> _updateOrderStatus(
    OrderModel order,
    OrderStatus newStatus,
  ) async {
    try {
      await DatabaseService().updateOrderStatus(
        orderId: order.orderId,
        status: newStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _markAsReady(OrderModel order) async {
    // Show dialog to assign counter number
    final counterNumber = await showDialog<int>(
      context: context,
      builder: (context) {
        int? selectedCounter;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Assign Counter Number'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select counter number for pickup:'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: List.generate(10, (index) {
                      final counter = index + 1;
                      final isSelected = selectedCounter == counter;
                      return ChoiceChip(
                        label: Text('$counter'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => selectedCounter = counter);
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedCounter != null
                      ? () => Navigator.pop(context, selectedCounter)
                      : null,
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    if (counterNumber != null) {
      try {
        await DatabaseService().updateOrderStatus(
          orderId: order.orderId,
          status: OrderStatus.ready,
          counterNumber: counterNumber,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Order ready at Counter $counterNumber. Customer notified!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateOrderStatus(order, OrderStatus.cancelled);
    }
  }
}