//lib/models/product.dart
class Product {
  final int? id;
  final String barcode;
  final String name;
  final String description;
  final double price;
  final String unit;
  final int? categoryId;
  final double stockQuantity;
  final double minStock;
  final bool isActive;
  final String? categoryName;

  Product({
    this.id,
    required this.barcode,
    required this.name,
    this.description = '',
    required this.price,
    this.unit = 'шт',
    this.categoryId,
    this.stockQuantity = 0,
    this.minStock = 0,
    this.isActive = true,
    this.categoryName,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'barcode': barcode,
    'name': name,
    'description': description,
    'price': price,
    'unit': unit,
    'category_id': categoryId,
    'stock_quantity': stockQuantity,
    'min_stock': minStock,
    'is_active': isActive ? 1 : 0,
  };

  factory Product.fromMap(Map<String, dynamic> map) => Product(
    id: map['id'],
    barcode: map['barcode'] ?? '',
    name: map['name'] ?? '',
    description: map['description'] ?? '',
    price: (map['price'] ?? 0).toDouble(),
    unit: map['unit'] ?? 'шт',
    categoryId: map['category_id'],
    stockQuantity: (map['stock_quantity'] ?? 0).toDouble(),
    minStock: (map['min_stock'] ?? 0).toDouble(),
    isActive: map['is_active'] == 1,
    categoryName: map['category_name'],
  );
}

class ReceiptItem {
  final int productId;
  final String name;
  double price;
  double quantity;
  ItemDiscount? discount;

  ReceiptItem({
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.discount,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() => {
    'product_id': productId,
    'product_name': name,
    'price': price,
    'quantity': quantity,
    'total': total,
  };
}

class ItemDiscount {
  String? type;
  double value = 0;

  ItemDiscount({this.type, this.value = 0});

  bool get isActive => type != null && value > 0;

  double apply(double price, double quantity) {
    final total = price * quantity;
    double newTotal;
    if (type == 'percent') {
      newTotal = total * (1 - value / 100);
    } else if (type == 'fixed') {
      newTotal = total - value;
    } else {
      return price;
    }
    return newTotal / quantity;
  }

  String get label {
    if (!isActive) return '';
    if (type == 'percent') return '-${value.toStringAsFixed(0)}%';
    return '-${value.toStringAsFixed(0)}₽';
  }

  void setPercent(double percent) {
    type = 'percent';
    value = percent;
  }

  void setFixed(double amount) {
    type = 'fixed';
    value = amount;
  }

  void clear() {
    type = null;
    value = 0;
  }
}

class ReceiptDiscount {
  String? type;
  double value = 0;

  bool get isActive => type != null && value > 0;

  String get label {
    if (!isActive) return '';
    if (type == 'percent') return 'Скидка ${value.toStringAsFixed(0)}%';
    return 'Скидка ${value.toStringAsFixed(2)}₽';
  }

  void setPercent(double percent) {
    type = 'percent';
    value = percent;
  }

  void setFixed(double amount) {
    type = 'fixed';
    value = amount;
  }

  void clear() {
    type = null;
    value = 0;
  }

  double apply(double total) {
    if (!isActive) return total;
    if (type == 'percent') {
      return total * (1 - value / 100);
    } else {
      return total - value;
    }
  }
}