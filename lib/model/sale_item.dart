class SaleItem {
  final String productId;
  final String productName;
  final int unitPriceCents;
  final int quantity;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.unitPriceCents,
    required this.quantity,
  }) {
    if (productId.isEmpty || productName.isEmpty) {
      throw Exception('Receipt needs a product ID and name.');
    }
    if (unitPriceCents <= 0 || quantity <= 0) {
      throw Exception('Price and quantity must be greater than zero.');
    }
  }

  int get totalCents {
    return unitPriceCents * quantity;
  }
}
