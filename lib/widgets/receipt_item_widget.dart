// lib/widgets/receipt_item_widget.dart

import 'package:flutter/material.dart';
import '../models/product.dart';

class ReceiptItemWidget extends StatelessWidget {
  final ReceiptItem item;
  final Function(double) onQuantityChanged;
  final VoidCallback onRemove;
  final VoidCallback onDiscount;

  const ReceiptItemWidget({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onDiscount,
  });

  @override
  Widget build(BuildContext context) {
    final step = item.quantity == item.quantity.roundToDouble() ? 1.0 : 0.1;
    final qtyText = item.quantity == item.quantity.roundToDouble()
        ? item.quantity.round().toString()
        : item.quantity.toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${item.price.toStringAsFixed(2)} ₽/ед.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.discount, size: 18, color: Colors.orange),
              onPressed: onDiscount,
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      size: 18, color: Colors.red),
                  onPressed: () => onQuantityChanged(-step),
                ),
                Text(
                  qtyText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      size: 18, color: Colors.green),
                  onPressed: () => onQuantityChanged(step),
                ),
              ],
            ),
            Text(
              '${item.total.toStringAsFixed(2)} ₽',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.red),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}