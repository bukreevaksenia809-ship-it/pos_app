// lib/services/cash_register.dart

import '../models/product.dart';

class CashRegister {
  final List<ReceiptItem> items = [];
  ReceiptDiscount? receiptDiscount;

  bool addByBarcode(Product product) {
    // Проверяем, есть ли уже такой товар
    final existingIndex = items.indexWhere(
      (i) => i.productId == product.id
    );

    if (existingIndex != -1) {
      items[existingIndex].quantity += 1;
    } else {
      items.add(ReceiptItem(
        productId: product.id!,
        name: product.name,
        price: product.price,
        quantity: 1,
      ));
    }
    return true;
  }

  double get total {
    double sum = 0;
    for (final item in items) {
      sum += item.total;
    }
    return sum;
  }

  void clear() {
    items.clear();
    receiptDiscount?.clear();
    receiptDiscount = null;
  }

  double get totalWithDiscount {
    if (receiptDiscount == null || !receiptDiscount!.isActive) {
      return total;
    }
    return receiptDiscount!.apply(total);
  }

  double get discountAmount {
    if (receiptDiscount == null || !receiptDiscount!.isActive) {
      return 0;
    }
    return total - receiptDiscount!.apply(total);
  }

  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  void changeQuantity(int index, double delta) {
    if (index >= 0 && index < items.length) {
      items[index].quantity += delta;
      if (items[index].quantity <= 0) {
        items.removeAt(index);
      }
    }
  }
}