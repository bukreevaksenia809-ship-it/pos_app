// lib/models/shift.dart

class Shift {
  final int? id;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingBalance;
  final double closingBalance;
  final int? receiptCount;
  final double? totalRevenue;

  Shift({
    this.id,
    required this.openedAt,
    this.closedAt,
    this.openingBalance = 0,
    this.closingBalance = 0,
    this.receiptCount,
    this.totalRevenue,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'opened_at': openedAt.toIso8601String(),
    'closed_at': closedAt?.toIso8601String(),
    'opening_balance': openingBalance,
    'closing_balance': closingBalance,
  };

  factory Shift.fromMap(Map<String, dynamic> map) => Shift(
    id: map['id'],
    openedAt: DateTime.parse(map['opened_at']),
    closedAt: map['closed_at'] != null ? DateTime.parse(map['closed_at']) : null,
    openingBalance: (map['opening_balance'] ?? 0).toDouble(),
    closingBalance: (map['closing_balance'] ?? 0).toDouble(),
    receiptCount: map['receipt_count'],
    totalRevenue: map['total_revenue']?.toDouble(),
  );

  bool get isOpen => closedAt == null;

  String get formattedOpened {
    return '${openedAt.day.toString().padLeft(2, '0')}.${openedAt.month.toString().padLeft(2, '0')}.${openedAt.year} ${openedAt.hour.toString().padLeft(2, '0')}:${openedAt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedClosed {
    if (closedAt == null) return 'Открыта';
    return '${closedAt!.day.toString().padLeft(2, '0')}.${closedAt!.month.toString().padLeft(2, '0')}.${closedAt!.year} ${closedAt!.hour.toString().padLeft(2, '0')}:${closedAt!.minute.toString().padLeft(2, '0')}';
  }
}

class ShiftStats {
  final int totalReceipts;
  final double totalRevenue;
  final double avgReceipt;

  ShiftStats({
    required this.totalReceipts,
    required this.totalRevenue,
    required this.avgReceipt,
  });

  factory ShiftStats.fromMap(Map<String, dynamic> map) => ShiftStats(
    totalReceipts: map['total_receipts'] ?? 0,
    totalRevenue: (map['total_revenue'] ?? 0).toDouble(),
    avgReceipt: (map['avg_receipt'] ?? 0).toDouble(),
  );
}

class Receipt {
  final int id;
  final int? shiftId;
  final double total;
  final String paymentType;
  final DateTime createdAt;

  Receipt({
    required this.id,
    this.shiftId,
    required this.total,
    this.paymentType = 'cash',
    required this.createdAt,
  });

  factory Receipt.fromMap(Map<String, dynamic> map) => Receipt(
    id: map['id'],
    shiftId: map['shift_id'],
    total: (map['total'] ?? 0).toDouble(),
    paymentType: map['payment_type'] ?? 'cash',
    createdAt: DateTime.parse(map['created_at']),
  );
}

class ReceiptItemDetail {
  final String productName;
  final double price;
  final double quantity;
  final double total;

  ReceiptItemDetail({
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
  });

  factory ReceiptItemDetail.fromMap(Map<String, dynamic> map) => ReceiptItemDetail(
    productName: map['product_name'] ?? '',
    price: (map['price'] ?? 0).toDouble(),
    quantity: (map['quantity'] ?? 0).toDouble(),
    total: (map['total'] ?? 0).toDouble(),
  );
}