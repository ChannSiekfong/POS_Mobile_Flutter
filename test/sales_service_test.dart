import 'package:test/test.dart';
import 'package:pos_mobile/model/product.dart';
import 'package:pos_mobile/model/sale.dart';
import 'package:pos_mobile/service/inventory_service.dart';
import 'package:pos_mobile/service/sales_service.dart';

void main() {
  var inventory = InventoryService();
  var sales = SalesService(inventory: inventory);

  setUp(() {
    inventory = InventoryService();
    inventory.addProduct(
      Product(
        id: 'water',
        name: 'Mineral Water',
        category: 'Beverages',
        priceCents: 75,
        stockQuantity: 2,
      ),
    );
    sales = SalesService(inventory: inventory);
  });

  test('completes a sale and returns the correct change', () {
    sales.addToCart('water');
    sales.updateCartQuantity('water', 2);
    Sale receipt = sales.checkout(cashReceivedCents: 200);

    expect(receipt.totalCents, 150);
    expect(receipt.changeCents, 50);
    expect(inventory.getProduct('water').stockQuantity, 0);
    expect(sales.cart.isEmpty, true);
    expect(sales.sales.length, 1);
  });

  test('rejects payment one cent below the total', () {
    sales.addToCart('water', quantity: 2);

    expect(() => sales.checkout(cashReceivedCents: 149), throwsException);
    expect(inventory.getProduct('water').stockQuantity, 2);
    expect(sales.cart.unitCount, 2);
    expect(sales.sales.length, 0);
  });

  test('rejects checkout when the cart is empty', () {
    sales.addToCart('water');
    sales.updateCartQuantity('water', 0);
    expect(() => sales.checkout(cashReceivedCents: 200), throwsException);
    expect(sales.sales.length, 0);
  });

  test('accepts exact payment for the last units in stock', () {
    sales.addToCart('water', quantity: 2);
    Sale receipt = sales.checkout(cashReceivedCents: 150);

    expect(receipt.changeCents, 0);
    expect(inventory.getProduct('water').stockQuantity, 0);
  });
}
