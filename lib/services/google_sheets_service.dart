//lib/services/google_sheets_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart' as auth;
import '../models/product.dart';
import '../models/shift.dart';

class GoogleSheetsService {
  static final GoogleSheetsService _instance = GoogleSheetsService._internal();
  factory GoogleSheetsService() => _instance;
  GoogleSheetsService._internal();

  String _spreadsheetId = '';
  auth.AuthClient? _client;
  sheets.SheetsApi? _sheetsApi;
  bool _isInitialized = false;

  final Map<String, String> _sheets = {
    'checks': 'Чеки',
    'items': 'Товары',
    'reports': 'Отчеты',
    'shifts': 'Смены',
  };

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Загружаем сохранённый ID таблицы
      final prefs = await SharedPreferences.getInstance();
      _spreadsheetId = prefs.getString('google_spreadsheet_id') ?? '';
      
      if (_spreadsheetId.isEmpty) {
        print('⚠️ ID таблицы не задан');
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final keyPath = '${dir.path}/google_key.json';
      
      final keyFile = File(keyPath);
      if (!await keyFile.exists()) {
        print('⚠️ Файл google_key.json не найден');
        return;
      }

      final credentials = json.decode(await keyFile.readAsString());
      
      final scopes = ['https://www.googleapis.com/auth/spreadsheets'];
      _client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(credentials),
        scopes,
      );
      
      _sheetsApi = sheets.SheetsApi(_client!);
      _isInitialized = true;
      print('✅ Google Sheets подключен');
      
