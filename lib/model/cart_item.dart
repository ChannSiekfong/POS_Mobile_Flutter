import 'product.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity}) {
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than zero.');
    }
  }

  int get totalCents {
    return product.priceCents * quantity;
  }
}
