//lib/widgets/product_search_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ProductSearchDialog extends StatefulWidget {
  final String query;

  const ProductSearchDialog({super.key, required this.query});

  @override
  State<ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<ProductSearchDialog> {
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = Provider.of<AppProvider>(context, listen: false)
        .loadProducts(search: widget.query);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Результаты поиска'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Consumer<AppProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.products.isEmpty) {
              return const Center(
                child: Text('Товары не найдены'),
              );
            }

            return ListView.builder(
              itemCount: provider.products.length,
              itemBuilder: (context, index) {
                final product = provider.products[index];
                return ListTile(
                  leading: const Icon(Icons.inventory_2, color: Colors.blue),
                  title: Text(product.name),
                  subtitle: Text(
                    '${product.barcode} | ${product.price.toStringAsFixed(2)} ₽/${product.unit}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    onPressed: () {
                      provider.addProductByBarcode(product.barcode).then((success) {
                        if (success) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(provider.status)),
                          );
                        }
                      });
                    },
                  ),
                );
              },
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
  }
}