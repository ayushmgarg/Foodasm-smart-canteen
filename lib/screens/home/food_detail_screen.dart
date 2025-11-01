import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../models/menu_item.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/custom_button.dart';

class FoodDetailScreen extends StatefulWidget {
  final MenuItem item;

  const FoodDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: widget.item.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.restaurant, size: 80),
                ),
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & Veg Indicator
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.item.isVeg
                                ? AppColors.vegGreen.withOpacity(0.1)
                                : AppColors.nonVegRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.circle,
                            size: 16,
                            color: widget.item.isVeg
                                ? AppColors.vegGreen
                                : AppColors.nonVegRed,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Category & Spice Level
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(widget.item.category),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          labelStyle: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.item.spiceLevel != 'none')
                          Chip(
                            avatar: Icon(
                              Icons.local_fire_department,
                              size: 16,
                              color: _getSpiceColor(widget.item.spiceLevel),
                            ),
                            label: Text(widget.item.spiceLevel.toUpperCase()),
                            backgroundColor:
                                _getSpiceColor(widget.item.spiceLevel)
                                    .withOpacity(0.1),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      widget.item.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Info Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.schedule,
                            title: 'Prep Time',
                            value: '${widget.item.preparationTime} mins',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                            icon: Icons.currency_rupee,
                            title: 'Price',
                            value: '₹${widget.item.price.toStringAsFixed(0)}',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Available Days
                    if (widget.item.availableDays.isNotEmpty) ...[
                      const Text(
                        'Available Days',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: widget.item.availableDays.map((day) {
                          return Chip(
                            label: Text(
                              day[0].toUpperCase() + day.substring(1),
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: AppColors.background,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Quantity Selector
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Total Price & Add to Cart
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Price',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '₹${(widget.item.price * _quantity).toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: CustomButton(
                            text: 'Add to Cart',
                            icon: Icons.shopping_cart,
                            onPressed: () {
                              final cartProvider =
                                  Provider.of<CartProvider>(context, listen: false);
                              
                              for (int i = 0; i < _quantity; i++) {
                                cartProvider.addItem(widget.item);
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '$_quantity x ${widget.item.name} added to cart',
                                  ),
                                  backgroundColor: AppColors.success,
                                  duration: const Duration(seconds: 2),
                                ),
                              );

                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSpiceColor(String level) {
    switch (level.toLowerCase()) {
      case 'mild':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}