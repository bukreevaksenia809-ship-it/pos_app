import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../models/product.dart';
import '../widgets/receipt_item_widget.dart';
import '../widgets/product_search_dialog.dart';
import '../widgets/payment_dialog.dart';
import '../screens/google_sheets_settings.dart';
import '../services/printer_service.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _scanBuffer = '';
  final PrinterService _printer = PrinterService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      if (!provider.isInitialized) {
        provider.init();
      }
      provider.setOnWeightProduct((product) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showWeightDialog(product);
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<AppProvider, ThemeProvider>(
        builder: (context, provider, themeProvider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Загрузка...'),
                ],
              ),
            );
          }

          final cashRegister = provider.cashRegister;
          
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildHeader(provider),
                      const SizedBox(height: 8),
                      _buildScanner(provider),
                      const SizedBox(height: 8),
                      _buildSearchBar(provider),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildReceiptList(cashRegister, provider),
                      ),
                      _buildTotal(provider),
                      _buildControls(provider),
                      _buildStatus(provider),
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 1,
                child: _buildSidebar(provider, themeProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Смена №${provider.currentShift?.id ?? '—'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ОТКРЫТА',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_scanner, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _scanBuffer.isEmpty ? 'Готов к сканированию' : _scanBuffer,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _scanBuffer.isEmpty ? Colors.grey : Colors.black,
              ),
            ),
          ),
          if (_scanBuffer.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () => setState(() => _scanBuffer = ''),
            ),
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.blue),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📷 Сканер камеры (в разработке)'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppProvider provider) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '🔍 Поиск по названию или штрих-коду',
              filled: true,
              fillColor: Theme.of(context).cardTheme.color,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _showProductSearch(context, value);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              final query = _searchController.text.trim();
              if (query.isNotEmpty) {
                _showProductSearch(context, query);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptList(dynamic cashRegister, AppProvider provider) {
    if (cashRegister.items.isEmpty) {
      return Card(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Чек пуст',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Отсканируйте товар или найдите вручную',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: cashRegister.items.length,
        itemBuilder: (context, index) {
          final item = cashRegister.items[index];
          return ReceiptItemWidget(
            item: item,
            onQuantityChanged: (delta) {
              cashRegister.changeQuantity(index, delta);
              provider.refreshUI();
            },
            onRemove: () {
              cashRegister.removeItem(index);
              provider.refreshUI();
            },
            onDiscount: () {
              _showItemDiscountDialog(context, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildTotal(AppProvider provider) {
    final cashRegister = provider.cashRegister;
    final total = cashRegister.totalWithDiscount;
    final discount = cashRegister.discountAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ИТОГО:',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${total.toStringAsFixed(2)} ₽',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          if (discount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.discount, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  'Скидка: -${discount.toStringAsFixed(2)} ₽',
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
            ),
          if (cashRegister.items.isNotEmpty)
            Text(
              'Товаров: ${cashRegister.items.length}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildControls(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: provider.clearReceipt,
              icon: const Icon(Icons.clear_all),
              label: const Text('Очистить'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () {
                if (provider.cashRegister.items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Чек пуст!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                _showPaymentDialog(context);
              },
              icon: const Icon(Icons.payment),
              label: const Text('Оплатить'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: provider.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: provider.statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            provider.status,
            style: TextStyle(
              color: provider.statusColor,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(AppProvider provider, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Касса Pro',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                _navButton(
                  icon: Icons.receipt_long,
                  label: 'Касса',
                  isActive: true,
                  onTap: () {},
                ),
                _navButton(
                  icon: Icons.inventory,
                  label: 'Каталог',
                  onTap: () {
                    Navigator.pushNamed(context, '/catalog');
                  },
                ),
                _navButton(
                  icon: Icons.add_box,
                  label: 'Добавить',
                  onTap: () {
                    Navigator.pushNamed(context, '/add_product');
                  },
                ),
                _navButton(
                  icon: Icons.history,
                  label: 'История',
                  onTap: () {
                    Navigator.pushNamed(context, '/history');
                  },
                ),
                _navButton(
                  icon: Icons.analytics,
                  label: 'Итоги',
                  onTap: () {
                    Navigator.pushNamed(context, '/summary');
                  },
                ),
                _navButton(
                  icon: Icons.download,
                  label: 'Импорт',
                  onTap: () {
                    Navigator.pushNamed(context, '/importer');
                  },
                ),
                const Divider(),
                _navButton(
                  icon: Icons.cloud_sync,
                  label: '📊 Google Sheets',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GoogleSheetsSettings(),
                      ),
                    );
                  },
                ),
                _navButton(
                  icon: Icons.print,
                  label: '🧪 Тест печати',
                  onTap: _testPrint,
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
              color: Colors.grey,
            ),
            title: Text(
              themeProvider.isDark ? 'Тёмная тема' : 'Светлая тема',
              style: const TextStyle(fontSize: 14),
            ),
            trailing: Switch(
              value: themeProvider.isDark,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              await provider.openNewShift();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.status),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Новая смена'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'v2.0.0 Pro',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? Colors.blue : Colors.grey,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? Colors.blue : null,
          ),
        ),
        tileColor: isActive ? Colors.blue.withOpacity(0.1) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
      ),
    );
  }

  // ============================================================
  // ДИАЛОГ ВВОДА ВЕСА
  // ============================================================

  void _showWeightDialog(Product product) {
    final TextEditingController controller = TextEditingController();
    double price = product.price;
    String unit = product.unit;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final weightText = controller.text;
            final weight = double.tryParse(weightText.replaceAll(',', '.'));
            final cost = weight != null && weight > 0 ? weight * price : 0;

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.scale, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${price.toStringAsFixed(2)} ₽ / $unit',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Введите вес ($unit)',
                        border: const OutlineInputBorder(),
                        suffixText: unit,
                        prefixIcon: const Icon(Icons.scale),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cost > 0 ? Colors.green.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Стоимость:',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            '${cost.toStringAsFixed(2)} ₽',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: cost > 0 ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildWeightKeyboard(setState, controller),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () {
                    final weight = double.tryParse(controller.text.replaceAll(',', '.'));
                    if (weight == null || weight <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚠️ Введите корректный вес'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    _addWeightProduct(product, weight);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('✅ Добавить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWeightKeyboard(StateSetter setState, TextEditingController controller) {
    final buttons = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['.', '0', '⌫'],
    ];

    return Column(
      children: buttons.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((label) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Material(
                  color: label == '⌫' ? Colors.red.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (label == '⌫') {
                        final text = controller.text;
                        if (text.isNotEmpty) {
                          controller.text = text.substring(0, text.length - 1);
                        }
                      } else {
                        controller.text += label;
                      }
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  void _addWeightProduct(Product product, double weight) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.addWeightProduct(product, weight);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${product.name} (${weight.toStringAsFixed(3)} ${product.unit})'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // ДИАЛОГИ
  // ============================================================

  void _showProductSearch(BuildContext context, String query) {
    showDialog(
      context: context,
      builder: (context) => ProductSearchDialog(query: query),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PaymentDialog(),
    );
  }

  void _showItemDiscountDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) {
        try {
          final item = Provider.of<AppProvider>(context, listen: false)
              .cashRegister
              .items[index];
          return AlertDialog(
            title: Text('Скидка: ${item.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Цена: ${item.price.toStringAsFixed(2)} ₽ × ${item.quantity.toStringAsFixed(1)} = ${item.total.toStringAsFixed(2)} ₽'),
                const SizedBox(height: 16),
                const Text('Скидка (в разработке)'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть'),
              ),
            ],
          );
        } catch (e) {
          return AlertDialog(
            title: const Text('Ошибка'),
            content: Text('Не удалось открыть скидку: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть'),
              ),
            ],
          );
        }
      },
    );
  }

  // ============================================================
  // ТЕСТ ПЕЧАТИ
  // ============================================================

  Future<void> _testPrint() async {
    final result = await _printer.printTest();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result ? '✅ Чек напечатан!' : '❌ Ошибка печати'),
        backgroundColor: result ? Colors.green : Colors.red,
      ),
    );
  }
}
