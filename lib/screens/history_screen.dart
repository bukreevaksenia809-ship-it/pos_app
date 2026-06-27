// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:pos_app/services/database/database_helper.dart';
import '../models/shift.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Receipt> _receipts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() => _isLoading = true);
    try {
      _receipts = await _db.getReceipts(limit: 50);
    } catch (e) {
      print('Error loading receipts: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История чеков'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReceipts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _receipts.isEmpty
              ? const Center(child: Text('Нет чеков'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _receipts.length,
                  itemBuilder: (context, index) {
                    final r = _receipts[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.receipt),
                        title: Text('Чек №${r.id}'),
                        subtitle: Text(
                          '${r.createdAt.day.toString().padLeft(2, '0')}.${r.createdAt.month.toString().padLeft(2, '0')}.${r.createdAt.year} ${r.createdAt.hour.toString().padLeft(2, '0')}:${r.createdAt.minute.toString().padLeft(2, '0')}',
                        ),
                        trailing: Text(
                          '${r.total.toStringAsFixed(2)} ₽',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        onTap: () => _showReceiptDetails(r.id),
                      ),
                    );
                  },
                ),
    );
  }

  void _showReceiptDetails(int receiptId) async {
    final items = await _db.getReceiptItems(receiptId);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Чек №$receiptId'),
          content: SizedBox(
            width: 400,
            height: 300,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item.productName),
                  subtitle: Text('${item.price.toStringAsFixed(2)} ₽ × ${item.quantity.toStringAsFixed(1)}'),
                  trailing: Text('${item.total.toStringAsFixed(2)} ₽'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }
}