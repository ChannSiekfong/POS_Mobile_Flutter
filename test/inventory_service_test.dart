import 'package:test/test.dart';
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

  test('adds a valid product and retrieves it by ID', () {
    inventory.addProduct(product());
    expect(inventory.getProduct('water').priceCents, 75);
    expect(inventory.products, hasLength(1));
  });

  test('rejects duplicate IDs without replacing the original product', () {
    inventory.addProduct(product());
    expect(() => inventory.addProduct(product(price: 100)), throwsException);
    expect(inventory.getProduct('water').priceCents, 75);
  });

  test('rejects missing products and updates of unknown products', () {
    expect(() => inventory.getProduct('missing'), throwsException);
    expect(() => inventory.updateProduct(product()), throwsException);
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
}
