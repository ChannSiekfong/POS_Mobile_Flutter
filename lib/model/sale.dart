import 'sale_item.dart';

class Sale {
  final String id;
  final DateTime completedAt;
  final int cashReceivedCents;
  final List<SaleItem> _items = [];

  Sale({
    required this.id,
    required this.completedAt,
    required List<SaleItem> items,
    required this.cashReceivedCents,
  }) {
    if (id.isEmpty || items.isEmpty) {
      throw Exception('A sale needs an ID and at least one item.');
    }
    for (SaleItem item in items) {
      _items.add(item);
    }
    if (cashReceivedCents < totalCents) {
      throw Exception('The cash received must cover the total.');
    }
  }

  List<SaleItem> get items {
    return List<SaleItem>.from(_items);
  }

  int get totalCents {
    int total = 0;
    for (SaleItem item in _items) {
      total = total + item.totalCents;
    }
    return total;
  }

  int get unitCount {
    int count = 0;
    for (SaleItem item in _items) {
      count = count + item.quantity;
    }
    return count;
  }

  int get changeCents {
    return cashReceivedCents - totalCents;
  }
}
