import 'package:test/test.dart';
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
  var inventory = InventoryService();

  setUp(() {
    inventory = InventoryService();
  });

  test('adds a product and finds it by ID', () {
    inventory.addProduct(product());

    expect(inventory.getProduct('water').priceCents, 75);
    expect(inventory.products.length, 1);
  });

  test('rejects a duplicate product ID', () {
    inventory.addProduct(product());

    expect(() => inventory.addProduct(product(price: 100)), throwsException);
    expect(inventory.getProduct('water').priceCents, 75);
  });

  test('updates an existing product', () {
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

    Product updated = inventory.getProduct('water');
    expect(updated.name, 'Spring Water');
    expect(updated.priceCents, 100);
    expect(updated.isAvailable, false);
  });

  test('deducts all remaining units down to zero', () {
    inventory.addProduct(product(stock: 2));

    Cart cart = Cart(
      items: [CartItem(product: inventory.getProduct('water'), quantity: 2)],
    );
    inventory.deductStock(cart);

    expect(inventory.getProduct('water').stockQuantity, 0);
  });
}
