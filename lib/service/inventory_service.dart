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
        throw Exception('This product ID already exists.');
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
    throw Exception('Product $id does not exist.');
  }

  void updateProduct(Product product) {
    for (int index = 0; index < _products.length; index++) {
      if (_products[index].id == product.id) {
        _products[index] = product;
        return;
      }
    }
    throw Exception('Product ${product.id} does not exist.');
  }

  void deductStock(Cart cart) {
    if (cart.isEmpty) {
      throw Exception('There are no items to deduct.');
    }
    List<CartItem> items = cart.items;

    for (CartItem item in items) {
      Product product = getProduct(item.product.id);
      if (!product.isAvailable) {
        throw Exception('${product.name} is not available for sale.');
      }
      if (item.quantity > product.stockQuantity) {
        throw Exception('Not enough stock for ${product.name}.');
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
