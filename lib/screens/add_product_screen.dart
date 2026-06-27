//lib/screens/add_product_screen.dart
import 'package:flutter/material.dart';
import 'package:pos_app/models/category.dart';
import 'package:pos_app/models/product.dart';
import 'package:pos_app/services/database/database_helper.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _minStockController = TextEditingController();
  
  String _selectedUnit = 'шт';
  int? _selectedCategoryId;
  List<Category> _categories = [];
  String _message = '';
  Color _messageColor = Colors.red;

  final List<String> _units = ['шт', 'кг', 'л', 'г', 'мл', 'уп'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      _categories = await _db.getCategories();
      setState(() {});
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить товар'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: 'Штрих-код *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Цена (₽) *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Ед.',
                      border: OutlineInputBorder(),
                    ),
                    items: _units.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedUnit = value!);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Остаток',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _minStockController,
                    decoration: const InputDecoration(
                      labelText: 'Мин. остаток',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Категория',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Без категории'),
                ),
                ..._categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedCategoryId = value);
              },
            ),
            const SizedBox(height: 16),
            if (_message.isNotEmpty)
              Text(
                _message,
                style: TextStyle(color: _messageColor),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saveProduct,
              icon: const Icon(Icons.save),
              label: const Text('Сохранить'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    final barcode = _barcodeController.text.trim();
    final name = _nameController.text.trim();
    final priceStr = _priceController.text.trim().replaceAll(',', '.');
    final stockStr = _stockController.text.trim();
    final minStockStr = _minStockController.text.trim();

    if (barcode.length < 8) {
      _showMessage('Штрих-код: минимум 8 цифр', Colors.red);
      return;
    }
    if (name.isEmpty) {
      _showMessage('Введите название', Colors.red);
      return;
    }

    final price = double.tryParse(priceStr);
    if (price == null || price <= 0) {
      _showMessage('Неверная цена', Colors.red);
      return;
    }

    final stock = double.tryParse(stockStr) ?? 0;
    final minStock = double.tryParse(minStockStr) ?? 0;

    final existing = await _db.getProductByBarcode(barcode);
    if (existing != null) {
      _showMessage('Штрих-код $barcode уже есть: ${existing.name}', Colors.red);
      return;
    }

    try {
      final id = await _db.addProduct(
        Product(
          barcode: barcode,
          name: name,
          price: price,
          unit: _selectedUnit,
          categoryId: _selectedCategoryId,
          stockQuantity: stock,
          minStock: minStock,
        ),
      );

      if (id > 0) {
        _showMessage('✅ $name добавлен!', Colors.green);
        _barcodeController.clear();
        _nameController.clear();
        _priceController.clear();
        _stockController.text = '0';
        _minStockController.text = '0';
      } else {
        _showMessage('Ошибка при сохранении', Colors.red);
      }
    } catch (e) {
      _showMessage('Ошибка: $e', Colors.red);
    }
  }

  void _showMessage(String msg, Color color) {
    setState(() {
      _message = msg;
      _messageColor = color;
    });
  }
}