import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../constants/colors.dart';
import '../../models/menu_item.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddFoodScreen extends StatefulWidget {
  final MenuItem? item; // For editing

  const AddFoodScreen({Key? key, this.item}) : super(key: key);

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String _selectedCategory = 'Breakfast';
  bool _isVeg = true;
  String _spiceLevel = 'medium';
  bool _isLoading = false;

  final List<String> _categories = [
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

  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  List<String> _selectedDays = [];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      // Editing mode
      _nameController.text = widget.item!.name;
      _descriptionController.text = widget.item!.description;
      _priceController.text = widget.item!.price.toString();
      _prepTimeController.text = widget.item!.preparationTime.toString();
      _imageUrlController.text = widget.item!.imageUrl;
      _selectedCategory = widget.item!.category;
      _isVeg = widget.item!.isVeg;
      _spiceLevel = widget.item!.spiceLevel;
      _selectedDays = List.from(widget.item!.availableDays);
    } else {
      // Default: select all days
      _selectedDays = List.from(_days);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _prepTimeController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Food Item' : 'Add Food Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              CustomTextField(
                label: 'Food Name',
                hint: 'Enter food name',
                controller: _nameController,
                prefixIcon: Icons.restaurant,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter food name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Description
              CustomTextField(
                label: 'Description',
                hint: 'Enter description',
                controller: _descriptionController,
                prefixIcon: Icons.description,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Price
              CustomTextField(
                label: 'Price (₹)',
                hint: 'Enter price',
                controller: _priceController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.currency_rupee,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter valid price';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Preparation Time
              CustomTextField(
                label: 'Preparation Time (minutes)',
                hint: 'Enter prep time',
                controller: _prepTimeController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.timer,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter preparation time';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter valid time';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Image URL
              CustomTextField(
                label: 'Image URL',
                hint: 'Enter image URL (optional)',
                controller: _imageUrlController,
                prefixIcon: Icons.image,
              ),

              const SizedBox(height: 32),

              // Category
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value!);
                },
              ),

              const SizedBox(height: 24),

              // Veg/Non-veg
              const Text(
                'Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Row(
                        children: [
                          Icon(Icons.circle,
                              size: 12, color: AppColors.vegGreen),
                          const SizedBox(width: 4),
                          const Text('Veg'),
                        ],
                      ),
                      value: true,
                      groupValue: _isVeg,
                      onChanged: (value) {
                        setState(() => _isVeg = value!);
                      },
                      activeColor: AppColors.vegGreen,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Row(
                        children: [
                          Icon(Icons.circle,
                              size: 12, color: AppColors.nonVegRed),
                          const SizedBox(width: 4),
                          const Text('Non-veg'),
                        ],
                      ),
                      value: false,
                      groupValue: _isVeg,
                      onChanged: (value) {
                        setState(() => _isVeg = value!);
                      },
                      activeColor: AppColors.nonVegRed,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Spice Level
              const Text(
                'Spice Level',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'none',
                    label: Text('None'),
                    icon: Icon(Icons.check, size: 16),
                  ),
                  ButtonSegment(
                    value: 'mild',
                    label: Text('Mild'),
                    icon: Icon(Icons.local_fire_department, size: 16),
                  ),
                  ButtonSegment(
                    value: 'medium',
                    label: Text('Medium'),
                    icon: Icon(Icons.local_fire_department, size: 16),
                  ),
                  ButtonSegment(
                    value: 'high',
                    label: Text('High'),
                    icon: Icon(Icons.local_fire_department, size: 16),
                  ),
                ],
                selected: {_spiceLevel},
                onSelectionChanged: (Set<String> selected) {
                  setState(() => _spiceLevel = selected.first);
                },
              ),

              const SizedBox(height: 24),

              // Available Days
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
                children: _days.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day[0].toUpperCase() + day.substring(1)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Save Button
              CustomButton(
                text: isEditing ? 'Update Food Item' : 'Add Food Item',
                icon: isEditing ? Icons.save : Icons.add,
                onPressed: _saveItem,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one available day'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final item = MenuItem(
        id: widget.item?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        category: _selectedCategory,
        price: double.parse(_priceController.text),
        description: _descriptionController.text.trim(),
        isVeg: _isVeg,
        spiceLevel: _spiceLevel,
        availableDays: _selectedDays,
        imageUrl: _imageUrlController.text.trim(),
        preparationTime: int.parse(_prepTimeController.text),
        isAvailable: widget.item?.isAvailable ?? true,
      );

      if (widget.item != null) {
        // Update existing item
        await DatabaseService().updateMenuItem(item);
      } else {
        // Add new item
        await DatabaseService().addMenuItem(item);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.item != null
                  ? 'Food item updated successfully'
                  : 'Food item added successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pop(context);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}