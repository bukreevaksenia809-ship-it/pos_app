// lib/test_simple_page.dart - МИНИМАЛЬНЫЙ ТЕСТ ВНУТРИ FLUTTER
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class TestSimplePage extends StatefulWidget {
  const TestSimplePage({super.key});

  @override
  State<TestSimplePage> createState() => _TestSimplePageState();
}

class _TestSimplePageState extends State<TestSimplePage> {
  String _status = 'Нажми кнопку';
  Color _statusColor = Colors.grey;
  bool _isPrinting = false;

  Future<void> _printTest() async {
    setState(() {
      _status = 'Печать...';
      _statusColor = Colors.orange;
      _isPrinting = true;
    });

    try {
      final ports = SerialPort.availablePorts;
      print('📋 Порты: $ports');
      
      String portName = '/dev/cu.usbserial-110';
      if (!ports.contains(portName)) {
        setState(() {
          _status = '❌ Порт не найден';
          _statusColor = Colors.red;
        });
        return;
      }
      
      final port = SerialPort(portName);
      port.config
        ..baudRate = 19200
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none;
      
      if (!port.openReadWrite()) {
        setState(() {
          _status = '❌ Ошибка открытия';
          _statusColor = Colors.red;
        });
        return;
      }
      
      print('✅ Порт открыт');
      
      // Отправляем
      port.write(Uint8List.fromList([0x1B, 0x40]));
      await Future.delayed(Duration(milliseconds: 100));
      
      port.write(Uint8List.fromList([0x1B, 0x52, 0x07]));
      await Future.delayed(Duration(milliseconds: 100));
      
      // Только латиница
      port.write(Uint8List.fromList('HELLO WORLD\n'.codeUnits));
      await Future.delayed(Duration(milliseconds: 100));
      
      // Русские буквы
      final russian = [
        0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0xF0, 0x86, 0x87,
        0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x8D, 0x8E, 0x8F,
        0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
        0x98, 0x99, 0x9A, 0x9B, 0x9C, 0x9D, 0x9E, 0x9F,
        0x0A
      ];
      port.write(Uint8List.fromList(russian));
      await Future.delayed(Duration(milliseconds: 100));
      
      port.write(Uint8List.fromList([0x1D, 0x56, 0x00]));
      await Future.delayed(Duration(milliseconds: 500));
      
      port.close();
      
      setState(() {
        _status = '✅ Напечатано!';
        _statusColor = Colors.green;
      });
      
    } catch (e) {
      setState(() {
        _status = '❌ Ошибка: $e';
        _statusColor = Colors.red;
      });
      print('❌ $e');
    }
    
    setState(() {
      _isPrinting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Тест принтера'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.print, size: 80, color: Colors.blue),
              const SizedBox(height: 30),
              Text(
                _status,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _statusColor,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                height: 60,
                child: FilledButton.icon(
                  onPressed: _isPrinting ? null : _printTest,
                  icon: _isPrinting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.print, size: 28),
                  label: Text(
                    _isPrinting ? 'Печать...' : 'Печать',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
