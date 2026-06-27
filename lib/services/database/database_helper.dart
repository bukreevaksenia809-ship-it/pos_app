//lib/services/database/database_helper.dart
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../models/shift.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Используем документы приложения вместо Documents папки пользователя
    final documentsDir = await getApplicationDocumentsDirectory();
    final path = join(documentsDir.path, 'pos.db');
    
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('🔄 Создание базы данных...');
    
    // --- Категории ---
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // --- Товары ---
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        price REAL NOT NULL DEFAULT 0,
        unit TEXT NOT NULL DEFAULT 'шт',
        category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
        stock_quantity REAL DEFAULT 0,
        min_stock REAL DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // --- Движения склада ---
    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
        movement_type TEXT NOT NULL,
        quantity REAL NOT NULL,
        comment TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // --- Смены ---
    await db.execute('''
      CREATE TABLE shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        opened_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        closed_at TIMESTAMP,
        opening_balance REAL DEFAULT 0,
        closing_balance REAL DEFAULT 0
      )
    ''');

    // --- Чеки ---
    await db.execute('''
      CREATE TABLE receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shift_id INTEGER REFERENCES shifts(id),
        total REAL NOT NULL,
        payment_type TEXT DEFAULT 'cash',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // --- Позиции чеков ---
    await db.execute('''
      CREATE TABLE receipt_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt_id INTEGER REFERENCES receipts(id) ON DELETE CASCADE,
        product_id INTEGER REFERENCES products(id) ON DELETE SET NULL,
        product_name TEXT,
        price REAL,
        quantity REAL,
        total REAL
      )
    ''');

    // --- Индексы ---
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_products_name ON products(name)');
    await db.execute('CREATE INDEX idx_products_category ON products(category_id)');
    await db.execute('CREATE INDEX idx_receipts_shift ON receipts(shift_id)');
    await db.execute('CREATE INDEX idx_receipts_date ON receipts(created_at)');

    await _seedTestData(db);
    print('✅ База данных создана');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Обновление базы данных с версии $oldVersion до $newVersion');
    
    if (oldVersion < 2) {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)');
    }
    
    if (oldVersion < 3) {
      // Проверяем существование таблиц
      final tables = await db.query('sqlite_master', where: 'type = "table"');
      print('📊 Существующие таблицы: ${tables.map((t) => t['name']).toList()}');
    }
  }

  Future<void> _seedTestData(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products')
    ) ?? 0;
    
    if (count > 0) return;

    print('📦 Добавление тестовых данных...');

    final catIds = <String, int>{};
    final categories = ['Хлебобулочные', 'Молочные', 'Бакалея', 'Напитки'];
    for (final cat in categories) {
      final id = await db.insert('categories', {'name': cat});
      catIds[cat] = id;
    }

    final products = [
      ('4601234567890', 'Хлеб белый', 'Хлеб пшеничный высший сорт', 35.50, 'шт', catIds['Хлебобулочные']!, 50, 10),
      ('4601234567891', 'Молоко 3.2%', 'Молоко пастеризованное 1л', 75.00, 'шт', catIds['Молочные']!, 100, 20),
      ('4601234567892', 'Масло сливочное', 'Масло сливочное 82.5% 180г', 120.00, 'шт', catIds['Молочные']!, 60, 15),
      ('4601234567893', 'Сыр Российский', 'Сыр полутвердый 1кг', 250.00, 'кг', catIds['Молочные']!, 25, 5),
      ('4601234567894', 'Сахар песок', 'Сахар белый свекловичный', 65.00, 'кг', catIds['Бакалея']!, 200, 30),
      ('4601234567895', 'Мука пшеничная', 'Мука высший сорт 1кг', 45.00, 'кг', catIds['Бакалея']!, 150, 20),
      ('4601234567896', 'Чай черный', 'Чай цейлонский 100 пак.', 180.00, 'шт', catIds['Бакалея']!, 40, 10),
      ('4601234567897', 'Кофе растворимый', 'Кофе сублимированный 100г', 320.00, 'шт', catIds['Напитки']!, 30, 5),
      ('4601234567898', 'Вода минеральная', 'Вода газированная 1.5л', 55.00, 'шт', catIds['Напитки']!, 120, 25),
      ('4601234567899', 'Сок яблочный', 'Сок прямого отжима 1л', 95.00, 'шт', catIds['Напитки']!, 80, 15),
    ];

    for (final p in products) {
      final productId = await db.insert('products', {
        'barcode': p.$1,
        'name': p.$2,
        'description': p.$3,
        'price': p.$4,
        'unit': p.$5,
        'category_id': p.$6,
        'stock_quantity': p.$7,
        'min_stock': p.$8,
      });
      
      await db.insert('stock_movements', {
        'product_id': productId,
        'movement_type': 'in',
        'quantity': p.$7,
        'comment': 'Начальный остаток',
      });
    }

    await db.insert('shifts', {
      'opened_at': DateTime.now().toIso8601String(),
      'opening_balance': 0,
    });
    
    print('✅ Тестовые данные добавлены');
  }

  // ============================================================
  //  ТОВАРЫ
  // ============================================================

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'barcode = ? AND is_active = 1',
      whereArgs: [barcode],
    );
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  Future<List<Product>> getAllProducts({
    String? search,
    int? categoryId,
    bool activeOnly = true,
    int? limit,
  }) async {
    final db = await database;
    String sql = '''
      SELECT p.*, c.name as category_name 
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE 1=1
    ''';
    final args = <Object?>[];

    if (search != null && search.isNotEmpty) {
      sql += ' AND (p.name LIKE ? OR p.barcode LIKE ?)';
      final s = '%$search%';
      args.addAll([s, s]);
    }
    if (categoryId != null) {
      sql += ' AND p.category_id = ?';
      args.add(categoryId);
    }
    if (activeOnly) {
      sql += ' AND p.is_active = 1';
    }
    sql += ' ORDER BY p.name';
    if (limit != null) {
      sql += ' LIMIT ?';
      args.add(limit);
    }

    final result = await db.rawQuery(sql, args);
    return result.map((e) => Product.fromMap(e)).toList();
  }

  Future<int> addProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.update(
      'products',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  //  КАТЕГОРИИ
  // ============================================================

  Future<List<Category>> getCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'name');
    return result.map((e) => Category.fromMap(e)).toList();
  }

  Future<int> addCategory(String name) async {
    final db = await database;
    return await db.insert('categories', {'name': name});
  }

  // ============================================================
  //  СМЕНЫ
  // ============================================================

  Future<Shift> getCurrentShift() async {
    final db = await database;
    
    var result = await db.query(
      'shifts',
      where: 'closed_at IS NULL',
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Shift.fromMap(result.first);
    }

    final now = DateTime.now().toIso8601String();
    final id = await db.insert('shifts', {
      'opened_at': now,
      'opening_balance': 0,
    });

    result = await db.query(
      'shifts',
      where: 'id = ?',
      whereArgs: [id],
    );
    return Shift.fromMap(result.first);
  }

  Future<void> closeShift(int shiftId) async {
    final db = await database;
    await db.update(
      'shifts',
      {'closed_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [shiftId],
    );
  }

  Future<ShiftStats> getShiftStats(int shiftId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_receipts,
        COALESCE(SUM(total), 0) as total_revenue,
        COALESCE(AVG(total), 0) as avg_receipt
      FROM receipts
      WHERE shift_id = ?
    ''', [shiftId]);
    
    return ShiftStats.fromMap(result.first);
  }

  Future<List<Shift>> getAllShifts({int limit = 50}) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT s.*, 
        COUNT(r.id) as receipt_count,
        COALESCE(SUM(r.total), 0) as total_revenue
      FROM shifts s
      LEFT JOIN receipts r ON r.shift_id = s.id
      GROUP BY s.id
      ORDER BY s.id DESC
      LIMIT ?
    ''', [limit]);
    
    return result.map((e) => Shift.fromMap(e)).toList();
  }

  // ============================================================
  //  ЧЕКИ
  // ============================================================

  Future<int> saveReceipt({
    required List<ReceiptItem> items,
    required double total,
    required String paymentType,
    int? shiftId,
  }) async {
    final db = await database;
    
    final receiptId = await db.insert('receipts', {
      'shift_id': shiftId,
      'total': total,
      'payment_type': paymentType,
      'created_at': DateTime.now().toIso8601String(),
    });

    for (final item in items) {
      await db.insert('receipt_items', {
        'receipt_id': receiptId,
        'product_id': item.productId,
        'product_name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'total': item.total,
      });

      await db.rawUpdate(
        'UPDATE products SET stock_quantity = stock_quantity - ? WHERE id = ?',
        [item.quantity, item.productId],
      );

      await db.insert('stock_movements', {
        'product_id': item.productId,
        'movement_type': 'out',
        'quantity': item.quantity,
        'comment': 'Продажа, чек №$receiptId',
      });
    }

    return receiptId;
  }

  Future<List<Receipt>> getReceipts({
    int limit = 50,
    int offset = 0,
    int? shiftId,
  }) async {
    final db = await database;
    
    String sql = '''
      SELECT id, shift_id, total, payment_type, created_at
      FROM receipts
    ''';
    final args = <Object?>[];

    if (shiftId != null) {
      sql += ' WHERE shift_id = ?';
      args.add(shiftId);
    }

    sql += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    args.addAll([limit, offset]);

    final result = await db.rawQuery(sql, args);
    return result.map((e) => Receipt.fromMap(e)).toList();
  }

  Future<List<ReceiptItemDetail>> getReceiptItems(int receiptId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT product_name, price, quantity, total
      FROM receipt_items
      WHERE receipt_id = ?
      ORDER BY id
    ''', [receiptId]);
    
    return result.map((e) => ReceiptItemDetail.fromMap(e)).toList();
  }

  Future<int> getReceiptCount({int? shiftId}) async {
    final db = await database;
    String sql = 'SELECT COUNT(*) FROM receipts';
    final args = <Object?>[];
    
    if (shiftId != null) {
      sql += ' WHERE shift_id = ?';
      args.add(shiftId);
    }

    final result = await db.rawQuery(sql, args);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ============================================================
  //  ПОЛНАЯ ОЧИСТКА БАЗЫ ДАННЫХ
  // ============================================================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('receipt_items');
    await db.delete('receipts');
    await db.delete('stock_movements');
    await db.delete('products');
    await db.delete('categories');
    await db.delete('shifts');
    print('✅ База данных полностью очищена');
    
    await db.insert('shifts', {
      'opened_at': DateTime.now().toIso8601String(),
      'opening_balance': 0,
    });
  }
}
