import 'cart_item.dart';

class Cart {
  final List<CartItem> _items = [];

  Cart({List<CartItem> items = const []}) {
    for (CartItem newItem in items) {
      for (CartItem savedItem in _items) {
        if (newItem.product.id == savedItem.product.id) {
          throw Exception('Product cannot appear in two cart lines.');
        }
      }
      _items.add(newItem);
    }
  }

  List<CartItem> get items {
    return List<CartItem>.from(_items);
  }

  bool get isEmpty {
    return _items.isEmpty;
  }

  int get productCount {
    return _items.length;
  }

  int get unitCount {
    int count = 0;
    for (CartItem item in _items) {
      count = count + item.quantity;
    }
    return count;
  }

  int get totalCents {
    int total = 0;
    for (CartItem item in _items) {
      total = total + item.totalCents;
    }
    return total;
  }
}
