import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/shift.dart';
import '../services/cash_register.dart';
import '../services/database/database_helper.dart';
import '../services/shift_service.dart';
import '../services/google_sheets_service.dart';
import '../services/printer_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final ShiftService _shiftService = ShiftService();
  final CashRegister _cashRegister = CashRegister();
  final PrinterService _printer = PrinterService();

  String _status = 'Готов к работе';
  Color _statusColor = Colors.green;
  List<Product> _products = [];
  Shift? _currentShift;
  ShiftStats? _shiftStats;
  bool _isLoading = false;
  bool _isInitialized = false;

  Function(Product)? _onWeightProduct;

  void setOnWeightProduct(Function(Product) callback) {
    _onWeightProduct = callback;
    print('✅ Колбэк веса установлен');
  }

  CashRegister get cashRegister => _cashRegister;
  String get status => _status;
  Color get statusColor => _statusColor;
  List<Product> get products => _products;
  Shift? get currentShift => _currentShift;
  ShiftStats? get shiftStats => _shiftStats;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    print('🔄 AppProvider.init() вызван');
    if (_isInitialized) {
      print('ℹ️ AppProvider уже инициализирован');
      return;
    }
    _isLoading = true;

    try {
      print('🔄 Загрузка текущей смены...');
      await loadCurrentShift();
      print('✅ Текущая смена загружена');
      
      print('🔄 Загрузка товаров...');
      await loadProducts();
      print('✅ Товары загружены');
      
    } catch (e, stack) {
      print('❌ AppProvider.init ошибка: $e');
      print('📚 Стек: $stack');
      _status = 'Ошибка: $e';
      _statusColor = Colors.red;
    }

    _isInitialized = true;
    _isLoading = false;
    print('✅ AppProvider.init() завершён');
    notifyListeners();
  }

  Future<void> loadCurrentShift() async {
    try {
      _currentShift = await _shiftService.getCurrentShift();
      if (_currentShift != null) {
        _shiftStats = await _shiftService.getShiftStats(_currentShift!.id!);
      }
    } catch (e) {
      print('❌ loadCurrentShift: $e');
      rethrow;
    }
  }

  Future<void> loadProducts({String? search, int? categoryId}) async {
    try {
      print('🔄 loadProducts: search="$search"');
      _products = await _db.getAllProducts(
        search: search,
        categoryId: categoryId,
        activeOnly: true,
      );
      print('✅ Загружено ${_products.length} товаров');
    } catch (e) {
      print('❌ loadProducts: $e');
      rethrow;
    }
  }

  Future<bool> addProductByBarcode(String barcode) async {
    print('🔍 Поиск товара по штрих-коду: $barcode');
    try {
      final product = await _db.getProductByBarcode(barcode);
      if (product == null) {
        _status = 'Товар не найден: $barcode';
        _statusColor = Colors.red;
        notifyListeners();
        print('❌ Товар не найден');
        return false;
      }

      print('📦 Найден товар: ${product.name}, unit: ${product.unit}');

      final weightUnits = ['кг', 'г', 'л', 'мл', 'kg', 'g', 'l', 'ml'];
      if (weightUnits.contains(product.unit.toLowerCase())) {
        _status = '⚖️ Весовой товар: введите вес';
        _statusColor = Colors.orange;
        notifyListeners();
        print('⚖️ Весовой товар, вызываем диалог');
        
        if (_onWeightProduct != null) {
          print('✅ Колбэк есть, вызываем...');
          _onWeightProduct!(product);
        } else {
          print('❌ Колбэк не установлен!');
        }
        return true;
      }

      _cashRegister.addByBarcode(product);
      _status = '✅ ${product.name} добавлен';
      _statusColor = Colors.green;
      notifyListeners();
      return true;
    } catch (e) {
      _status = '❌ Ошибка: $e';
      _statusColor = Colors.red;
      notifyListeners();
      print('❌ Ошибка в addProductByBarcode: $e');
      return false;
    }
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    return await _db.getProductByBarcode(barcode);
  }

  void addWeightProduct(Product product, double weight) {
    print('➕ Добавляем весовой товар: ${product.name}, вес: $weight');
    _cashRegister.items.add(ReceiptItem(
      productId: product.id!,
      name: '${product.name} (${weight.toStringAsFixed(3)}) ${product.unit}',
      price: product.price,
      quantity: weight,
    ));
    _status = '✅ ${product.name} добавлен';
    _statusColor = Colors.green;
    notifyListeners();
  }

  Future<int?> payReceipt({
    required double paid,
    required String paymentType,
  }) async {
    if (_cashRegister.items.isEmpty) {
      _status = '⚠️ Чек пуст!';
      _statusColor = Colors.red;
      notifyListeners();
      return null;
    }

    final total = _cashRegister.totalWithDiscount;
    if (paid < total) {
      _status = '❌ Не хватает: ${(total - paid).toStringAsFixed(2)} ₽';
      _statusColor = Colors.red;
      notifyListeners();
      return null;
    }

    try {
      final shiftId = _currentShift?.id;
      final receiptId = await _db.saveReceipt(
        items: _cashRegister.items,
        total: total,
        paymentType: paymentType,
        shiftId: shiftId,
      );

      // Печать чека через Python
      try {
        print('🖨️ Начинаем печать чека №$receiptId...');
        final printed = await _printer.printReceipt(
          items: _cashRegister.items,
          total: total,
          paymentType: paymentType,
          paid: paid,
          change: paid - total,
          discountLabel: _cashRegister.receiptDiscount?.label ?? '',
          shiftId: shiftId,
          receiptId: receiptId,
        );
        if (printed) {
          print('✅ Чек №$receiptId напечатан');
        } else {
          print('⚠️ Чек сохранён в файл (ошибка печати)');
        }
      } catch (e) {
        print('❌ Ошибка печати чека: $e');
      }

      // Отправка в Google Sheets
      try {
        await GoogleSheetsService().sendReceipt(
          receiptId: receiptId,
          total: total,
          paymentType: paymentType,
          paid: paid,
          change: paid - total,
          items: _cashRegister.items,
          shiftId: shiftId,
          shiftOpened: _currentShift?.openedAt,
          shiftClosed: null,
        );
        print('✅ Чек №$receiptId отправлен в Google Sheets');
      } catch (e) {
        print('❌ Ошибка отправки в Google Sheets: $e');
      }

      _cashRegister.clear();
      await loadCurrentShift();
      _status = '✅ Чек №$receiptId закрыт';
      _statusColor = Colors.green;
      notifyListeners();
      return receiptId;
    } catch (e) {
      _status = '❌ Ошибка оплаты: $e';
      _statusColor = Colors.red;
      notifyListeners();
      return null;
    }
  }

  Future<void> openNewShift() async {
    try {
      if (_currentShift != null && _currentShift!.isOpen) {
        try {
          final stats = await _shiftService.getShiftStats(_currentShift!.id!);
          await GoogleSheetsService().closeShift(
            shiftId: _currentShift!.id!,
            closedAt: DateTime.now(),
            stats: stats,
          );
        } catch (e) {
          print('❌ Ошибка закрытия смены в Google Sheets: $e');
        }
      }

      _currentShift = await _shiftService.openNewShift();
      _shiftStats = await _shiftService.getShiftStats(_currentShift!.id!);
      _status = '✅ Новая смена открыта';
      _statusColor = Colors.green;
      notifyListeners();
    } catch (e) {
      _status = '❌ Ошибка: $e';
      _statusColor = Colors.red;
      notifyListeners();
    }
  }

  void clearStatus() {
    _status = 'Готов к работе';
    _statusColor = Colors.green;
    notifyListeners();
  }

  void clearReceipt() {
    _cashRegister.clear();
    _status = '🧹 Чек очищен';
    _statusColor = Colors.grey;
    notifyListeners();
  }

  void refreshUI() {
    notifyListeners();
  }
}
