import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/user_provider.dart';
import '../../providers/cart_provider.dart';
import 'menu_screen.dart';
import '../cart/cart_screen.dart';
import '../orders/my_orders_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_dashboard.dart';
import '../recommendations/ai_recommendations_screen.dart';
import '../admin/admin_wallet_requests_screen.dart';
import '../profile/admin_profile_screen.dart';

// CRITICAL: Global TabController that can be accessed from anywhere
TabController? globalTabController;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  // Static method that uses the global TabController
  static void switchToTab(int index) {
    if (globalTabController != null && globalTabController!.index != index) {
      globalTabController!.animateTo(index);
    }
  }
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Widget> _screens;
  late List<String> _titles;

  @override
  void initState() {
    super.initState();
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isAdmin = userProvider.user?.isAdmin ?? false;
    
    if (isAdmin) {
      // Admin screens - NO WALLET
      _screens = const [
        MenuScreen(),
        MyOrdersScreen(),
        AdminWalletRequestsScreen(),
        AdminProfileScreen(),
      ];
      _titles = [
        'Menu',
        'Orders',
        'Wallet Requests',
        'Profile',
      ];
    } else {
      // Student screens
      _screens = const [
        MenuScreen(),
        MyOrdersScreen(),
        WalletScreen(),
        ProfileScreen(),
      ];
      _titles = [
        'Menu',
        'My Orders',
        'Wallet',
        'Profile',
      ];
    }
    
    _tabController = TabController(length: _screens.length, vsync: this);
    
    // CRITICAL: Assign to global variable
    globalTabController = _tabController;
    
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    // Load user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user != null) {
        userProvider.listenToUserChanges(userProvider.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    globalTabController = null; // Clear global reference
    super.dispose();
  }

  List<Tab> _buildTabs() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isAdmin = userProvider.user?.isAdmin ?? false;

    if (isAdmin) {
      return const [
        Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu'),
        Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
        Tab(icon: Icon(Icons.pending_actions), text: 'Requests'),
        Tab(icon: Icon(Icons.person), text: 'Profile'),
      ];
    } else {
      return const [
        Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu'),
        Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
        Tab(icon: Icon(Icons.account_balance_wallet), text: 'Wallet'),
        Tab(icon: Icon(Icons.person), text: 'Profile'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Logo in AppBar
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              width: 32,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.restaurant_menu, size: 28);
              },
            ),
            const SizedBox(width: 12),
            Text(
              _titles[_tabController.index],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // AI Recommendations
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AIRecommendationsScreen(),
                  ),
                );
              },
              tooltip: 'AI Recommendations',
            ),

          // Cart Icon with Badge
          if (_tabController.index == 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                ),
                if (cartProvider.itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '${cartProvider.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),

          // Admin Dashboard - Always show if admin
          if (userProvider.user != null && userProvider.user!.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminDashboard(),
                  ),
                );
              },
              tooltip: 'Admin Dashboard',
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primary,
        tabs: _buildTabs(),
      ),
    );
  }
}