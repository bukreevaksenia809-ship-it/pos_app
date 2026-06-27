//lib/screens/importer_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../providers/app_provider.dart';
import '../services/database/database_helper.dart';

class ImporterScreen extends StatefulWidget {
  const ImporterScreen({super.key});

  @override
  State<ImporterScreen> createState() => _ImporterScreenState();
}

class _ImporterScreenState extends State<ImporterScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  
  List<Map<String, String>> _previewData = [];
  List<String> _headers = [];
  Map<int, String> _columnFields = {};
  Map<int, String> _columnUnits = {};
  String _status = '';
  Color _statusColor = Colors.green;
  bool _isLoading = false;
  String _fileName = '';
  bool _isDragging = false;
  int _totalRows = 0;
  int _totalColumns = 0;
  String _selectedDelimiter = ';';

  final Map<String, String> _fieldMap = {
    'name': 'Название',
    'barcode': 'Штрих-код',
    'price': 'Цена',
    'unit': 'Ед. изм.',
    'category': 'Категория',
    'stock': 'Остаток',
    'min_stock': 'Мин. остаток',
    'description': 'Описание',
  };

  final List<String> _units = ['шт', 'кг', 'л', 'г', 'мл', 'уп'];
  final List<String> _delimiters = [';', '\t', ','];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Импорт товаров'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_previewData.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: _isLoading ? null : _importData,
              tooltip: 'Импортировать',
            ),
          if (_previewData.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearAll,
              tooltip: 'Очистить',
            ),
        ],
      ),
      body: DropTarget(
        onDragDone: _onDragDone,
        onDragEntered: (details) => setState(() => _isDragging = true),
        onDragExited: (details) => setState(() => _isDragging = false),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _previewData.isEmpty
                  ? _buildDropZone()
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_fileName.isNotEmpty)
                      Text(
                        '📄 $_fileName',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _status,
                      style: TextStyle(color: _statusColor),
                    ),
                    if (_totalRows > 0 && _totalColumns > 0)
                      Text(
                        '📊 $_totalRows строк × $_totalColumns колонок',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              if (_previewData.isEmpty)
                FilledButton.icon(
                  onPressed: _isLoading ? null : _pickFile,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.folder_open),
                  label: const Text('Выбрать файл'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropZone() {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(
          color: _isDragging ? Colors.blue : Colors.grey.shade400,
          width: _isDragging ? 3 : 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(16),
        color: _isDragging 
            ? Colors.blue.shade50 
            : Colors.grey.shade50,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isDragging ? Icons.file_download : Icons.upload_file,
              size: 80,
              color: _isDragging ? Colors.blue : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _isDragging 
                  ? '📂 Отпустите файл для загрузки' 
                  : 'Перетащите файл сюда',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: _isDragging ? Colors.blue : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Поддерживаются: CSV, TSV, Excel (.xlsx), JSON',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'или',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Выбрать файл'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Сопоставьте колонки с полями товара.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Настройка колонок:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ..._headers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final header = entry.value;
                  return _buildColumnMapper(index, header);
                }),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                const Text(
                  'Предпросмотр (первые 20 строк):',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPreviewTable(),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _previewData.isEmpty || _isLoading
                        ? null
                        : _importData,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload),
                    label: Text(
                      '🚀 Импортировать ${_previewData.length} товаров',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColumnMapper(int index, String header) {
    final currentField = _columnFields[index] ?? '';
    final currentUnit = _columnUnits[index] ?? 'шт';
    final isUnitField = currentField == 'unit';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(
              width: 150,
              child: Text(
                header,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: currentField.isNotEmpty ? currentField : null,
                decoration: const InputDecoration(
                  labelText: 'Поле',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('— Не использовать —'),
                  ),
                  ..._fieldMap.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    if (value != null && value.isNotEmpty) {
                      _columnFields[index] = value;
                    } else {
                      _columnFields.remove(index);
                    }
                  });
                },
              ),
            ),
            if (isUnitField) const SizedBox(width: 8),
            if (isUnitField)
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<String>(
                  value: currentUnit,
                  decoration: const InputDecoration(
                    labelText: 'Ед.',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  items: _units.map((unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Text(unit),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      if (value != null) {
                        _columnUnits[index] = value;
                      }
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTable() {
    if (_previewData.isEmpty) {
      return const Center(child: Text('Нет данных'));
    }

    final headers = _headers.where((h) {
      final idx = _headers.indexOf(h);
      return _columnFields.containsKey(idx) && _columnFields[idx]!.isNotEmpty;
    }).toList();

    if (headers.isEmpty) {
      return const Center(
        child: Text('Выберите хотя бы одну колонку'),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 12,
          columns: [
            const DataColumn(
              label: Text('№', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...headers.map((h) => DataColumn(
              label: Text(
                _fieldMap[_columnFields[_headers.indexOf(h)]] ?? h,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )),
          ],
          rows: _previewData.take(20).map((row) {
            return DataRow(
              cells: [
                DataCell(Text('${_previewData.indexOf(row) + 1}')),
                ...headers.map((h) {
                  final idx = _headers.indexOf(h);
                  final value = row[h] ?? '';
                  return DataCell(Text(value));
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _onDragDone(DropDoneDetails details) async {
    if (details.files.isEmpty) return;
    
    final file = details.files.first;
    final bytes = await file.readAsBytes();
    _fileName = file.name;
    
    await _processFile(bytes, file.name);
  }

  Future<void> _pickFile() async {
    try {
      _setStatus('🔄 Выбор файла...', Colors.blue);
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'tsv', 'xlsx', 'xls', 'json', 'txt'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        _setStatus('Файл не выбран', Colors.orange);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      _fileName = file.name;

      if (bytes == null) {
        _setStatus('❌ Не удалось прочитать файл', Colors.red);
        return;
      }

      await _processFile(bytes, file.name);
      
    } catch (e) {
      _setStatus('❌ Ошибка: $e', Colors.red);
      print('Ошибка выбора файла: $e');
    }
  }

  Future<void> _processFile(List<int> bytes, String fileName) async {
    setState(() {
      _isLoading = true;
      _previewData = [];
      _headers = [];
      _columnFields = {};
      _columnUnits = {};
      _totalRows = 0;
      _totalColumns = 0;
    });

    final ext = path.extension(fileName).toLowerCase();
    bool success = false;

    try {
      if (ext == '.json') {
        success = await _parseJson(bytes);
      } else if (ext == '.xlsx' || ext == '.xls') {
        success = await _parseExcel(bytes);
      } else {
        success = await _parseCsv(bytes);
      }

      _totalRows = _previewData.length;
      _totalColumns = _headers.length;

      if (success && _previewData.isNotEmpty) {
        _setStatus('✅ Загружено $_totalRows строк', Colors.green);
        _autoMapColumns();
      } else if (_previewData.isEmpty) {
        _setStatus('❌ Не найдено данных в файле', Colors.red);
      } else {
        _setStatus('❌ Ошибка парсинга файла', Colors.red);
      }
    } catch (e) {
      _setStatus('❌ Ошибка: $e', Colors.red);
      print('Ошибка обработки файла: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<bool> _parseExcel(List<int> bytes) async {
    try {
      print('📊 Парсим Excel...');
      
      final excelFile = excel.Excel.decodeBytes(bytes);
      if (excelFile == null || excelFile.sheets.isEmpty) {
        return false;
      }
      
      final sheet = excelFile.sheets.values.first;
      if (sheet.rows.isEmpty) {
        return false;
      }

      final headerRow = sheet.rows.first;
      _headers = headerRow
          .where((cell) => cell?.value != null)
          .map((cell) => cell!.value.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
      
      if (_headers.isEmpty) {
        return false;
      }
      
      print('📝 Заголовки (${_headers.length}): $_headers');

      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.every((cell) => cell?.value == null || cell!.value.toString().trim().isEmpty)) continue;
        
        final rowData = <String, String>{};
        for (var j = 0; j < _headers.length && j < row.length; j++) {
          final cell = row[j];
          rowData[_headers[j]] = cell?.value?.toString().trim() ?? '';
        }
        _previewData.add(rowData);
      }

      print('✅ Парсинг Excel завершён: ${_previewData.length} строк');
      return _previewData.isNotEmpty;
    } catch (e) {
      print('❌ Excel parse error: $e');
      return false;
    }
  }

  Future<bool> _parseCsv(List<int> bytes) async {
    try {
      print('📊 Начинаем парсинг CSV файла...');
      
      String content = utf8.decode(bytes, allowMalformed: true);
      
      if (content.startsWith('\uFEFF')) {
        content = content.substring(1);
      }

      String delimiter = _selectedDelimiter;
      print('✅ Используем разделитель: "${delimiter == '\t' ? 'TAB' : delimiter}"');

      final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        print('❌ Нет строк в файле');
        return false;
      }

      _headers = lines.first.split(delimiter).map((s) => s.trim()).toList();
      
      while (_headers.isNotEmpty && _headers.last.isEmpty) {
        _headers.removeLast();
      }

      print('📝 Заголовков: ${_headers.length}');

      for (var i = 1; i < lines.length; i++) {
        final values = lines[i].split(delimiter).map((s) => s.trim()).toList();
        if (values.isEmpty || values.every((v) => v.isEmpty)) continue;
        
        final row = <String, String>{};
        for (var j = 0; j < _headers.length && j < values.length; j++) {
          row[_headers[j]] = values[j];
        }
        _previewData.add(row);
      }

      print('✅ Парсинг CSV завершён: ${_previewData.length} строк');
      return _previewData.isNotEmpty;
    } catch (e) {
      print('CSV parse error: $e');
      return false;
    }
  }

  Future<bool> _parseJson(List<int> bytes) async {
    try {
      final String content = utf8.decode(bytes);
      final dynamic data = json.decode(content);
      
      List<Map<String, dynamic>> items = [];
      
      if (data is List) {
        items = data.whereType<Map<String, dynamic>>().toList();
      } else if (data is Map && data.containsKey('items')) {
        final list = data['items'] as List;
        items = list.whereType<Map<String, dynamic>>().toList();
      } else if (data is Map) {
        items = [Map<String, dynamic>.from(data)];
      }

      if (items.isEmpty) return false;

      final keys = <String>{};
      for (final item in items) {
        keys.addAll(item.keys);
      }
      _headers = keys.toList();

      for (final item in items) {
        final row = <String, String>{};
        for (final key in _headers) {
          row[key] = item[key]?.toString() ?? '';
        }
        _previewData.add(row);
      }

      return true;
    } catch (e) {
      print('JSON parse error: $e');
      return false;
    }
  }

  void _autoMapColumns() {
    final fieldKeywords = {
      'name': ['название', 'имя', 'наименование', 'товар', 'продукт', 'name', 'title', 'product'],
      'barcode': ['штрих', 'бар', 'barcode', 'код', 'артикул', 'sku', 'code', 'ean', 'upc'],
      'price': ['цена', 'price', 'cost', 'сумма', 'amount', 'стоимость'],
      'unit': ['ед', 'unit', 'uom', 'измер', 'measure', 'единицы'],
      'category': ['категория', 'кат', 'category', 'cat', 'группа', 'group'],
      'stock': ['остаток', 'stock', 'количество', 'quantity', 'qty', 'кол'],
      'min_stock': ['мин', 'min', 'minimum', 'порог', 'threshold'],
      'description': ['описание', 'description', 'desc', 'примечание', 'comment', 'note'],
    };

    for (var i = 0; i < _headers.length; i++) {
      final header = _headers[i].toLowerCase();
      String? bestField;
      int bestScore = 0;

      for (final entry in fieldKeywords.entries) {
        final field = entry.key;
        final keywords = entry.value;
        
        for (final keyword in keywords) {
          if (header.contains(keyword)) {
            final score = keyword.length;
            if (score > bestScore) {
              bestScore = score;
              bestField = field;
            }
          }
        }
      }

      if (bestField != null && bestScore > 1) {
        _columnFields[i] = bestField;
        if (bestField == 'unit') {
          _columnUnits[i] = 'шт';
        }
      }
    }

    final hasName = _columnFields.containsValue('name');
    final hasBarcode = _columnFields.containsValue('barcode');
    final hasPrice = _columnFields.containsValue('price');

    if (!hasName) {
      _setStatus('⚠️ Не найдена колонка "Название"', Colors.orange);
    } else if (!hasBarcode) {
      _setStatus('⚠️ Не найдена колонка "Штрих-код"', Colors.orange);
    } else if (!hasPrice) {
      _setStatus('⚠️ Не найдена колонка "Цена"', Colors.orange);
    } else {
      _setStatus('✅ Автоматическое сопоставление выполнено', Colors.green);
    }

    setState(() {});
  }

  List<String> _parseBarcodes(String value) {
    if (value.isEmpty) return [];
    
    final separators = [',', ';', '/', r'\s+'];
    String? usedSeparator;
    
    for (final sep in separators) {
      if (value.contains(sep)) {
        usedSeparator = sep;
        break;
      }
    }
    
    if (usedSeparator != null) {
      return value.split(RegExp(usedSeparator))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    
    return [value.trim()];
  }

  String _detectUnit(String value) {
    final lower = value.toLowerCase().trim();
    
    if (lower == 'шт' || lower == 'штука') return 'шт';
    if (lower == 'кг' || lower == 'килограмм') return 'кг';
    if (lower == 'л' || lower == 'литр') return 'л';
    if (lower == 'г' || lower == 'грамм') return 'г';
    if (lower == 'мл' || lower == 'миллилитр') return 'мл';
    if (lower == 'уп' || lower == 'упаковка') return 'уп';
    
    if (lower.contains('кг')) return 'кг';
    if (lower.contains('литр') || lower.contains('л.')) return 'л';
    if (lower.contains('грамм')) return 'г';
    if (lower.contains('мл')) return 'мл';
    
    return 'шт';
  }

  Future<void> _importData() async {
    final hasName = _columnFields.containsValue('name');
    final hasBarcode = _columnFields.containsValue('barcode');
    final hasPrice = _columnFields.containsValue('price');

    if (!hasName) {
      _setStatus('❌ Укажите колонку "Название"', Colors.red);
      return;
    }
    if (!hasBarcode) {
      _setStatus('❌ Укажите колонку "Штрих-код"', Colors.red);
      return;
    }
    if (!hasPrice) {
      _setStatus('❌ Укажите колонку "Цена"', Colors.red);
      return;
    }

    final fieldMap = <int, String>{};
    final unitMap = <int, String>{};
    for (final entry in _columnFields.entries) {
      fieldMap[entry.key] = entry.value;
      if (entry.value == 'unit' && _columnUnits.containsKey(entry.key)) {
        unitMap[entry.key] = _columnUnits[entry.key]!;
      }
    }

    setState(() => _isLoading = true);
    _setStatus('🔄 Импорт...', Colors.blue);

    try {
      int imported = 0;
      int skipped = 0;
      int errors = 0;

      final existingProducts = await _db.getAllProducts();
      final existingBarcodes = existingProducts.map((p) => p.barcode).toSet();
      print('📊 Существующих товаров: ${existingProducts.length}');

      final categories = await _db.getCategories();
      final categoryMap = <String, int>{};
      for (final cat in categories) {
        categoryMap[cat.name] = cat.id;
      }

      for (final row in _previewData) {
        try {
          String? name;
          String? barcodeRaw;
          double? price;
          String unit = 'шт';
          String? categoryName;
          double stock = 0;
          double minStock = 0;
          String description = '';

          for (final entry in fieldMap.entries) {
            final colIndex = entry.key;
            final field = entry.value;
            final value = row[_headers[colIndex]]?.trim() ?? '';

            switch (field) {
              case 'name':
                name = value;
                break;
              case 'barcode':
                barcodeRaw = value;
                break;
              case 'price':
                price = double.tryParse(
                  value.replaceAll(' ', '')
                       .replaceAll(',', '.')
                       .replaceAll(RegExp(r'[^\d.]'), '')
                ) ?? 0;
                break;
              case 'unit':
                unit = _detectUnit(value);
                if (unitMap.containsKey(colIndex) && unitMap[colIndex] != 'шт') {
                  unit = unitMap[colIndex]!;
                }
                break;
              case 'category':
                categoryName = value;
                break;
              case 'stock':
                stock = double.tryParse(
                  value.replaceAll(' ', '').replaceAll(',', '.')
                ) ?? 0;
                break;
              case 'min_stock':
                minStock = double.tryParse(
                  value.replaceAll(' ', '').replaceAll(',', '.')
                ) ?? 0;
                break;
              case 'description':
                description = value;
                break;
            }
          }

          if (name == null || name.isEmpty) { skipped++; continue; }
          if (barcodeRaw == null || barcodeRaw.isEmpty) { skipped++; continue; }
          if (price == null || price <= 0) { skipped++; continue; }

          final barcodes = _parseBarcodes(barcodeRaw);
          if (barcodes.isEmpty) { skipped++; continue; }

          final mainBarcode = barcodes.first;
          
          if (existingBarcodes.contains(mainBarcode)) {
            print('⚠️ Пропускаем дубликат: $mainBarcode');
            skipped++;
            continue;
          }

          int? categoryId;
          if (categoryName != null && categoryName.isNotEmpty) {
            if (categoryMap.containsKey(categoryName)) {
              categoryId = categoryMap[categoryName];
            } else {
              try {
                final newCatId = await _db.addCategory(categoryName);
                categoryId = newCatId;
                categoryMap[categoryName] = newCatId;
              } catch (e) {
                print('Ошибка создания категории $categoryName: $e');
              }
            }
          }

          final product = Product(
            barcode: mainBarcode,
            name: name,
            description: description,
            price: price,
            unit: unit,
            categoryId: categoryId,
            stockQuantity: stock,
            minStock: minStock,
            isActive: true,
          );

          await _db.addProduct(product);
          imported++;
          existingBarcodes.add(mainBarcode);

        } catch (e) {
          errors++;
          print('Ошибка импорта строки: $e');
        }
      }

      String message = '✅ Импортировано: $imported';
      if (skipped > 0) message += ' | Пропущено (дубликаты): $skipped';
      if (errors > 0) message += ' | Ошибок: $errors';
      
      _setStatus(message, imported > 0 ? Colors.green : Colors.orange);

      if (imported > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Импортировано $imported товаров'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.loadProducts();
        
        setState(() {
          _previewData = [];
          _headers = [];
          _columnFields = {};
          _columnUnits = {};
          _fileName = '';
          _totalRows = 0;
          _totalColumns = 0;
        });
      }

    } catch (e) {
      _setStatus('❌ Ошибка импорта: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearAll() {
    setState(() {
      _previewData = [];
      _headers = [];
      _columnFields = {};
      _columnUnits = {};
      _fileName = '';
      _totalRows = 0;
      _totalColumns = 0;
      _status = '';
    });
  }

  void _setStatus(String msg, Color color) {
    setState(() {
      _status = msg;
      _statusColor = color;
    });
  }
}
