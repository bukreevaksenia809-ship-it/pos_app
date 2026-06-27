import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  Future<bool> printReceipt({
    required List<ReceiptItem> items,
    required double total,
    required String paymentType,
    required double paid,
    required double change,
    String discountLabel = '',
    int? shiftId,
    int? receiptId,
    String? port,
  }) async {
    try {
      final scriptDir = Directory.current.path;
      String scriptPath;
      String pythonPath;
      
      if (Platform.isWindows) {
        scriptPath = '$scriptDir\\scripts\\print_receipt.py';
        pythonPath = 'python';
      } else {
        scriptPath = '$scriptDir/scripts/print_receipt.py';
        final venvPath = '$scriptDir/printer_env/bin/python3';
        pythonPath = await File(venvPath).exists() ? venvPath : 'python3';
      }
      
      if (!await File(scriptPath).exists()) {
        print('❌ Скрипт не найден: $scriptPath');
        return false;
      }

      final itemsData = items.map((item) => {
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'total': item.total,
      }).toList();

      final data = {
        'shop_name': 'ИП Букреева А.А. Магазин "МЕДВЕДЬ"',
        'shop_address': '397855, Воронежская область, г. Воронеж, ул. Херсонская, д. 21а',
        'shop_inn': '361913652004',
        'kkt_zn': '00109729168060pwd',
        'kkt_reg': '009663345065263',
        'fn': '7380440902561114',
        'footer': 'Ждем вас снова!',
        'receipt_id': receiptId ?? 0,
        'shift_id': shiftId ?? 0,
        'total': total,
        'paid': paid,
        'change': change,
        'payment_type': paymentType,
        'discount': discountLabel,
        'items': itemsData,
        'port': port,
      };

      final jsonData = jsonEncode(data);
      print('📤 Отправка данных в Python...');

      final result = await Process.run(
        pythonPath,
        [scriptPath, jsonData],
        runInShell: Platform.isWindows,
      );

      if (result.exitCode == 0) {
        try {
          final response = jsonDecode(result.stdout.toString());
          return response['success'] == true;
        } catch (e) {
          print('❌ Ошибка парсинга: $e');
          return false;
        }
      } else {
        print('❌ Ошибка: ${result.stderr}');
        return false;
      }

    } catch (e) {
      print('❌ Ошибка печати: $e');
      return false;
    }
  }

  Future<bool> printTest() async {
    final testItems = [
      ReceiptItem(productId: 1, name: 'Тестовый товар 1', price: 100.0, quantity: 2),
      ReceiptItem(productId: 2, name: 'Тестовый товар 2', price: 250.50, quantity: 1.5),
    ];

    return await printReceipt(
      items: testItems,
      total: 575.75,
      paymentType: 'Наличные',
      paid: 1000.0,
      change: 424.25,
      discountLabel: 'Тест 10%',
      receiptId: 999,
    );
  }
}
