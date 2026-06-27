import 'package:flutter/material.dart';
import '../services/printer_service.dart';

class PrinterSettings extends StatefulWidget {
  const PrinterSettings({super.key});

  @override
  State<PrinterSettings> createState() => _PrinterSettingsState();
}

class _PrinterSettingsState extends State<PrinterSettings> {
  final PrinterService _printer = PrinterService();
  List<String> _ports = [];
  String _selectedPort = '';
  String _selectedSpeed = '19200';
  String _status = 'Не подключен';
  Color _statusColor = Colors.red;
  bool _isLoading = false;
  final List<String> _speedOptions = ['9600', '19200', '38400', '57600', '115200'];

  @override
  void initState() {
    super.initState();
    _loadPorts();
    _updateStatus();
  }

  Future<void> _loadPorts() async {
    setState(() => _isLoading = true);
    try {
      final ports = await _printer.getAvailablePorts();
      if (ports.isNotEmpty) {
        _ports = ports;
        final usbPorts = ports.where((p) => 
          p.contains('usbserial') || p.contains('ttyUSB') || p.contains('COM')).toList();
        _selectedPort = usbPorts.isNotEmpty ? usbPorts.first : ports.first;
      } else {
        _ports = ['/dev/cu.usbserial-110', '/dev/cu.usbserial-10'];
        _selectedPort = _ports.first;
      }
    } catch (e) {
      print('Ошибка загрузки портов: $e');
    }
    setState(() => _isLoading = false);
  }

  void _updateStatus() {
    setState(() {
      _status = _printer.isConnected ? '✅ Подключен' : '❌ Не подключен';
      _statusColor = _printer.isConnected ? Colors.green : Colors.red;
    });
  }

  Future<void> _connectPrinter() async {
    if (_selectedPort.isEmpty) {
      _showSnackbar('⚠ Выберите порт', Colors.orange);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final speed = int.parse(_selectedSpeed);
      final connected = await _printer.connect(portName: _selectedPort, baudRate: speed);
      _updateStatus();
      _showSnackbar(connected ? '✅ Подключен!' : '❌ Ошибка', 
        connected ? Colors.green : Colors.red);
    } catch (e) {
      _showSnackbar('❌ Ошибка: $e', Colors.red);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _disconnectPrinter() async {
    setState(() => _isLoading = true);
    try {
      await _printer.disconnect();
      _updateStatus();
      _showSnackbar('🔌 Отключен', Colors.orange);
    } catch (e) {
      _showSnackbar('❌ Ошибка: $e', Colors.red);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testPrint() async {
    if (!_printer.isConnected) {
      _showSnackbar('⚠ Сначала подключите принтер', Colors.orange);
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final text = '''
=== ТЕСТОВАЯ ПЕЧАТЬ ===
АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ
абвгдеёжзийклмнопрстуфхцчшщъыьэюя
Привет мир!
ИП Букреева А.А.
''';
      final result = await _printer.printText(text);
      _showSnackbar(result ? '✅ Напечатано!' : '❌ Ошибка', 
        result ? Colors.green : Colors.red);
    } catch (e) {
      _showSnackbar('❌ Ошибка: $e', Colors.red);
    }
    setState(() => _isLoading = false);
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🖨 Принтер'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPorts,
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
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  _buildPortSettings(),
                  const SizedBox(height: 20),
                  _buildControlButtons(),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _testPrint,
                    icon: const Icon(Icons.print),
                    label: const Text('🧪 Тестовая печать'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            _printer.isConnected ? Icons.check_circle : Icons.error,
            color: _statusColor,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _status,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Настройки порта', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _ports.contains(_selectedPort) ? _selectedPort : null,
              decoration: const InputDecoration(
                labelText: 'Порт',
                border: OutlineInputBorder(),
              ),
              items: _ports.map((port) {
                return DropdownMenuItem(value: port, child: Text(port));
              }).toList(),
              onChanged: (value) => setState(() => _selectedPort = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedSpeed,
              decoration: const InputDecoration(
                labelText: 'Скорость',
                border: OutlineInputBorder(),
              ),
              items: _speedOptions.map((speed) {
                return DropdownMenuItem(
                  value: speed,
                  child: Text('$speed бод'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedSpeed = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return _printer.isConnected
        ? OutlinedButton.icon(
            onPressed: _disconnectPrinter,
            icon: const Icon(Icons.usb_off),
            label: const Text('Отключить'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          )
        : FilledButton.icon(
            onPressed: _connectPrinter,
            icon: const Icon(Icons.usb),
            label: const Text('Подключить'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          );
  }
}
