import '../model/cart.dart';
import '../model/cart_item.dart';
import '../model/product.dart';
import '../model/sale.dart';
import '../model/sale_item.dart';
import 'inventory_service.dart';

class SalesService {
  final InventoryService inventory;
  Cart _cart = Cart();
  final List<Sale> _sales = [];
  int _nextSaleNumber = 1;

  SalesService({required this.inventory});

  Cart get cart {
    return _cart;
  }

  List<Sale> get sales {
    List<Sale> newestFirst = [];
    for (int index = _sales.length - 1; index >= 0; index--) {
      newestFirst.add(_sales[index]);
    }
    return newestFirst;
  }

  void addToCart(String productId, {int quantity = 1}) {
    if (quantity <= 0) {
      throw Exception('The quantity must be greater than zero.');
    }
    Product product = inventory.getProduct(productId);
    List<CartItem> items = _cart.items;

    for (int index = 0; index < items.length; index++) {
      CartItem item = items[index];
      if (item.product.id == productId) {
        int newQuantity = item.quantity + quantity;
        _checkStock(product, newQuantity);
        items[index] = CartItem(product: item.product, quantity: newQuantity);
        _cart = Cart(items: items);
        return;
      }
    }

    _checkStock(product, quantity);
    items.add(CartItem(product: product, quantity: quantity));
    _cart = Cart(items: items);
  }

  void updateCartQuantity(String productId, int quantity) {
    if (quantity < 0) {
      throw Exception('The quantity cannot be negative.');
    }
    List<CartItem> items = _cart.items;
    for (int index = 0; index < items.length; index++) {
      CartItem item = items[index];
      if (item.product.id == productId) {
        if (quantity == 0) {
          items.removeAt(index);
        } else {
          Product product = inventory.getProduct(productId);
          _checkStock(product, quantity);
          items[index] = CartItem(product: item.product, quantity: quantity);
        }
        _cart = Cart(items: items);
        return;
      }
    }
    throw Exception('This product is not in the cart.');
  }

  Sale checkout({required int cashReceivedCents}) {
    if (_cart.isEmpty) {
      throw Exception('The cart is empty.');
    }
    if (cashReceivedCents < _cart.totalCents) {
      throw Exception('The cash received must cover the cart total.');
    }

    List<SaleItem> receiptItems = [];
    for (CartItem item in _cart.items) {
      SaleItem receiptItem = SaleItem(
        productId: item.product.id,
        productName: item.product.name,
        unitPriceCents: item.product.priceCents,
        quantity: item.quantity,
      );
      receiptItems.add(receiptItem);
    }

    String saleId = 'TRX-${_nextSaleNumber.toString().padLeft(4, '0')}';
    Sale sale = Sale(
      id: saleId,
      completedAt: DateTime.now(),
      items: receiptItems,
      cashReceivedCents: cashReceivedCents,
    );

    inventory.deductStock(_cart);
    _sales.add(sale);
    _nextSaleNumber = _nextSaleNumber + 1;
    _cart = Cart();
    return sale;
  }

  void _checkStock(Product product, int quantity) {
    if (!product.isAvailable) {
      throw Exception('${product.name} is not available for sale.');
    }
    if (quantity > product.stockQuantity) {
      throw Exception('Not enough stock for ${product.name}.');
    }
  }
}
