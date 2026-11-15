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
}
