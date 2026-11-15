import 'package:flutter_test/flutter_test.dart';
import 'package:pos_mobile/model/cart.dart';
import 'package:pos_mobile/model/cart_item.dart';
import 'package:pos_mobile/model/product.dart';
import 'package:pos_mobile/service/inventory_service.dart';

Product product({
  String id = 'water',
  String name = 'Mineral Water',
  String category = 'Beverages',
  int price = 75,
  int stock = 24,
}) {
  return Product(
    id: id,
    name: name,
    category: category,
    priceCents: price,
    stockQuantity: stock,
  );
}

void main() {
  late InventoryService inventory;

  setUp(() {
    inventory = InventoryService();
  });

  group('Product management', () {
    test('adds a valid product and retrieves it by ID', () {
      inventory.addProduct(product());
      expect(inventory.getProduct('water').priceCents, 75);
      expect(inventory.products, hasLength(1));
    });

    test('rejects duplicate IDs without replacing the original product', () {
      inventory.addProduct(product());
      expect(() => inventory.addProduct(product(price: 100)), throwsStateError);
      expect(inventory.getProduct('water').priceCents, 75);
    });

    test('rejects missing products and updates of unknown products', () {
      expect(() => inventory.getProduct('missing'), throwsStateError);
      expect(() => inventory.updateProduct(product()), throwsStateError);
      expect(inventory.products, isEmpty);
    });

    test('rejects empty fields, nonpositive prices, and negative stock', () {
      expect(() => product(id: ''), throwsException);
      expect(() => product(name: ''), throwsException);
      expect(() => product(category: ''), throwsException);
      expect(() => product(price: 0), throwsException);
      expect(() => product(price: -1), throwsException);
      expect(() => product(stock: -1), throwsException);
    });

    test('accepts zero stock and a one-cent price as boundary values', () {
      inventory.addProduct(product(price: 1, stock: 0));
      expect(inventory.getProduct('water').stockQuantity, 0);
      expect(inventory.getProduct('water').priceCents, 1);
    });

    test('updates price, name, category, and availability', () {
      inventory.addProduct(product());
      inventory.updateProduct(
        Product(
          id: 'water',
          name: 'Spring Water',
          category: 'Other',
          priceCents: 100,
          stockQuantity: 24,
          isAvailable: false,
        ),
      );
      final updated = inventory.getProduct('water');
      expect(updated.name, 'Spring Water');
      expect(updated.category, 'Other');
      expect(updated.priceCents, 100);
      expect(updated.isAvailable, isFalse);
      expect(updated.stockQuantity, 24);
    });

    test('searches names without case sensitivity and filters categories', () {
      inventory.addProduct(product());
      inventory.addProduct(
        product(id: 'chips', name: 'Potato Chips', category: 'Snacks'),
      );
      expect(inventory.searchProducts('  WATER  ').single.id, 'water');
      expect(
        inventory.searchProducts('', category: 'Snacks').single.id,
        'chips',
      );
      expect(inventory.searchProducts('missing'), isEmpty);
    });
  });

  group('Stock operations', () {
    setUp(() {
      inventory.addProduct(product(stock: 2));
    });

    test('restocks an existing product', () {
      inventory.restockProduct('water', 3);
      expect(inventory.getProduct('water').stockQuantity, 5);
    });

    test('rejects zero, negative, and unknown-product restocks', () {
      expect(() => inventory.restockProduct('water', 0), throwsArgumentError);
      expect(() => inventory.restockProduct('water', -1), throwsArgumentError);
      expect(() => inventory.restockProduct('missing', 1), throwsStateError);
      expect(inventory.getProduct('water').stockQuantity, 2);
    });

    test('deducts the exact remaining stock down to zero', () {
      Cart cart = Cart(
        items: [CartItem(product: inventory.getProduct('water'), quantity: 2)],
      );
      inventory.deductStock(cart);
      expect(inventory.getProduct('water').stockQuantity, 0);
    });

    test('an invalid second product cannot partially deduct the first', () {
      inventory.addProduct(product(id: 'chips', stock: 0));
      Cart cart = Cart(
        items: [
          CartItem(product: inventory.getProduct('water'), quantity: 1),
          CartItem(product: inventory.getProduct('chips'), quantity: 1),
        ],
      );
      expect(() => inventory.deductStock(cart), throwsStateError);
      expect(inventory.getProduct('water').stockQuantity, 2);
      expect(inventory.getProduct('chips').stockQuantity, 0);
    });

    test('rejects empty deductions and duplicate product lines', () {
      expect(() => inventory.deductStock(Cart()), throwsArgumentError);
      expect(
        () => Cart(
          items: [
            CartItem(product: inventory.getProduct('water'), quantity: 2),
            CartItem(product: inventory.getProduct('water'), quantity: 2),
          ],
        ),
        throwsException,
      );
      expect(inventory.getProduct('water').stockQuantity, 2);
    });

    test('editing a returned list does not change the inventory', () {
      List<Product> returnedProducts = inventory.products;
      returnedProducts.clear();
      expect(inventory.products, hasLength(1));
    });
  });
}
