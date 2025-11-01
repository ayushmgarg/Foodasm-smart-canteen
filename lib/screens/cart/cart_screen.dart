import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../constants/colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/wallet_service.dart';
import '../../services/database_service.dart';
import '../../models/order_model.dart';
import '../../widgets/custom_button.dart';


class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _instructionsController = TextEditingController();
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          if (cartProvider.itemCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _clearCart(context, cartProvider),
            ),
        ],
      ),
      body: cartProvider.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                // Cart Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartProvider.items.length,
                    itemBuilder: (context, index) {
                      final cartItem =
                          cartProvider.items.values.toList()[index];
                      return _buildCartItem(cartItem, cartProvider);
                    },
                  ),
                ),

                // Special Instructions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _instructionsController,
                    decoration: InputDecoration(
                      hintText: 'Special instructions (optional)',
                      prefixIcon: const Icon(Icons.edit_note),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,),
                    ),
                    maxLines: 2,
                  ),
                ),

                const SizedBox(height: 16),

                // Bill Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Items Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Items (${cartProvider.totalQuantity})',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            '₹${cartProvider.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      // Total Amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${cartProvider.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Wallet Balance Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Wallet Balance:',
                              style: TextStyle(fontSize: 14),
                            ),
                            Text(
                              '₹${userProvider.user?.walletBalance.toStringAsFixed(2) ?? '0.00'}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: (userProvider.user?.walletBalance ?? 0) >=
                                        cartProvider.totalAmount
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Place Order Button
                      CustomButton(
                        text: 'Place Order',
                        icon: Icons.shopping_bag,
                        onPressed: _isPlacingOrder
                            ? () {}
                            : () => _placeOrder(
                                  context,
                                  cartProvider,
                                  userProvider,
                                ),
                        isLoading: _isPlacingOrder,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items from the menu',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Browse Menu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem cartItem, CartProvider cartProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: cartItem.item.imageUrl.isNotEmpty
                    ? Image.network(
                        cartItem.item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.restaurant,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      )
                    : Icon(
                        Icons.restaurant,
                        size: 40,
                        color: Colors.grey[400],
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: cartItem.item.isVeg
                            ? AppColors.vegGreen
                            : AppColors.nonVegRed,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          cartItem.item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${cartItem.item.price.toStringAsFixed(0)} each',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Quantity Controls
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: () {
                                cartProvider.decreaseQuantity(cartItem.item.id);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '${cartItem.quantity}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () {
                                cartProvider.increaseQuantity(cartItem.item.id);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Total Price
                      Text(
                        '₹${cartItem.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCart(BuildContext context, CartProvider cartProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      cartProvider.clear();
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _placeOrder(
    BuildContext context,
    CartProvider cartProvider,
    UserProvider userProvider,
  ) async {
    final user = userProvider.user;
    if (user == null) return;

    print('🔍 User Check Before Order:');
    print('   UID: ${user.uid}');
    print('   Name: ${user.name}');
    print('   Email: ${user.email}');

    if (user.name.isEmpty) {
    print('⚠️ WARNING: User name is empty!');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error: User profile incomplete. Please logout and login again.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
    }
    // Check wallet balance
    if (user.walletBalance < cartProvider.totalAmount) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Insufficient Balance'),
          content: Text(
            'Your wallet balance is ₹${user.walletBalance.toStringAsFixed(2)}\n'
            'Order total is ₹${cartProvider.totalAmount.toStringAsFixed(2)}\n\n'
            'Please add money to your wallet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to wallet screen
                Navigator.pop(context);
              },
              child: const Text('Add Money'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      // Create order items
      List<OrderItem> orderItems = cartProvider.getCartItems().map((cartItem) {
        return OrderItem(
          itemId: cartItem.item.id,
          itemName: cartItem.item.name,
          price: cartItem.item.price,
          quantity: cartItem.quantity,
        );
      }).toList();

      // Create order
      OrderModel order = OrderModel(
        orderId: const Uuid().v4(),
        userId: user.uid,
        userName: user.name,
        items: orderItems,
        totalAmount: cartProvider.totalAmount,
        specialInstructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
      );

      print('🔍 DEBUG Order Details:');
      print('   User ID: ${user.uid}');
      print('   User Name: ${user.name}');
      print('   Order ID: ${order.orderId}');

      // Place order in database
      await DatabaseService().placeOrder(order);

      // Deduct from wallet
     await WalletService().deductMoney(
        userId: user.uid,
        userName: user.name,  
        amount: cartProvider.totalAmount,
        description: 'Order #${order.orderId.substring(0, 8)}',
      );

      // Clear cart
      cartProvider.clear();
      _instructionsController.clear();

      if (context.mounted) {
        // Show success
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 32),
                SizedBox(width: 12),
                Text('Order Placed!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order ID: #${order.orderId.substring(0, 8)}'),
                const SizedBox(height: 8),
                Text('Total: ₹${order.totalAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                const Text(
                  'Your order is being prepared. You will be notified when it\'s ready!',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close cart screen
                },
                child: const Text('View Order'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }
}