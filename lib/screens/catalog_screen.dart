//lib/screens/catalog_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/database/database_helper.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _isLoading = false;

  final List<String> _units = ['шт', 'кг', 'л', 'г', 'мл', 'уп'];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).loadProducts();
    });
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
        title: const Text('Каталог товаров'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).loadProducts();
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear_catalog') {
                _showClearCatalogDialog(context);
              } else if (value == 'clear_all_db') {
                _showClearAllDbDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_catalog',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('🗑️ Удалить активные товары', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all_db',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('💣 Полная очистка БД', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: '🔍 Поиск по названию или штрих-коду',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          _searchProducts(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_categories.isNotEmpty)
                      DropdownButton<int>(
                        hint: const Text('Категория'),
                        value: _selectedCategoryId,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Все'),
                          ),
                          ..._categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                          _searchProducts(null);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Каталог пуст',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  Text(
                    'Добавьте товары через импорт или вручную',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.products.length,
            itemBuilder: (context, index) {
              final p = provider.products[index];
              final stockColor = p.stockQuantity <= p.minStock
                  ? Colors.red
                  : Colors.green;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: () => _showEditDialog(context, p),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Штрих-код: ${p.barcode}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              if (p.categoryName != null && p.categoryName!.isNotEmpty)
                                Text(
                                  'Категория: ${p.categoryName}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${p.price.toStringAsFixed(2)} ₽',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              'Остаток: ${p.stockQuantity.toStringAsFixed(0)} ${p.unit}',
                              style: TextStyle(
                                color: stockColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _showDeleteDialog(context, p),
                          tooltip: 'Удалить товар',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _searchProducts(String? query) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.loadProducts(
      search: query ?? _searchController.text,
      categoryId: _selectedCategoryId,
    );
  }

  // ============================================================
  //  ДИАЛОГ УДАЛЕНИЯ АКТИВНЫХ ТОВАРОВ
  // ============================================================

  void _showClearCatalogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Удалить активные товары?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Все активные товары будут удалены!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllProducts();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Удалить активные'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllProducts() async {
    try {
      setState(() => _isLoading = true);
      
      final products = await _db.getAllProducts();
      
      for (final product in products) {
        await _db.deleteProduct(product.id!);
      }
      
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.loadProducts();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Активные товары удалены!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ============================================================
  //  ДИАЛОГ ПОЛНОЙ ОЧИСТКИ БД
  // ============================================================

  void _showClearAllDbDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💣 Полная очистка БД?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.warning, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Будут удалены ВСЕ товары, категории, чеки и смены!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Это действие НЕЛЬЗЯ отменить!',
              style: TextStyle(fontSize: 14, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearDatabaseComplete();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('💣 Удалить ВСЁ!'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearDatabaseComplete() async {
    try {
      setState(() => _isLoading = true);
      
      await _db.clearAllData();
      
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.loadProducts();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💣 База данных полностью очищена!'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ============================================================
  //  ДИАЛОГ УДАЛЕНИЯ ОДНОГО ТОВАРА
  // ============================================================

  void _showDeleteDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить товар?'),
        content: Text(
          'Вы уверены, что хотите удалить "${product.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteProduct(product);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    try {
      await _db.deleteProduct(product.id!);
      
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.loadProducts();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ "${product.name}" удалён'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  //  ДИАЛОГ РЕДАКТИРОВАНИЯ ТОВАРА
  // ============================================================

  void _showEditDialog(BuildContext context, Product product) {
    final nameController = TextEditingController(text: product.name);
    final barcodeController = TextEditingController(text: product.barcode);
    final priceController = TextEditingController(text: product.price.toString());
    final stockController = TextEditingController(text: product.stockQuantity.toString());
    final minStockController = TextEditingController(text: product.minStock.toString());
    final descriptionController = TextEditingController(text: product.description);
    
    String selectedUnit = product.unit;
    int? selectedCategoryId = product.categoryId;
    bool isActive = product.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('✏️ Редактировать товар'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Штрих-код *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            decoration: const InputDecoration(
                              labelText: 'Цена *',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedUnit,
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
                              setDialogState(() {
                                selectedUnit = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: stockController,
                            decoration: const InputDecoration(
                              labelText: 'Остаток',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: minStockController,
                            decoration: const InputDecoration(
                              labelText: 'Мин. остаток',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_categories.isNotEmpty)
                      DropdownButtonFormField<int>(
                        value: selectedCategoryId,
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
                          setDialogState(() {
                            selectedCategoryId = value;
                          });
                        },
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Описание',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Активен:'),
                        const SizedBox(width: 8),
                        Switch(
                          value: isActive,
                          onChanged: (value) {
                            setDialogState(() {
                              isActive = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _updateProduct(
                    product,
                    nameController.text,
                    barcodeController.text,
                    priceController.text,
                    selectedUnit,
                    stockController.text,
                    minStockController.text,
                    selectedCategoryId,
                    descriptionController.text,
                    isActive,
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Сохранить'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateProduct(
    Product oldProduct,
    String name,
    String barcode,
    String priceStr,
    String unit,
    String stockStr,
    String minStockStr,
    int? categoryId,
    String description,
    bool isActive,
  ) async {
    try {
      if (name.isEmpty) {
        _showError('Введите название');
        return;
      }
      if (barcode.isEmpty || barcode.length < 4) {
        _showError('Введите корректный штрих-код');
        return;
      }
      
      final price = double.tryParse(priceStr.replaceAll(',', '.'));
      if (price == null || price <= 0) {
        _showError('Введите корректную цену');
        return;
      }
      
      final stock = double.tryParse(stockStr.replaceAll(',', '.')) ?? 0;
      final minStock = double.tryParse(minStockStr.replaceAll(',', '.')) ?? 0;

      if (barcode != oldProduct.barcode) {
        final existing = await _db.getProductByBarcode(barcode);
        if (existing != null) {
          _showError('Штрих-код "$barcode" уже используется');
          return;
        }
      }

      final updatedProduct = Product(
        id: oldProduct.id,
        barcode: barcode,
        name: name,
        description: description,
        price: price,
        unit: unit,
        categoryId: categoryId,
        stockQuantity: stock,
        minStock: minStock,
        isActive: isActive,
      );

      await _db.updateProduct(updatedProduct);
      
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.loadProducts();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ "${name}" обновлён!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Ошибка: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
