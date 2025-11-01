class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String description;
  final bool isVeg;
  final String spiceLevel;
  final List<String> availableDays;
  final String imageUrl;
  final int preparationTime; // in minutes
  final bool isAvailable;

  MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.isVeg,
    this.spiceLevel = 'medium',
    this.availableDays = const [],
    this.imageUrl = '',
    this.preparationTime = 15,
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'isVeg': isVeg,
      'spiceLevel': spiceLevel,
      'availableDays': availableDays,
      'imageUrl': imageUrl,
      'preparationTime': preparationTime,
      'isAvailable': isAvailable,
    };
  }

  factory MenuItem.fromMap(String id, Map<String, dynamic> map) {
    return MenuItem(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      isVeg: map['isVeg'] ?? true,
      spiceLevel: map['spiceLevel'] ?? 'medium',
      availableDays: List<String>.from(map['availableDays'] ?? []),
      imageUrl: map['imageUrl'] ?? '',
      preparationTime: map['preparationTime'] ?? 15,
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  MenuItem copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? description,
    bool? isVeg,
    String? spiceLevel,
    List<String>? availableDays,
    String? imageUrl,
    int? preparationTime,
    bool? isAvailable,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      isVeg: isVeg ?? this.isVeg,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      availableDays: availableDays ?? this.availableDays,
      imageUrl: imageUrl ?? this.imageUrl,
      preparationTime: preparationTime ?? this.preparationTime,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}