      await _setupSheets();
    } catch (e) {
      print('❌ Ошибка подключения Google Sheets: $e');
    }
  }

  Future<void> _setupSheets() async {
    try {
      final spreadsheet = await _sheetsApi!.spreadsheets.get(_spreadsheetId);
      final existingSheets = spreadsheet.sheets?.map((s) => s.properties?.title ?? '').toList() ?? [];
      
      for (final sheetName in _sheets.values) {
        if (!existingSheets.contains(sheetName)) {
          await _sheetsApi!.spreadsheets.batchUpdate(
            sheets.BatchUpdateSpreadsheetRequest(
              requests: [
                sheets.Request(
                  addSheet: sheets.AddSheetRequest(
                    properties: sheets.SheetProperties(
                      title: sheetName,
                    ),
                  ),
                ),
              ],
            ),
            _spreadsheetId,
          );
          print('✅ Создан лист: $sheetName');
        }
      }
    } catch (e) {
      print('⚠️ Ошибка настройки листов: $e');
    }
  }

  Future<void> sendReceipt({
    required int receiptId,
    required double total,
    required String paymentType,
    required double paid,
    required double change,
    required List<ReceiptItem> items,
    int? shiftId,
    DateTime? shiftOpened,
    DateTime? shiftClosed,
  }) async {
    if (!_isInitialized || _sheetsApi == null || _spreadsheetId.isEmpty) {
      print('⚠️ Google Sheets не инициализирован');
      return;
    }

    try {
      final now = DateTime.now();
      final dateStr = '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      await _addShiftHeader(shiftId, shiftOpened, shiftClosed);
      
      final itemsText = items.map((item) => 
        '${item.name} x${item.quantity.toStringAsFixed(1)}'
      ).join(' | ');
      
      final checkRow = [
        receiptId.toString(),
        dateStr,
        shiftId?.toString() ?? '-',
        itemsText,
        total.toStringAsFixed(2),
        paid.toStringAsFixed(2),
        change.toStringAsFixed(2),
      ];
      
      await _appendRow(_sheets['checks']!, checkRow);
      
      for (final item in items) {
        final itemRow = [
          receiptId.toString(),
          item.name,
          item.price.toStringAsFixed(2),
          item.quantity.toStringAsFixed(1),
          _detectUnit(item.name),
          item.total.toStringAsFixed(2),
        ];
        await _appendRow(_sheets['items']!, itemRow);
      }
      
      await _updateReport(shiftId, total);
      
      print('✅ Чек №$receiptId отправлен в Google Таблицы');
    } catch (e) {
      print('❌ Ошибка отправки чека: $e');
    }
  }

  Future<void> closeShift({
    required int shiftId,
    required DateTime closedAt,
    required ShiftStats stats,
  }) async {
    if (!_isInitialized || _sheetsApi == null) return;

    try {
      final closedStr = '${closedAt.day.toString().padLeft(2, '0')}.${closedAt.month.toString().padLeft(2, '0')}.${closedAt.year} ${closedAt.hour.toString().padLeft(2, '0')}:${closedAt.minute.toString().padLeft(2, '0')}';
      final headerText = '🔴 СМЕНА №$shiftId | Закрыта: $closedStr | Чеков: ${stats.totalReceipts} | Выручка: ${stats.totalRevenue.toStringAsFixed(2)} ₽';
      
      await _updateShiftHeader(_sheets['checks']!, shiftId, headerText);
      await _updateShiftHeader(_sheets['items']!, shiftId, headerText);
      
      print('📊 Смена №$shiftId закрыта в Google Таблицах');
    } catch (e) {
      print('❌ Ошибка закрытия смены: $e');
    }
  }

  String _detectUnit(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('кг')) return 'кг';
    if (lower.contains('л')) return 'л';
    if (lower.contains('г')) return 'г';
    if (lower.contains('мл')) return 'мл';
    if (lower.contains('шт')) return 'шт';
    return 'шт';
  }

  Future<void> _appendRow(String sheetName, List<String> row) async {
    try {
      final valueRange = sheets.ValueRange(
        values: [row],
      );
      await _sheetsApi!.spreadsheets.values.append(
        valueRange,
        _spreadsheetId,
        sheetName,
        valueInputOption: 'USER_ENTERED',
      );
    } catch (e) {
      print('⚠️ Ошибка добавления строки в $sheetName: $e');
    }
  }

  Future<void> _addShiftHeader(int? shiftId, DateTime? opened, DateTime? closed) async {
    if (shiftId == null) return;
    
    try {
      final response = await _sheetsApi!.spreadsheets.values.get(
        _spreadsheetId,
        _sheets['checks']!,
      );
      
      final values = response.values ?? [];
      for (final row in values) {
        if (row.isNotEmpty && row[0] != null && row[0].toString().contains('СМЕНА №$shiftId')) {
          return;
        }
      }
      
      final openedStr = opened != null 
          ? '${opened.day.toString().padLeft(2, '0')}.${opened.month.toString().padLeft(2, '0')}.${opened.year} ${opened.hour.toString().padLeft(2, '0')}:${opened.minute.toString().padLeft(2, '0')}'
          : '—';
      final closedStr = closed != null
          ? '${closed.day.toString().padLeft(2, '0')}.${closed.month.toString().padLeft(2, '0')}.${closed.year} ${closed.hour.toString().padLeft(2, '0')}:${closed.minute.toString().padLeft(2, '0')}'
          : 'Открыта';
      
      await _appendRow(_sheets['checks']!, ['']);
      await _appendRow(_sheets['checks']!, [
        '🟢 СМЕНА №$shiftId | Открыта: $openedStr | Закрыта: $closedStr'
      ]);
      await _appendRow(_sheets['checks']!, [
        '№ чека', 'Дата', 'Смена', 'Товары', 'Сумма', 'Оплата', 'Сдача'
      ]);
      
      await _appendRow(_sheets['items']!, ['']);
      await _appendRow(_sheets['items']!, [
        '🟢 СМЕНА №$shiftId | Открыта: $openedStr | Закрыта: $closedStr'
      ]);
      await _appendRow(_sheets['items']!, [
        '№ чека', 'Товар', 'Цена', 'Кол-во', 'Ед.', 'Сумма'
      ]);
      
    } catch (e) {
      print('⚠️ Ошибка добавления заголовка смены: $e');
    }
  }

  Future<void> _updateShiftHeader(String sheetName, int shiftId, String headerText) async {
    try {
      final response = await _sheetsApi!.spreadsheets.values.get(
        _spreadsheetId,
        sheetName,
      );
      
      final values = response.values ?? [];
      for (int i = 0; i < values.length; i++) {
        final row = values[i];
        if (row.isNotEmpty && row[0] != null && row[0].toString().contains('СМЕНА №$shiftId')) {
          final updateRange = '$sheetName!A${i + 1}';
          final valueRange = sheets.ValueRange(
            values: [[headerText]],
          );
          await _sheetsApi!.spreadsheets.values.update(
            valueRange,
            _spreadsheetId,
            updateRange,
            valueInputOption: 'USER_ENTERED',
          );
          break;
        }
      }
    } catch (e) {
      print('⚠️ Ошибка обновления заголовка смены: $e');
    }
  }

  Future<void> _updateReport(int? shiftId, double total) async {
    if (shiftId == null) return;
    
    try {
      final response = await _sheetsApi!.spreadsheets.values.get(
        _spreadsheetId,
        _sheets['reports']!,
      );
      
      final values = response.values ?? [];
      bool found = false;
      
      for (int i = 0; i < values.length; i++) {
        final row = values[i];
        if (row.isNotEmpty && row[0] != null && row[0].toString().contains('Смена №$shiftId')) {
          final currentReceipts = int.tryParse(row.length > 1 ? row[1]?.toString() ?? '0' : '0') ?? 0;
          final currentRevenue = double.tryParse(row.length > 2 ? row[2]?.toString().replaceAll(',', '.') ?? '0' : '0') ?? 0;
          
          final newReceipts = currentReceipts + 1;
          final newRevenue = currentRevenue + total;
          
          final updateRow = [
            'Смена №$shiftId',
            newReceipts.toString(),
            newRevenue.toStringAsFixed(2),
            newReceipts > 0 ? (newRevenue / newReceipts).toStringAsFixed(2) : '0',
          ];
          
          final updateRange = '${_sheets['reports']}!A${i + 1}:D${i + 1}';
          final valueRange = sheets.ValueRange(
            values: [updateRow],
          );
          await _sheetsApi!.spreadsheets.values.update(
            valueRange,
            _spreadsheetId,
            updateRange,
            valueInputOption: 'USER_ENTERED',
          );
          
          found = true;
          break;
        }
      }
      
      if (!found) {
        await _appendRow(_sheets['reports']!, [
          'Смена №$shiftId',
          '1',
          total.toStringAsFixed(2),
          total.toStringAsFixed(2),
        ]);
      }
    } catch (e) {
      print('⚠️ Ошибка обновления отчёта: $e');
    }
  }

  // ============================================================
  //  УПРАВЛЕНИЕ НАСТРОЙКАМИ
  // ============================================================

  Future<void> setCredentials(String credentialsJson) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final keyPath = '${dir.path}/google_key.json';
      final keyFile = File(keyPath);
      await keyFile.writeAsString(credentialsJson);
      print('✅ Ключ Google Sheets сохранён');
      await init();
    } catch (e) {
      print('❌ Ошибка сохранения ключа: $e');
      throw e;
    }
  }

  Future<void> setSpreadsheetId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('google_spreadsheet_id', id);
      _spreadsheetId = id;
      print('✅ ID таблицы сохранён: $id');
    } catch (e) {
      print('❌ Ошибка сохранения ID таблицы: $e');
    }
  }

  Future<String?> getSpreadsheetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('google_spreadsheet_id');
  }

  Future<bool> testConnection() async {
    if (!_isInitialized || _sheetsApi == null) {
      await init();
    }
    return _isInitialized && _spreadsheetId.isNotEmpty;
  }

  bool get isConnected => _isInitialized && _spreadsheetId.isNotEmpty;
}
