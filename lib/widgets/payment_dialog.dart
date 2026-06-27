//lib/widgets/payment_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class PaymentDialog extends StatefulWidget {
  const PaymentDialog({super.key});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final TextEditingController _paymentController = TextEditingController();
  String _changeText = '';
  bool _isProcessing = false;

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('💳 Оплата чека'),
      content: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final total = provider.cashRegister.totalWithDiscount;
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Сумма:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${total.toStringAsFixed(2)} ₽',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _paymentController,
                decoration: const InputDecoration(
                  labelText: 'Внесено наличных',
                  prefixIcon: Icon(Icons.money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
                onChanged: (value) {
                  _calculateChange(provider, total);
                },
              ),
              if (_changeText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _changeText.contains('Не хватает')
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _changeText.contains('Не хватает')
                            ? Colors.red.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _changeText.contains('Не хватает')
                              ? Icons.error_outline
                              : Icons.check_circle,
                          color: _changeText.contains('Не хватает')
                              ? Colors.red
                              : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _changeText,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _changeText.contains('Не хватает')
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        Consumer<AppProvider>(
          builder: (context, provider, child) {
            final total = provider.cashRegister.totalWithDiscount;
            final paidStr = _paymentController.text.trim().replaceAll(',', '.');
            final paid = double.tryParse(paidStr) ?? 0;
            final isValid = paid >= total && paid > 0;

            return FilledButton.icon(
              onPressed: _isProcessing || !isValid
                  ? null
                  : () async {
                      setState(() => _isProcessing = true);
                      final receiptId = await provider.payReceipt(
                        paid: paid,
                        paymentType: 'cash',
                      );
                      
                      if (mounted) {
                        setState(() => _isProcessing = false);
                        
                        if (receiptId != null) {
                          // Закрываем диалог только после успешной оплаты
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Чек №$receiptId оплачен!'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(provider.status),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.payment),
              label: const Text('Оплатить'),
              style: FilledButton.styleFrom(
                backgroundColor: isValid ? Colors.green : Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            );
          },
        ),
      ],
    );
  }

  void _calculateChange(AppProvider provider, double total) {
    final paidStr = _paymentController.text.trim().replaceAll(',', '.');
    final paid = double.tryParse(paidStr) ?? 0;
    
    setState(() {
      if (paid <= 0) {
        _changeText = '';
      } else if (paid < total) {
        _changeText = '⚠️ Не хватает: ${(total - paid).toStringAsFixed(2)} ₽';
      } else {
        _changeText = '✅ Сдача: ${(paid - total).toStringAsFixed(2)} ₽';
      }
    });
  }
}
