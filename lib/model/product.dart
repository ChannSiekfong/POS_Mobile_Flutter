class Product {
  final String id;
  final String name;
  final String category;
  final int priceCents;
  final int stockQuantity;
  final bool isAvailable;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.priceCents,
    required this.stockQuantity,
    this.isAvailable = true,
  }) {
    if (id.isEmpty || name.isEmpty || category.isEmpty) {
      throw Exception('Product ID, name, and category are required.');
    }
    if (priceCents <= 0) {
      throw Exception('Price must be greater than zero.');
    }
    if (stockQuantity < 0) {
      throw Exception('Stock must be greater than zero.');
    }
  }
}
