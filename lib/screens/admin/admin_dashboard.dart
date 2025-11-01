import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/order_model.dart';
import '../../services/database_service.dart';
import 'manage_menu_screen.dart';
import 'orders_management_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings,
                      size: 50, color: Colors.white),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage your canteen operations',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Statistics
            const Text(
              'Today\'s Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            StreamBuilder<List<OrderModel>>(
              stream: DatabaseService().getAllOrders(),
              builder: (context, snapshot) {
                print('📊 Admin Dashboard Orders Stream:');
                print('   Connection State: ${snapshot.connectionState}');
                print('   Has Data: ${snapshot.hasData}');
                print('   Data Length: ${snapshot.data?.length ?? 0}');
                if (snapshot.hasError) {
                  print('   Error: ${snapshot.error}');
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!;
                final today = DateTime.now();
                final todayOrders = orders.where((order) {
                  return order.orderDate.year == today.year &&
                      order.orderDate.month == today.month &&
                      order.orderDate.day == today.day;
                }).toList();

                final pendingOrders = todayOrders
                    .where((o) => o.status == OrderStatus.pending)
                    .length;
                final preparingOrders = todayOrders
                    .where((o) => o.status == OrderStatus.preparing)
                    .length;
                final completedOrders = todayOrders
                    .where((o) => o.status == OrderStatus.completed)
                    .length;
                final totalRevenue = todayOrders.fold<double>(
                    0, (sum, order) => sum + order.totalAmount);

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.pending_actions,
                            title: 'Pending',
                            value: '$pendingOrders',
                            color: AppColors.pending,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.restaurant,
                            title: 'Preparing',
                            value: '$preparingOrders',
                            color: AppColors.preparing,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.check_circle,
                            title: 'Completed',
                            value: '$completedOrders',
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.currency_rupee,
                            title: 'Revenue',
                            value: '₹${totalRevenue.toStringAsFixed(0)}',
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _buildActionCard(
              context: context,
              icon: Icons.shopping_bag,
              title: 'Manage Orders',
              subtitle: 'View and update order status',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrdersManagementScreen(),
                  ),
                );
              },
            ),

            _buildActionCard(
              context: context,
              icon: Icons.restaurant_menu,
              title: 'Manage Menu',
              subtitle: 'Add, edit or remove food items',
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageMenuScreen(),
                  ),
                );
              },
            ),

            _buildActionCard(
              context: context,
              icon: Icons.bar_chart,
              title: 'Analytics',
              subtitle: 'View sales and performance',
              color: Colors.purple,
              onTap: () {
                _showAnalyticsDialog(context);
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
  void _showAnalyticsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.bar_chart, color: Colors.purple.shade700),
                  const SizedBox(width: 12),
                  const Text(
                    'Analytics Dashboard',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: StreamBuilder<List<OrderModel>>(
                stream: DatabaseService().getAllOrders(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final orders = snapshot.data!;
                  print('📊 Analytics: Total orders = ${orders.length}');
                  
                  final completedOrders = orders.where((o) => o.status == OrderStatus.completed).toList();
                  print('📊 Analytics: Completed orders = ${completedOrders.length}');
                  
                  final totalRevenue = completedOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);
                  print('📊 Analytics: Total revenue = ₹$totalRevenue');
                  
                  final avgOrderValue = completedOrders.isEmpty ? 0.0 : totalRevenue / completedOrders.length;

                  // Get today's data
                  final today = DateTime.now();
                  final todayOrders = completedOrders.where((o) =>
                    o.orderDate.year == today.year &&
                    o.orderDate.month == today.month &&
                    o.orderDate.day == today.day
                  ).toList();
                  final todayRevenue = todayOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);

                  // Get this week's data
                  final weekStart = today.subtract(Duration(days: today.weekday - 1));
                  final weekOrders = completedOrders.where((o) => o.orderDate.isAfter(weekStart)).toList();
                  final weekRevenue = weekOrders.fold<double>(0, (sum, o) => sum + o.totalAmount);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Overall:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        _buildAnalyticItem('Total Orders', '${orders.length}', Icons.receipt_long, Colors.blue),
                        _buildAnalyticItem('Completed', '${completedOrders.length}', Icons.done_all, Colors.green),
                        _buildAnalyticItem('Total Revenue', '₹${totalRevenue.toStringAsFixed(0)}', Icons.currency_rupee, Colors.orange),
                        _buildAnalyticItem('Avg Order', '₹${avgOrderValue.toStringAsFixed(0)}', Icons.trending_up, Colors.purple),
                        const Divider(height: 24),
                        const Text('Today:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        _buildAnalyticItem('Orders', '${todayOrders.length}', Icons.today, Colors.teal),
                        _buildAnalyticItem('Revenue', '₹${todayRevenue.toStringAsFixed(0)}', Icons.currency_rupee, Colors.teal),
                        const Divider(height: 24),
                        const Text('This Week:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        _buildAnalyticItem('Orders', '${weekOrders.length}', Icons.calendar_today, Colors.indigo),
                        _buildAnalyticItem('Revenue', '₹${weekRevenue.toStringAsFixed(0)}', Icons.currency_rupee, Colors.indigo),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildAnalyticItem(String label, String value, IconData icon, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}
}