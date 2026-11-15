import '../model/cart.dart';
import '../model/cart_item.dart';
import '../model/product.dart';

class InventoryService {
  final List<Product> _products = [];

  List<Product> get products {
    return List<Product>.from(_products);
  }

  void addProduct(Product product) {
    for (Product savedProduct in _products) {
      if (savedProduct.id == product.id) {
        throw StateError('This product ID already exists.');
      }
    }
    _products.add(product);
  }

  Product getProduct(String id) {
    for (Product product in _products) {
      if (product.id == id) {
        return product;
      }
    }
    throw StateError('Product $id does not exist.');
  }

  void updateProduct(Product product) {
    for (int index = 0; index < _products.length; index++) {
      if (_products[index].id == product.id) {
        _products[index] = product;
        return;
      }
    }
    throw StateError('Product ${product.id} does not exist.');
  }

  void restockProduct(String productId, int quantity) {
    if (quantity <= 0) {
      throw ArgumentError('The restock quantity must be greater than zero.');
    }
    Product product = getProduct(productId);
    Product updatedProduct = Product(
      id: product.id,
      name: product.name,
      category: product.category,
      priceCents: product.priceCents,
      stockQuantity: product.stockQuantity + quantity,
      isAvailable: product.isAvailable,
    );
    updateProduct(updatedProduct);
  }

  List<Product> searchProducts(String query, {String category = ''}) {
    List<Product> results = [];
    String searchText = query.trim().toLowerCase();

    for (Product product in _products) {
      bool nameMatches = product.name.toLowerCase().contains(searchText);
      bool categoryMatches = category.isEmpty || product.category == category;
      if (nameMatches && categoryMatches) {
        results.add(product);
      }
    }
    return results;
  }

  void deductStock(Cart cart) {
    if (cart.isEmpty) {
      throw ArgumentError('There are no items to deduct.');
    }
    List<CartItem> items = cart.items;

    for (CartItem item in items) {
      Product product = getProduct(item.product.id);
      if (!product.isAvailable) {
        throw StateError('${product.name} is not available for sale.');
      }
      if (item.quantity > product.stockQuantity) {
        throw StateError('Not enough stock for ${product.name}.');
      }
    }

    for (CartItem item in items) {
      Product product = getProduct(item.product.id);
      Product updatedProduct = Product(
        id: product.id,
        name: product.name,
        category: product.category,
        priceCents: product.priceCents,
        stockQuantity: product.stockQuantity - item.quantity,
        isAvailable: product.isAvailable,
      );
      updateProduct(updatedProduct);
    }
  }
}
