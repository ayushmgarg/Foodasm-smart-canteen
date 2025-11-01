import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../models/menu_item.dart';
import '../../services/database_service.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/menu_card.dart';
import '../../widgets/loading_widget.dart';
import 'food_detail_screen.dart';
import '../../constants/food_data.dart';
import '../../services/ai_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _vegOnly = false;
  bool _availableToday = false;

  final List<String> _categories = [
    'All',
    'Breakfast',
    'Rice',
    'Curry',
    'Bread',
    'Snacks',
    'South Indian',
    'Beverages',
    'Desserts',
    'Indo-Chinese',
    'Thali',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for food...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value.toLowerCase());
            },
          ),
        ),

        // TEMPORARY: Re-initialize button for admin
        StreamBuilder<List<MenuItem>>(
          stream: DatabaseService().getMenuItems(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final count = snapshot.data!.length;
              if (count < 100) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Only $count items in database',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Click to add all 100 items',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _clearAndInitializeMenu,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Fix Now'),
                      ),
                    ],
                  ),
                );
              }
            }
            return const SizedBox.shrink();
          },
        ),

        // Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              // Veg Only Filter
              FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: _vegOnly ? AppColors.vegGreen : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    const Text('Veg Only'),
                  ],
                ),
                selected: _vegOnly,
                onSelected: (selected) {
                  setState(() => _vegOnly = selected);
                },
                selectedColor: AppColors.vegGreen.withOpacity(0.2),
                checkmarkColor: AppColors.vegGreen,
              ),
              const SizedBox(width: 8),
              
              // Available Today Filter
              FilterChip(
                label: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.today, size: 14),
                    SizedBox(width: 4),
                    Text('Today'),
                  ],
                ),
                selected: _availableToday,
                onSelected: (selected) {
                  setState(() => _availableToday = selected);
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
              ),
              
              const Spacer(),
              
              // Active Filters Count
              if (_vegOnly || _availableToday || _selectedCategory != 'All')
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _vegOnly = false;
                      _availableToday = false;
                      _selectedCategory = 'All';
                    });
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),

        // Quick AI Suggestion Banner
        StreamBuilder<List<MenuItem>>(
          stream: DatabaseService().getMenuItems(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            return FutureBuilder<String>(
              future: AIService().getQuickSuggestion(
                mealType: _selectedCategory == 'All' ? 'Breakfast' : _selectedCategory,
                menu: snapshot.data!,
              ),
              builder: (context, aiSnapshot) {
                if (!aiSnapshot.hasData) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.blue.shade400],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Suggestion',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              aiSnapshot.data!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),

        // Category Chips
        Container(
          height: 50,
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = category);
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),

        const Divider(height: 1),

        // Menu Items Grid
        Expanded(
          child: StreamBuilder<List<MenuItem>>(
            stream: DatabaseService().getMenuItems(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget(message: 'Loading menu...');
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.restaurant_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No menu items available',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                      'Contact admin to add food items',
                       style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                     ),
                    ],
                  ),
                );
              }

              // Filter items
              List<MenuItem> items = snapshot.data!;
              
              // Filter by category
              if (_selectedCategory != 'All') {
                items = items
                    .where((item) => item.category == _selectedCategory)
                    .toList();
              }
              
              // Filter by search
              if (_searchQuery.isNotEmpty) {
                items = items.where((item) {
                  return item.name.toLowerCase().contains(_searchQuery) ||
                      item.description.toLowerCase().contains(_searchQuery) ||
                      item.category.toLowerCase().contains(_searchQuery);
                }).toList();
              }

              // Filter by veg only
              if (_vegOnly) {
                items = items.where((item) => item.isVeg).toList();
              }

              // Filter by available today
              if (_availableToday) {
                String today = _getTodayDay();
                items = items.where((item) => 
                  item.availableDays.contains(today)
                ).toList();
              }

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No items found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _selectedCategory = 'All';
                            _vegOnly = false;
                            _availableToday = false;
                          });
                        },
                        child: const Text('Clear all filters'),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.70,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return MenuCard(
                    item: item,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FoodDetailScreen(item: item),
                        ),
                      );
                    },
                    onAddToCart: () {
                      Provider.of<CartProvider>(context, listen: false)
                          .addItem(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.name} added to cart'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  );
                }
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _clearAndInitializeMenu() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Re-initialize Menu'),
      content: const Text(
        'This will DELETE all existing menu items and add fresh 100 items. Continue?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Yes, Re-initialize'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleting old items and adding 100 new items... Please wait'),
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Step 1: Delete all existing menu items
      final querySnapshot = await FirebaseFirestore.instance
          .collection('menuItems')
          .get();
      
      print('🗑️ Deleting ${querySnapshot.docs.length} old items...');
      
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
      
      print('✅ Old items deleted');
      
      // Step 2: Add 100 new items
      print('📦 Adding 100 new items...');
      await DatabaseService().initializeMenuItems(INDIAN_FOOD_ITEMS);
      
      // Step 3: Verify count
      final newSnapshot = await FirebaseFirestore.instance
          .collection('menuItems')
          .get();
      
      print('✅ Total items now: ${newSnapshot.docs.length}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Successfully added ${newSnapshot.docs.length} food items!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error: $e');
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

  Future<void> _initializeMenu() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initialize Menu'),
        content: const Text(
          'This will add 50 Indian food items to your database. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Add Items'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Show loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adding 50 food items... Please wait'),
              duration: Duration(seconds: 3),
            ),
          );
        }

        await DatabaseService().initializeMenuItems(INDIAN_FOOD_ITEMS);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 50 food items added successfully!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
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
}