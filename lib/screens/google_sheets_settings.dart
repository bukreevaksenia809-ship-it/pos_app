//lib/screens/google_sheets_settings.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/google_sheets_service.dart';
import '../providers/theme_provider.dart';

class GoogleSheetsSettings extends StatefulWidget {
  const GoogleSheetsSettings({super.key});

  @override
  State<GoogleSheetsSettings> createState() => _GoogleSheetsSettingsState();
}

class _GoogleSheetsSettingsState extends State<GoogleSheetsSettings> {
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _spreadsheetIdController = TextEditingController();
  bool _isConnected = false;
  bool _isLoading = false;
  bool _showInstruction = true;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isLoading = true;
    });
    
    _isConnected = GoogleSheetsService().isConnected;
    
    // Загружаем сохранённый ID таблицы
    final savedId = await GoogleSheetsService().getSpreadsheetId();
    if (savedId != null) {
      _spreadsheetIdController.text = savedId;
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Google Sheets'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Статус подключения
                  _buildStatusCard(),
                  const SizedBox(height: 24),

                  // Инструкция (сворачиваемая)
                  _buildInstructionSection(),
                  const SizedBox(height: 24),

                  // Форма настройки
                  _buildSettingsForm(),
                  const SizedBox(height: 24),

                  // Кнопки действий
                  _buildActionButtons(),
                  const SizedBox(height: 16),

                  // Информация о таблице
                  _buildTableInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isConnected ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.check_circle : Icons.warning_amber,
            color: _isConnected ? Colors.green : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected ? '✅ Подключено' : '⚠️ Требуется настройка',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isConnected ? Colors.green : Colors.orange,
                  ),
                ),
                Text(
                  _isConnected 
                    ? 'Google Sheets подключён и готов к работе'
                    : 'Настройте подключение к Google Sheets',
                  style: TextStyle(
                    color: _isConnected ? Colors.green.shade700 : Colors.orange.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        initiallyExpanded: !_isConnected,
        leading: const Icon(Icons.lightbulb, color: Colors.amber),
        title: const Text(
          '📖 Инструкция по настройке',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _isConnected ? '✅ Настроено' : 'Следуйте шагам ниже',
          style: TextStyle(
            color: _isConnected ? Colors.green : Colors.grey,
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _instructionStep(
                  '1️⃣', 'Перейдите в Google Cloud Console',
                  'Откройте https://console.cloud.google.com',
                ),
                const SizedBox(height: 8),
                _instructionStep(
                  '2️⃣', 'Создайте проект',
                  'Нажмите "Создать проект" и дайте ему название',
                ),
                const SizedBox(height: 8),
                _instructionStep(
                  '3️⃣', 'Включите Google Sheets API',
                  'Перейдите в "Библиотека" → найдите "Google Sheets API" → включите',
                ),
                const SizedBox(height: 8),
                _instructionStep(
                  '4️⃣', 'Создайте сервисный аккаунт',
                  'API и сервисы → Учётные данные → Создать сервисный аккаунт',
                ),
                const SizedBox(height: 8),
                _instructionStep(
                  '5️⃣', 'Скачайте JSON ключ',
                  'Создайте ключ → JSON → Скачать',
                ),
                const SizedBox(height: 8),
                _instructionStep(
                  '6️⃣', 'Вставьте ключ в приложение',
                  'Скопируйте содержимое JSON файла в поле ниже',
                ),
                const SizedBox(height: 8),
                _instructionStep(
                  '7️⃣', 'Создайте Google Таблицу',
                  'Создайте таблицу и скопируйте её ID из URL',
                ),
                const SizedBox(height: 8),
                _instructionStep(
                  '8️⃣', 'Дайте доступ сервисному аккаунту',
                  'В таблице → "Доступ" → добавьте email сервисного аккаунта с правами редактора',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '💡 Важно: ID таблицы — это часть URL: docs.google.com/spreadsheets/d/ВАШ_ID/edit',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '✅ Готово! После настройки нажмите "Сохранить"',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚙️ Настройки подключения',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // ID таблицы
            TextField(
              controller: _spreadsheetIdController,
              decoration: const InputDecoration(
                labelText: 'ID Google Таблицы',
                hintText: 'Вставьте ID таблицы',
                prefixIcon: Icon(Icons.table_chart),
                border: OutlineInputBorder(),
                helperText: 'Пример: 1uY4qHHfHHVO1TWu500oXHLXWDtQaEggP0rWCCt2pu9I',
              ),
            ),
            const SizedBox(height: 16),
            
            // JSON ключ
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _keyController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'JSON ключ сервисного аккаунта',
                  hintText: 'Вставьте содержимое JSON файла сюда...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.key),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('💾 Сохранить настройки'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (_isConnected)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _testConnection,
              icon: const Icon(Icons.network_check),
              label: const Text('Проверить'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTableInfo() {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Структура таблицы',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _tableInfoRow('📄 Чеки', '№ чека, Дата, Смена, Товары, Сумма, Оплата, Сдача'),
            _tableInfoRow('📦 Товары', '№ чека, Товар, Цена, Кол-во, Ед., Сумма'),
            _tableInfoRow('📊 Отчеты', 'Смена, Чеков, Выручка, Средний чек'),
            _tableInfoRow('🔄 Смены', 'Автоматически создаются при первой отправке'),
          ],
        ),
      ),
    );
  }

  Widget _tableInfoRow(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final key = _keyController.text.trim();
    final spreadsheetId = _spreadsheetIdController.text.trim();

    if (spreadsheetId.isEmpty) {
      _showSnackbar('⚠️ Введите ID таблицы', Colors.orange);
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Сохраняем ID таблицы
      await GoogleSheetsService().setSpreadsheetId(spreadsheetId);

      // Если есть ключ — сохраняем и подключаемся
      if (key.isNotEmpty) {
        try {
          json.decode(key); // Проверяем валидность JSON
          await GoogleSheetsService().setCredentials(key);
        } catch (e) {
          _showSnackbar('❌ Неверный JSON ключ: $e', Colors.red);
          setState(() => _isLoading = false);
          return;
        }
      }

      await _checkConnection();
      
      if (GoogleSheetsService().isConnected) {
        _showSnackbar('✅ Подключение к Google Sheets установлено!', Colors.green);
        _keyController.clear();
      } else {
        _showSnackbar('⚠️ Настройки сохранены, но подключение не установлено. Проверьте ключ.', Colors.orange);
      }
    } catch (e) {
      _showSnackbar('❌ Ошибка: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isLoading = true);
    
    try {
      final isConnected = await GoogleSheetsService().testConnection();
      if (isConnected) {
        _showSnackbar('✅ Подключение работает!', Colors.green);
      } else {
        _showSnackbar('⚠️ Подключение не установлено. Проверьте настройки.', Colors.orange);
      }
    } catch (e) {
      _showSnackbar('❌ Ошибка: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help, color: Colors.blue),
            SizedBox(width: 8),
            Text('Помощь'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📌 Зачем это нужно?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Интеграция с Google Sheets позволяет автоматически отправлять чеки и отчёты в облачную таблицу.',
            ),
            const SizedBox(height: 12),
            const Text(
              '🔑 Что нужно сделать:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('1. Создать сервисный аккаунт в Google Cloud\n'
                      '2. Включить Google Sheets API\n'
                      '3. Скачать JSON ключ\n'
                      '4. Вставить ключ в приложение'),
            const SizedBox(height: 12),
            const Text(
              '💡 Совет:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Для теста можно использовать готовую таблицу. '
              'Создайте новую таблицу и дайте доступ сервисному аккаунту.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
