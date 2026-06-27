// lib/test_on_start.dart - ТЕСТ С БАЙТАМИ ИЗ PYTHON
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';

Future<void> testPrinterOnStart() async {
  print('🧪 ТЕСТ С БАЙТАМИ ИЗ PYTHON');
  print('=' * 50);
  
  try {
    final ports = SerialPort.availablePorts;
    print('📋 Порты: $ports');
    
    String portName = '/dev/cu.usbserial-110';
    if (!ports.contains(portName)) {
      for (var p in ['/dev/cu.usbserial-110', '/dev/tty.usbserial-110', '/dev/cu.usbserial-10']) {
        if (ports.contains(p)) {
          portName = p;
          break;
        }
      }
    }
    
    print('🔌 Порт: $portName');
    
    final port = SerialPort(portName);
    port.config
      ..baudRate = 19200
      ..bits = 8
      ..stopBits = 1
      ..parity = SerialPortParity.none;
    
    if (!port.openReadWrite()) {
      print('❌ Ошибка открытия порта');
      return;
    }
    
    print('✅ Порт открыт');
    
    void sendBytes(List<int> data) {
      port.write(Uint8List.fromList(data));
      print('📤 Отправлено: ${data.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
    }
    
    // ============================================================
    // 1. СБРОС И КОДИРОВКА
    // ============================================================
    print('\n📝 1. Инициализация');
    sendBytes([0x1B, 0x40]);  // Reset
    await Future.delayed(Duration(milliseconds: 100));
    sendBytes([0x1B, 0x52, 0x07]);  // CP866 код 7
    await Future.delayed(Duration(milliseconds: 100));
    
    // ============================================================
    // 2. ЛАТИНИЦА (должна работать всегда)
    // ============================================================
    print('\n📝 2. Латиница');
    sendBytes([0x0A]);  // newline
    sendBytes('ABCDEFGHIJKLMNOPQRSTUVWXYZ'.codeUnits);
    sendBytes([0x0A]);
    sendBytes('abcdefghijklmnopqrstuvwxyz'.codeUnits);
    sendBytes([0x0A]);
    sendBytes('1234567890'.codeUnits);
    sendBytes([0x0A, 0x0A]);
    await Future.delayed(Duration(milliseconds: 300));
    
    // ============================================================
    // 3. РУССКИЕ БУКВЫ - ТЕ ЖЕ БАЙТЫ ЧТО В PYTHON
    // ============================================================
    print('\n📝 3. Русские буквы (байты из Python)');
    sendBytes([0x0A]);
    
    // АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ в CP866
    // ЭТИ БАЙТЫ ТОЧНО РАБОТАЮТ В PYTHON!
    sendBytes([
      0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0xF0, 0x86, 0x87, 
      0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x8D, 0x8E, 0x8F,
      0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,
      0x98, 0x99, 0x9A, 0x9B, 0x9C, 0x9D, 0x9E, 0x9F
    ]);
    sendBytes([0x0A]);
    await Future.delayed(Duration(milliseconds: 100));
    
    // абвгдеёжзийклмнопрстуфхцчшщъыьэюя в CP866
    sendBytes([
      0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xF1, 0xA6, 0xA7,
      0xA8, 0xA9, 0xAA, 0xAB, 0xAC, 0xAD, 0xAE, 0xAF,
      0xB0, 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7,
      0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF
    ]);
    sendBytes([0x0A, 0x0A]);
    await Future.delayed(Duration(milliseconds: 300));
    
    // ============================================================
    // 4. "ПРИВЕТ МИР" - ТЕ ЖЕ БАЙТЫ
    // ============================================================
    print('\n📝 4. "Привет мир"');
    sendBytes([0x0A]);
    // "Привет мир" в CP866
    sendBytes([
      0x9F, 0xD0, 0x98, 0x92, 0x85, 0xD2, 0x20, 0x9C, 0x98, 0xD0
    ]);
    sendBytes([0x0A, 0x0A, 0x0A]);
    await Future.delayed(Duration(milliseconds: 300));
    
    // ============================================================
    // 5. "ИП БУКРЕЕВА" - ТЕ ЖЕ БАЙТЫ
    // ============================================================
    print('\n📝 5. "ИП Букреева"');
    sendBytes([0x0A]);
    // "ИП Букреева" в CP866
    sendBytes([
      0x88, 0x9F, 0x20, 0x81, 0xA3, 0x8A, 0xD0, 0x85, 0x85, 0x92, 0x80, 0xA0
    ]);
    sendBytes([0x0A, 0x0A, 0x0A]);
    await Future.delayed(Duration(milliseconds: 300));
    
    // ============================================================
    // ОБРЕЗКА
    // ============================================================
    sendBytes([0x1D, 0x56, 0x00]);
    await Future.delayed(Duration(milliseconds: 500));
    
    port.close();
    
    print('\n✅ Все тесты отправлены!');
    print('=' * 50);
    print('📸 Сделай фото чека!');
    print('Скажи что напечаталось:');
    print('1. Латиница - нормально?');
    print('2. Русские буквы - что видно?');
    
  } catch (e) {
    print('❌ Ошибка: $e');
  }
}
