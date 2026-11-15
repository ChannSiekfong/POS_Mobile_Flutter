import 'package:test/test.dart';
import 'package:pos_mobile/model/cart_item.dart';
import 'package:pos_mobile/model/product.dart';
import 'package:pos_mobile/model/sale.dart';
import 'package:pos_mobile/model/sale_item.dart';
import 'package:pos_mobile/service/inventory_service.dart';
import 'package:pos_mobile/service/sales_service.dart';

void main() {
  late InventoryService inventory;
  late SalesService sales;

  setUp(() {
    inventory = InventoryService();
    for (final product in [
      Product(
        id: 'water',
        name: 'Mineral Water',
        category: 'Beverages',
        priceCents: 75,
        stockQuantity: 24,
      ),
      Product(
        id: 'cola',
        name: 'Coca-Cola',
        category: 'Beverages',
        priceCents: 125,
        stockQuantity: 18,
      ),
      Product(
        id: 'chips',
        name: 'Potato Chips',
        category: 'Snacks',
        priceCents: 150,
        stockQuantity: 12,
      ),
      Product(
        id: 'juice',
        name: 'Orange Juice',
        category: 'Beverages',
        priceCents: 200,
        stockQuantity: 0,
      ),
    ]) {
      inventory.addProduct(product);
    }
    sales = SalesService(inventory: inventory);
  });

  void fillExampleCart() {
    sales.addToCart('water', quantity: 2);
    sales.addToCart('cola');
    sales.addToCart('chips');
  }

  group('Cart operations', () {
    test('calculates three products, four units, and 425 cents', () {
      fillExampleCart();
      expect(sales.cart.productCount, 3);
      expect(sales.cart.unitCount, 4);
      expect(sales.cart.totalCents, 425);
    });

    test('merges repeated additions into one product line', () {
      sales.addToCart('water');
      sales.addToCart('water', quantity: 2);
      expect(sales.cart.productCount, 1);
      expect(sales.cart.unitCount, 3);
      expect(sales.cart.totalCents, 225);
    });

    test('rejects nonpositive quantities and unknown products', () {
      expect(() => sales.addToCart('water', quantity: 0), throwsArgumentError);
      expect(() => sales.addToCart('water', quantity: -1), throwsArgumentError);
      expect(() => sales.addToCart('missing'), throwsStateError);
      expect(sales.cart.isEmpty, isTrue);
    });

    test('rejects unavailable and out-of-stock products', () {
      inventory.updateProduct(
        Product(
          id: 'cola',
          name: 'Coca-Cola',
          category: 'Beverages',
          priceCents: 125,
          stockQuantity: 18,
          isAvailable: false,
        ),
      );
      expect(() => sales.addToCart('cola'), throwsStateError);
      expect(() => sales.addToCart('juice'), throwsStateError);
      expect(sales.cart.isEmpty, isTrue);
    });

    test(
      'checks cumulative quantity against stock without changing the cart',
      () {
        sales.addToCart('water', quantity: 24);
        expect(() => sales.addToCart('water'), throwsStateError);
        expect(sales.cart.unitCount, 24);
        expect(inventory.getProduct('water').stockQuantity, 24);
      },
    );

    test('changes quantities and removes a line at zero', () {
      sales.addToCart('water');
      sales.updateCartQuantity('water', 3);
      expect(sales.cart.totalCents, 225);
      sales.updateCartQuantity('water', 0);
      expect(sales.cart.isEmpty, isTrue);
    });

    test('rejects negative, excessive, and missing-line quantity changes', () {
      sales.addToCart('water');
      expect(() => sales.updateCartQuantity('water', -1), throwsArgumentError);
      expect(() => sales.updateCartQuantity('water', 25), throwsStateError);
      expect(() => sales.updateCartQuantity('missing', 1), throwsStateError);
      expect(sales.cart.unitCount, 1);
    });

    test('removes selected lines and clears without changing stock', () {
      fillExampleCart();
      sales.removeFromCart('cola');
      expect(sales.cart.productCount, 2);
      expect(sales.cart.totalCents, 300);
      expect(() => sales.removeFromCart('cola'), throwsStateError);
      sales.clearCart();
      expect(sales.cart.isEmpty, isTrue);
      expect(inventory.getProduct('water').stockQuantity, 24);
    });

    test('editing a returned list does not change the cart', () {
      sales.addToCart('water');
      final oldCart = sales.cart;
      List<CartItem> returnedItems = oldCart.items;
      returnedItems.clear();
      sales.addToCart('cola');
      expect(oldCart.productCount, 1);
      expect(sales.cart.productCount, 2);
    });
  });

  group('Checkout operations', () {
    test(
      'records a multi-product cash sale, updates stock, and clears cart',
      () {
        fillExampleCart();
        DateTime beforeCheckout = DateTime.now();
        final receipt = sales.checkout(cashReceivedCents: 1000);
        DateTime afterCheckout = DateTime.now();
        expect(receipt.id, 'TRX-0001');
        expect(receipt.totalCents, 425);
        expect(receipt.changeCents, 575);
        expect(receipt.unitCount, 4);
        expect(receipt.completedAt.isBefore(beforeCheckout), isFalse);
        expect(receipt.completedAt.isAfter(afterCheckout), isFalse);
        expect(inventory.getProduct('water').stockQuantity, 22);
        expect(inventory.getProduct('cola').stockQuantity, 17);
        expect(inventory.getProduct('chips').stockQuantity, 11);
        expect(sales.cart.isEmpty, isTrue);
        expect(sales.getSale(receipt.id), same(receipt));
      },
    );

    test('accepts exact cash and returns zero change', () {
      sales.addToCart('water');
      expect(sales.checkout(cashReceivedCents: 75).changeCents, 0);
    });

    test(
      'rejects payment one cent short, preserving cart, stock, and history',
      () {
        fillExampleCart();
        expect(
          () => sales.checkout(cashReceivedCents: 424),
          throwsArgumentError,
        );
        expect(sales.cart.totalCents, 425);
        expect(inventory.getProduct('water').stockQuantity, 24);
        expect(sales.sales, isEmpty);
        expect(sales.checkout(cashReceivedCents: 425).id, 'TRX-0001');
      },
    );

    test('rejects negative cash and empty-cart checkout', () {
      expect(() => sales.checkout(cashReceivedCents: 1000), throwsStateError);
      sales.addToCart('water');
      expect(() => sales.checkout(cashReceivedCents: -1), throwsArgumentError);
      expect(sales.cart.unitCount, 1);
      expect(sales.sales, isEmpty);
    });

    test(
      'rechecks stock at checkout and never partially deducts other lines',
      () {
        fillExampleCart();
        inventory.updateProduct(
          Product(
            id: 'chips',
            name: 'Potato Chips',
            category: 'Snacks',
            priceCents: 150,
            stockQuantity: 0,
          ),
        );
        expect(() => sales.checkout(cashReceivedCents: 1000), throwsStateError);
        expect(inventory.getProduct('water').stockQuantity, 24);
        expect(inventory.getProduct('cola').stockQuantity, 18);
        expect(sales.cart.unitCount, 4);
        expect(sales.sales, isEmpty);
      },
    );

    test('rechecks product availability at checkout', () {
      sales.addToCart('water');
      inventory.updateProduct(
        Product(
          id: 'water',
          name: 'Mineral Water',
          category: 'Beverages',
          priceCents: 75,
          stockQuantity: 24,
          isAvailable: false,
        ),
      );
      expect(() => sales.checkout(cashReceivedCents: 1000), throwsStateError);
      expect(inventory.getProduct('water').stockQuantity, 24);
      expect(sales.cart.unitCount, 1);
      expect(sales.sales, isEmpty);
    });

    test('selling the last unit prevents another sale of that product', () {
      sales.addToCart('water', quantity: 24);
      sales.checkout(cashReceivedCents: 1800);
      expect(inventory.getProduct('water').stockQuantity, 0);
      expect(() => sales.addToCart('water'), throwsStateError);
      expect(sales.sales, hasLength(1));
    });

    test(
      'keeps the original cart price and protects the completed receipt',
      () {
        sales.addToCart('water');
        inventory.updateProduct(
          Product(
            id: 'water',
            name: 'New Water',
            category: 'Beverages',
            priceCents: 100,
            stockQuantity: 24,
          ),
        );
        final receipt = sales.checkout(cashReceivedCents: 75);
        expect(receipt.items.single.productName, 'Mineral Water');
        expect(receipt.totalCents, 75);
        inventory.updateProduct(
          Product(
            id: 'water',
            name: 'New Water',
            category: 'Beverages',
            priceCents: 200,
            stockQuantity: 23,
          ),
        );
        expect(receipt.totalCents, 75);
        List<SaleItem> returnedItems = receipt.items;
        returnedItems.clear();
        expect(receipt.items.length, 1);
        expect(receipt.totalCents, 75);
      },
    );

    test('repeating checkout cannot record the completed cart twice', () {
      sales.addToCart('water');
      sales.checkout(cashReceivedCents: 75);
      expect(() => sales.checkout(cashReceivedCents: 75), throwsStateError);
      expect(sales.sales, hasLength(1));
      expect(inventory.getProduct('water').stockQuantity, 23);
    });

    test('history is newest first, IDs differ, and revenue filters by day', () {
      sales.addToCart('water');
      final first = sales.checkout(cashReceivedCents: 75);
      sales.addToCart('cola');
      final second = sales.checkout(cashReceivedCents: 125);
      expect(first.id, isNot(second.id));
      List<Sale> history = sales.sales;
      expect(history[0].id, second.id);
      expect(history[1].id, first.id);

      DateTime firstDate = first.completedAt;
      DateTime secondDate = second.completedAt;
      bool sameDay =
          firstDate.year == secondDate.year &&
          firstDate.month == secondDate.month &&
          firstDate.day == secondDate.day;
      if (sameDay) {
        expect(sales.revenueForDate(firstDate), 200);
      } else {
        expect(sales.revenueForDate(firstDate), 75);
        expect(sales.revenueForDate(secondDate), 125);
      }
      DateTime followingDay = DateTime(
        secondDate.year,
        secondDate.month,
        secondDate.day + 1,
      );
      expect(sales.revenueForDate(followingDay), 0);
      expect(() => sales.getSale('missing'), throwsStateError);
      history.clear();
      expect(sales.sales.length, 2);
    });
  });

  test('a cart line rejects zero or negative units', () {
    expect(
      () => CartItem(product: inventory.getProduct('water'), quantity: 0),
      throwsException,
    );
    expect(
      () => CartItem(product: inventory.getProduct('water'), quantity: -1),
      throwsException,
    );
  });
}
